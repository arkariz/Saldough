import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show NavigatorObserver;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:saldough/core/config/firebase_config.dart';

/// Inisialisasi Firebase (ADR-023): Analytics, Crashlytics, App Check
/// (wajib untuk Firebase AI Logic, ADR-027 §3.5 butir 5), dan Google
/// Sign-In. Dipanggil sekali dari `main.dart`, sebelum `runApp`.
///
/// ⚠ **Kegagalan di sini tidak boleh menghentikan aplikasi** (NFR-REL-001 —
/// pencatatan inti wajib berfungsi penuh tanpa koneksi, termasuk saat
/// perangkat offline sejak pertama dibuka). Karena itu seluruh isi fungsi
/// ini dibungkus try/catch di pemanggilnya sendiri
/// (`main.dart`/`AppBootstrap.run`), bukan di sini — supaya jelas di titik
/// mana kegagalan diserap.
abstract final class AppBootstrap {
  AppBootstrap._();

  /// `FirebaseAnalytics` akar, dipakai [analyticsObserver] dan tempat
  /// menambah event kustom nanti (belum ada — lihat ADR-023 §3).
  static FirebaseAnalytics get analytics => FirebaseAnalytics.instance;

  /// Observer `GoRouter` untuk `screen_view` otomatis. Didaftarkan di
  /// `AppRouteRegistry.build(observers: [...])`.
  static NavigatorObserver get analyticsObserver => FirebaseAnalyticsObserver(analytics: analytics);

  /// Menjalankan `Firebase.initializeApp()`, menyalakan pelaporan crash
  /// (nonaktif di mode debug supaya crash saat pengembangan tidak
  /// mengotori dasbor), dan menyiapkan Google Sign-In supaya
  /// `GoogleSignIn.instance` siap dipakai `FirebaseAuthRepositoryImpl`.
  static Future<void> run() async {
    await Firebase.initializeApp();

    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      unawaited(FirebaseCrashlytics.instance.recordError(error, stack, fatal: true));
      return true;
    };

    // App Check: Play Integrity / App Attest di rilis; penyedia debug di mode
    // debug (token debug-nya didaftarkan di Firebase Console). Sesudah
    // Crashlytics, supaya kegagalannya terlaporkan dan tidak mematikan
    // pelaporan crash; tanpa App Check hanya Firebase AI yang terdampak.
    try {
      await FirebaseAppCheck.instance.activate(
        providerAndroid: kDebugMode ? const AndroidDebugProvider() : const AndroidPlayIntegrityProvider(),
        providerApple: kDebugMode ? const AppleDebugProvider() : const AppleAppAttestWithDeviceCheckFallbackProvider(),
      );
    } on Object catch (error) {
      recordNonFatal(error, reason: 'AppCheck');
    }

    await GoogleSignIn.instance.initialize(serverClientId: FirebaseConfig.googleServerClientId);
  }

  /// Melaporkan galat yang sudah ditangani (non-fatal) ke Crashlytics, mis.
  /// migrasi data yang gagal dan akan dicoba lagi. Diam kalau Firebase belum
  /// terinisialisasi (perangkat offline sejak pertama dibuka).
  static void recordNonFatal(Object error, {required String reason}) {
    if (Firebase.apps.isEmpty) return;
    unawaited(FirebaseCrashlytics.instance.recordError(error, StackTrace.current, reason: reason));
  }
}
