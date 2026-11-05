import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:state_management/state_management.dart';

/// Mendaftarkan penangan [ShowSnackBarEffect].
///
/// Semua tingkat memakai snackbar design system v2 (`dsSnackBar`): permukaan
/// terbalik, titik bernada di kiri sebagai penanda pesan dari sistem.
///
/// ⚠ `actionLabel`/`actionIntentId` belum terhubung ke bloc — belum ada
/// fitur yang butuh aksi pada snackbar, dan paket `state_management` tidak
/// menentukan mekanisme baku untuk mengirim intent balik ke bloc yang
/// mengeluarkan efeknya. Kalau kebutuhannya muncul nanti, putuskan dulu
/// mekanismenya (misalnya lewat `CallbackEffect` sebagai pengganti) sebelum
/// menyambungkan tombol aksi di sini.
void registerSnackBarEffectHandler(EffectRegistry registry) {
  registry.register<ShowSnackBarEffect>((context, effect) {
    ScaffoldMessenger.of(context).showSnackBar(feedbackSnackBar(context.ds, effect));
  });
}

/// Snackbar v2 untuk [effect]: titik bernada di kiri (centang untuk sukses,
/// tanda seru untuk peringatan, silang untuk galat, "i" untuk info). Dipakai
/// juga di luar penangan efek, mis. hasil "Urungkan" yang diketuk sesudah rute
/// pemilik blocnya tertutup (ADR-030 §3.3): token [ds] diambil saat rute masih hidup.
SnackBar feedbackSnackBar(DsTokens ds, ShowSnackBarEffect effect) => dsSnackBar(
  ds,
  content: Text(effect.message),
  tone: switch (effect.severity) {
    FeedbackSeverity.success => DsSnackTone.success,
    FeedbackSeverity.warning => DsSnackTone.warning,
    FeedbackSeverity.error => DsSnackTone.error,
    FeedbackSeverity.info => DsSnackTone.info,
  },
  duration: effect.autoDismissDuration,
);
