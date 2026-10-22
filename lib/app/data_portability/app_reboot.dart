import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/app_icon.dart';
import 'package:saldough/core/presentation/widgets/app_spin.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/data_portability/domain/restore_models.dart';
import 'package:saldough/features/data_portability/presentation/widgets/restore_steps.dart';

/// Kemajuan pemulihan yang tampil di layar boot ulang: langkah ke-[step] dari
/// empat langkah di Akun (`Pulihkan.dc.html`); dari onboarding langkah
/// pertama dilewati.
final class RestoreProgress {
  /// Membuat [RestoreProgress].
  const RestoreProgress({required this.step, this.onboarding = false});

  /// Langkah yang sedang berjalan, 1..4 (penomoran Akun).
  final int step;

  /// Pemulihan dari onboarding (tanpa cadangan pengaman).
  final bool onboarding;
}

/// Menjalankan ulang bootstrap aplikasi di dalam proses (ADR-040 §3.7).
///
/// Pemulihan cadangan mengganti data di penyimpanan, sedangkan kontainer DI,
/// blok, dan state global (`ActiveCurrency`, `ActiveCategories`, ...) sudah
/// memuat data lama. Membangun ulang pohon widget saja tidak membuangnya;
/// boot ulang memakai jalur yang sama dengan peluncuran dingin, yang sudah
/// teruji.
abstract final class AppReboot {
  static Future<void> Function()? _bootstrap;

  /// Keterangan pemulihan yang baru selesai, diisi bootstrap. Dibaca shell
  /// untuk membuka halaman "Data dipulihkan" sekali, lalu dikosongkan.
  static final ValueNotifier<RestoreReport?> report = ValueNotifier(null);

  /// Kemajuan pemulihan untuk layar boot ulang; `null` = boot biasa.
  static final ValueNotifier<RestoreProgress?> progress = ValueNotifier(null);

  /// Mendaftarkan [bootstrap] (`bootstrapApp`), dipanggil sekali oleh `main()`.
  // ignore: use_setters_to_change_properties, dipasang sekali sebagai tindakan, bukan properti.
  static void install(Future<void> Function() bootstrap) => _bootstrap = bootstrap;

  /// Mengganti layar dengan penanda proses lalu menjalankan ulang bootstrap.
  /// Penerapan data sebenarnya dilakukan jalur pemulihan jurnal di dalam
  /// bootstrap, jadi jalur yang sama menangani pemulihan biasa dan pemulihan
  /// dari gangguan. [restoring] menampilkan daftar langkah pemulihan; `null`
  /// hanya pemutar.
  static Future<void> reboot({RestoreProgress? restoring}) async {
    final bootstrap = _bootstrap;
    if (bootstrap == null) throw StateError('AppReboot.install belum dipanggil');
    progress.value = restoring;
    runApp(const _RebootSplash());
    // Pohon lama harus benar-benar lepas sebelum kontainer DI dikosongkan.
    await WidgetsBinding.instance.endOfFrame;
    await bootstrap();
  }
}

class _RebootSplash extends StatelessWidget {
  const _RebootSplash();

  @override
  Widget build(BuildContext context) {
    final colors = PixelTheme.light.extension<AppColors>()!;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: PixelTheme.light,
      darkTheme: PixelTheme.dark,
      home: Scaffold(
        body: SafeArea(
          child: ValueListenableBuilder<RestoreProgress?>(
            valueListenable: AppReboot.progress,
            builder: (context, progress, _) {
              if (progress == null) {
                return Center(
                  child: AppSpin(child: AppIcon(IconKey.progressActivity, color: colors.brand)),
                );
              }
              final labels = restoreStepLabels(onboarding: progress.onboarding);
              final current = progress.onboarding ? progress.step - 1 : progress.step;
              final textTheme = Theme.of(context).textTheme;
              return ListView(
                padding: const EdgeInsets.all(AppSpacing.space4),
                children: [
                  const SizedBox(height: AppSpacing.space8),
                  Text(t.dataPortability.restoreRunTitle, style: textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.space4),
                  RestoreSteps(labels: labels, current: current),
                  const SizedBox(height: AppSpacing.space3),
                  Text(
                    t.dataPortability.restoreNoCancel,
                    style: textTheme.bodyMedium?.copyWith(color: colors.ink2),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
