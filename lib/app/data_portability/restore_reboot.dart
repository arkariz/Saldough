import 'package:saldough/app/data_portability/app_reboot.dart';

/// Memulai ulang aplikasi sesudah penggantian disiapkan (`RestoreReboot`).
/// Layar boot ulang menampilkan daftar langkah mulai dari langkah 2; langkah 1
/// (menyimpan cadangan pengaman) sudah selesai di halaman pulihkan.
Future<void> restoreReboot({required bool onboarding}) =>
    AppReboot.reboot(restoring: RestoreProgress(step: 2, onboarding: onboarding));
