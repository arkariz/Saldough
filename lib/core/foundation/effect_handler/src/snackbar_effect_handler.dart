import 'package:flutter/material.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:state_management/state_management.dart';

/// Mendaftarkan penangan [ShowSnackBarEffect], memetakan [FeedbackSeverity]
/// ke slot warna semantik Saldough.
///
/// ⚠ `actionLabel`/`actionIntentId` belum terhubung ke bloc — belum ada
/// fitur yang butuh aksi pada snackbar, dan paket `state_management` tidak
/// menentukan mekanisme baku untuk mengirim intent balik ke bloc yang
/// mengeluarkan efeknya. Kalau kebutuhannya muncul nanti, putuskan dulu
/// mekanismenya (misalnya lewat `CallbackEffect` sebagai pengganti) sebelum
/// menyambungkan tombol aksi di sini.
void registerSnackBarEffectHandler(EffectRegistry registry) {
  registry.register<ShowSnackBarEffect>((context, effect) {
    final colors = context.appColors;
    final background = switch (effect.severity) {
      FeedbackSeverity.success => colors.income,
      FeedbackSeverity.warning => colors.overBudget,
      FeedbackSeverity.error => colors.expense,
      FeedbackSeverity.info => colors.rollUp,
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(effect.message),
        backgroundColor: background,
        duration: effect.autoDismissDuration,
      ),
    );
  });
}
