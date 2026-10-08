import 'package:flutter/material.dart';
import 'package:saldough/core/presentation/widgets/app_icon.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:state_management/state_management.dart';

/// Mendaftarkan penangan [ShowSnackBarEffect].
///
/// Semua tingkat memakai snackbar design system: latar `inverse-surface`,
/// teks `on-inverse` (ADR-034). Tingkat dibedakan lewat ikon, bukan warna
/// latar: centang untuk sukses, info untuk peringatan dan galat.
///
/// ⚠ `actionLabel`/`actionIntentId` belum terhubung ke bloc — belum ada
/// fitur yang butuh aksi pada snackbar, dan paket `state_management` tidak
/// menentukan mekanisme baku untuk mengirim intent balik ke bloc yang
/// mengeluarkan efeknya. Kalau kebutuhannya muncul nanti, putuskan dulu
/// mekanismenya (misalnya lewat `CallbackEffect` sebagai pengganti) sebelum
/// menyambungkan tombol aksi di sini.
void registerSnackBarEffectHandler(EffectRegistry registry) {
  registry.register<ShowSnackBarEffect>((context, effect) {
    ScaffoldMessenger.of(context).showSnackBar(feedbackSnackBar(context.appColors, effect));
  });
}

/// Snackbar untuk [effect] dengan palet [colors]. Dipakai juga di luar
/// penangan efek, mis. hasil "Urungkan" yang diketuk sesudah rute
/// pemilik blocnya tertutup (ADR-030 §3.3) -- warnanya diambil saat rute
/// itu masih hidup.
SnackBar feedbackSnackBar(AppColors colors, ShowSnackBarEffect effect) {
  final icon = switch (effect.severity) {
    FeedbackSeverity.success => IconKey.check,
    FeedbackSeverity.warning || FeedbackSeverity.error => IconKey.info,
    FeedbackSeverity.info => null,
  };
  return SnackBar(
    content: Row(
      children: [
        if (icon != null) ...[
          AppIcon(icon, size: 20, color: colors.onInverse),
          const SizedBox(width: AppSpacing.space2),
        ],
        Expanded(
          child: Text(effect.message, style: TextStyle(color: colors.onInverse)),
        ),
      ],
    ),
    backgroundColor: colors.inverseSurface,
    duration: effect.autoDismissDuration,
  );
}
