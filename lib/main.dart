import 'dart:developer' as developer;

import 'package:dependencies/dependencies.dart';
import 'package:di/di.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:saldough/app/app.dart';
import 'package:saldough/app/di/di.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/foundation/analytics/app_bootstrap_firebase.dart';
import 'package:saldough/core/foundation/effect_handler/app_effect_registry.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/language/language.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:state_management/state_management.dart';

/// Kontainer DI akar. Lihat ARCHITECTURE_OVERVIEW.md bagian "Bootstrap".
final GetIt rootGetIt = GetIt.instance;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Urutan ini dipertahankan dari flutter-architecture-studi-bank (minus
  // jembatan legacy GetX mereka): pasang Bloc.observer -> Firebase ->
  // di.run() -> daftarkan effect handler -> render router -> di.warmUp()
  // setelah frame pertama. Lihat "Dasar keputusan" di
  // ARCHITECTURE_OVERVIEW.md.
  Bloc.observer = AppBlocObserver();

  // ADR-023. Dibungkus try/catch di sini, BUKAN di dalam AppBootstrap.run()
  // sendiri: kegagalan apa pun (mis. perangkat offline sejak pertama
  // dibuka, google-services.json belum ditaruh) tidak boleh menghalangi
  // pencatatan inti berjalan (NFR-REL-001) -- aplikasi lanjut tanpa
  // Analytics/Crashlytics/Google Sign-In daripada macet di layar putih.
  try {
    await AppBootstrap.run();
  } on Object catch (e, st) {
    developer.log('Firebase gagal diinisialisasi, lanjut tanpa itu', error: e, stackTrace: st, name: 'AppBootstrap');
  }

  await LocaleSettings.useDeviceLocale();
  await di.run(rootGetIt);

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

  registerEffectHandlers();

  final router = rootGetIt<GoRouter>();

  runApp(TranslationProvider(
    child: SaldoughApp(getIt: rootGetIt, router: router),
  ));

  di.warmUp(rootGetIt);
}
