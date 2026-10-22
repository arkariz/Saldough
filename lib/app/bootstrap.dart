import 'dart:async';
import 'dart:developer' as developer;

import 'package:dependencies/dependencies.dart';
import 'package:di/di.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:saldough/app/app.dart';
import 'package:saldough/app/data_portability/app_reboot.dart';
import 'package:saldough/app/data_portability/restore_recovery.dart';
import 'package:saldough/app/di/di.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/foundation/analytics/app_bootstrap_firebase.dart';
import 'package:saldough/core/foundation/effect_handler/app_effect_registry.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/language/language.dart';
import 'package:saldough/features/data_portability/data/platform_file_transfer.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/transaction/source_icons.dart';

/// Kontainer DI akar. Lihat ARCHITECTURE_OVERVIEW.md bagian "Bootstrap".
final GetIt rootGetIt = GetIt.instance;

int _generation = 0;

/// Memasang penyimpanan, kontainer DI, dan state global, lalu `runApp`
/// (ADR-040 §3.7: dipecah dari `main()` supaya bisa dijalankan ulang di dalam
/// proses sesudah pemulihan cadangan). Pemanggilan pertama berasal dari
/// `main()`; yang berikutnya dari [AppReboot.reboot].
///
/// Urutannya sama dengan bootstrap sebelumnya. Perbedaannya hanya pada boot
/// ulang: kontainer dikosongkan dulu, state global dimuat ulang, dan pohon
/// widget dibuat baru (kunci berbeda) supaya tidak ada state lama yang
/// terbawa.
Future<void> bootstrapApp() async {
  final isReboot = _generation > 0;
  if (isReboot) {
    await rootGetIt.reset();
    _resetGlobalState();
  }
  _generation++;

  await di.run(rootGetIt);

  // ADR-040 §3.8: sisa berkas bagi di cache dihapus; isinya data keuangan.
  unawaited(PlatformFileTransfer.sweepTemp());

  // ADR-040 §3.4: bila pemulihan data selesai diterapkan (atau terputus di
  // tengah penerapan), tuntaskan sebelum ada yang membaca data.
  await finishRestoreIfNeeded(rootGetIt);

  // ADR-028: bahasa pilihan pengguna (kalau ada) menggantikan bahasa
  // perangkat, sebelum migrasi kategori menanam nama bawaan.
  final savedLanguage = (await rootGetIt<LanguagePreferenceRepository>().load()).getOrElse((_) => null);
  if (savedLanguage != null) await LocaleSettings.setLocale(savedLanguage);
  ActiveLanguage.notifier.value = LocaleSettings.currentLocale;

  // ADR-025 §3.5: mata uang harus sudah terpasang sebelum layar pertama
  // memformat nominal. Gagal dibaca berarti bawaan (IDR).
  ActiveCurrency.notifier.value = (await rootGetIt<CurrencyPreferenceRepository>().load()).getOrElse(
    (_) => AppCurrency.idr,
  );
  // Sembunyikan nominal (ADR-034): dibaca sebelum layar pertama, setiap
  // perubahan disimpan. Gagal dibaca = tampil. Pendengar dipasang sekali
  // (bukan tiap boot ulang) dan mencari repositorinya saat dipakai, karena
  // kontainer DI dibuat ulang saat boot ulang.
  AmountVisibility.notifier.value = (await rootGetIt<AmountVisibilityRepository>().load()).getOrElse((_) => false);
  if (!isReboot) {
    AmountVisibility.notifier.addListener(
      () => unawaited(rootGetIt<AmountVisibilityRepository>().save(hidden: AmountVisibility.hidden)),
    );
  }

  // ADR-038: jadwal bulan keuangan berriwayat; gagal dibaca = tanggal 1.
  ActiveFinancialMonth.notifier.value = (await rootGetIt<FinancialMonthPreferenceRepository>().load()).getOrElse(
    (_) => FinancialMonthSchedule.initial,
  );

  // ADR-026 §3.4: kategori bawaan + migrasi label lama, sebelum layar pertama
  // membaca judul transaksi. Gagal tidak menghalangi aplikasi terbuka
  // (NFR-REL-001); dicoba lagi pada pembukaan berikutnya.
  final categoryRepository = rootGetIt<CategoryRepository>();
  final migrated = await MigrateLegacyCategories(
    categoryRepository: categoryRepository,
    legacyLabels: rootGetIt<LegacyCategoryLabels>(),
  )(builtInName: (key) => t.category.builtIn[key] ?? key);
  if (migrated case Left(value: final failure)) {
    developer.log('Migrasi kategori gagal, dicoba lagi nanti', error: failure, name: 'MigrateLegacyCategories');
    AppBootstrap.recordNonFatal(failure, reason: 'MigrateLegacyCategories');
  }
  // Mengisi `ActiveCategories` (lewat repository) untuk judul transaksi.
  await categoryRepository.listCategories();

  // Pengendali efek tidak boleh didaftarkan dua kali.
  if (!isReboot) registerEffectHandlers();

  final router = rootGetIt<GoRouter>();

  runApp(
    KeyedSubtree(
      key: ValueKey(_generation),
      child: TranslationProvider(
        child: SaldoughApp(getIt: rootGetIt, router: router),
      ),
    ),
  );

  di.warmUp(rootGetIt);
}

/// Mengosongkan state global yang diisi bootstrap dari penyimpanan. Bahasa
/// dan Sembunyikan nominal milik perangkat, tidak berubah oleh pemulihan,
/// tetapi tetap dibaca ulang oleh [bootstrapApp]. Daftar ini dijaga
/// `app_reboot_state_test.dart`.
void _resetGlobalState() {
  SourceIcons.reset();
  HistoryPeriod.reset();
  ActiveCategories.notifier.value = const [];
}
