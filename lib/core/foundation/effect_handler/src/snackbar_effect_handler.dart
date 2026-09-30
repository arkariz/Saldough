import 'package:flutter/material.dart';
import 'package:saldough/core/presentation/widgets/app_icon.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:state_management/state_management.dart';

/// Mendaftarkan penangan [ShowSnackBarEffect], memetakan [FeedbackSeverity]
/// ke slot warna semantik Saldough.
///
/// Sukses berlatar netral dengan ikon centang, BUKAN hijau: hijau berarti
/// "uang masuk" (ADR-016, UX-17), sedangkan "Pengeluaran tercatat." juga
/// sebuah keberhasilan.
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
SnackBar feedbackSnackBar(AppColorsExtension colors, ShowSnackBarEffect effect) {
  final background = switch (effect.severity) {
    FeedbackSeverity.warning => colors.overBudget,
    FeedbackSeverity.error => colors.expense,
    // Netral, padanan `inverseSurface` Material: gelap di mode terang,
    // terang di mode gelap. Slot `rollUp` yang dulu dipakai dihapus T-3.5.
    FeedbackSeverity.success || FeedbackSeverity.info => colors.textPrimary,
  };
  final isSuccess = effect.severity == FeedbackSeverity.success;
  return SnackBar(
    content: Row(
      children: [
        if (isSuccess) ...[
          AppIcon(IconKey.check, size: 20, color: colors.background),
          const SizedBox(width: AppSpacing.sm),
        ],
        Expanded(child: Text(effect.message)),
      ],
    ),
    backgroundColor: background,
    duration: effect.autoDismissDuration,
  );
}
