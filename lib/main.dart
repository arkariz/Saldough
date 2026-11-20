import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/widgets.dart';
import 'package:saldough/app/bootstrap.dart';
// Perpustakaan titik masuk mesin tanpa layar (ADR-044 §3.5) harus terjangkau dari
// main agar ikut dalam kernel/AOT; native menjalankannya lewat DartEntrypoint.
// ignore: unused_import
import 'package:saldough/app/capture_worker/capture_worker_main.dart';
import 'package:saldough/app/data_portability/app_reboot.dart';
import 'package:saldough/app/startup/boot_failure_app.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/foundation/analytics/app_bootstrap_firebase.dart';
import 'package:saldough/core/foundation/boot/boot_trace.dart';
import 'package:saldough/core/foundation/storage/android_path_fallback.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/app_icon.dart';
import 'package:state_management/state_management.dart';

/// Batas startup sebelum layar darurat tampil (langkah yang tertahan disebut).
/// Cukup longgar untuk perangkat lambat dan pembukaan pertama.
const _bootWatchdog = Duration(seconds: 20);

Future<void> main() async {
  BootTrace.mark('main');
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsBinding.instance.addObserver(ActiveDay.observer);
  // path_provider_android 2.3.x (JNI) gagal di sebagian perangkat pada langkah
  // storage; pasang jalur cadangan yang diverifikasi sebelum storage dibuka.
  FallbackPathProvider.installOnAndroid(
    onFallback: (error, kind) => AppBootstrap.recordNonFatal(error, reason: 'PathFallback:$kind'),
  );
  // Penjaga startup: bila `runApp` belum terpanggil dalam [_bootWatchdog],
  // tampilkan layar darurat yang menyebut langkah yang tertahan. Bila startup
  // akhirnya selesai, `runApp` berikutnya menggantikannya.
  Timer(_bootWatchdog, () {
    if (BootTrace.shown) return;
    final step = BootTrace.step;
    developer.log('Startup tertahan di $step', name: 'BootWatchdog');
    AppBootstrap.recordNonFatal(StateError('startup tertahan di $step'), reason: 'BootWatchdog');
    runApp(BootFailureApp(step: step, stuck: true, onRetry: () => unawaited(_startApp())));
  });

  BootTrace.mark('pixelIcons');
  await PixelIconAssets.load();

  // Urutan ini dipertahankan dari flutter-architecture-studi-bank (minus
  // jembatan legacy GetX mereka): pasang Bloc.observer -> Firebase ->
  // di.run() -> daftarkan effect handler -> render router -> di.warmUp()
  // setelah frame pertama. Lihat "Dasar keputusan" di
  // ARCHITECTURE_OVERVIEW.md. Dari `di.run()` sampai `warmUp()` ada di
  // `bootstrapApp()` supaya bisa dijalankan ulang (ADR-040 §3.7).
  Bloc.observer = AppBlocObserver();

  // ADR-023. Dibungkus try/catch di sini, BUKAN di dalam AppBootstrap.run()
  // sendiri: kegagalan apa pun (mis. perangkat offline sejak pertama
  // dibuka, google-services.json belum ditaruh) tidak boleh menghalangi
  // pencatatan inti berjalan (NFR-REL-001) -- aplikasi lanjut tanpa
  // Analytics/Crashlytics/Google Sign-In daripada macet di layar putih.
  try {
    BootTrace.mark('firebase');
    await AppBootstrap.run();
  } on Object catch (e, st) {
    developer.log('Firebase gagal diinisialisasi, lanjut tanpa itu', error: e, stackTrace: st, name: 'AppBootstrap');
  }

  BootTrace.mark('locale');
  await LocaleSettings.useDeviceLocale();

  AppReboot.install(bootstrapApp);
  await _startApp();
}

/// Menjalankan [bootstrapApp]; galat apa pun sebelum layar pertama menjadi
/// layar darurat (bukan splash yang tertahan selamanya tanpa pesan).
Future<void> _startApp() async {
  try {
    await bootstrapApp();
  } on Object catch (e, st) {
    final step = BootTrace.step;
    developer.log('Startup gagal di $step', error: e, stackTrace: st, name: 'BootWatchdog');
    AppBootstrap.recordNonFatal(e, reason: 'BootFailure:$step');
    runApp(BootFailureApp(step: step, stuck: false, error: e, onRetry: () => unawaited(_startApp())));
  }
}
