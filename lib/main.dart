import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/widgets.dart';
import 'package:saldough/app/bootstrap.dart';
import 'package:saldough/app/data_portability/app_reboot.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/foundation/analytics/app_bootstrap_firebase.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/app_icon.dart';
import 'package:state_management/state_management.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsBinding.instance.addObserver(ActiveDay.observer);
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
    await AppBootstrap.run();
  } on Object catch (e, st) {
    developer.log('Firebase gagal diinisialisasi, lanjut tanpa itu', error: e, stackTrace: st, name: 'AppBootstrap');
  }

  await LocaleSettings.useDeviceLocale();

  AppReboot.install(bootstrapApp);
  await bootstrapApp();
}
