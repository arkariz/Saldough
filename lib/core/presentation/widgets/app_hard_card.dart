import 'package:flutter/material.dart';
import 'package:saldough/core/theme/theme.dart';

/// Level elevasi bayangan keras ADR-015 (§"Elevasi dan bayangan").
enum AppHardElevation {
  /// Level 0 — datar, tanpa bayangan. Bidang isian, baris tabel.
  flat,

  /// Level 1 — kartu. Dompet, anggaran, transaksi.
  card,

  /// Level 2 — interaktif. Tombol terisi, FAB CATAT. Ditekan menekan
  /// bayangan ke 0 dan menggeser isi sejauh offset bayangannya — lihat
  /// [AppHardCard.pressed].
  interactive,

  /// Level 3 — lembar bawah. Bayangan mengarah ke atas.
  bottomSheet,
}

/// Panel bergaris tepi 2px dengan bayangan keras offset — dasar visual
/// ADR-015, padanan `AppCard` (ADR-0006) untuk layar Saldough 2.0.
///
/// Dipakai HANYA di dalam subtree `PixelTheme` — warna dan radiusnya
/// diambil dari `context.appColors`/token `pixelSm`, yang cuma bernilai
/// ADR-015 kalau `PixelTheme` terpasang di atasnya. Di luar `PixelTheme`
/// (mis. layar lama) tampilannya jatuh ke palet ADR-0006 seperti biasa —
/// bukan galat, tapi juga bukan pemakaian yang dimaksud.
class AppHardCard extends StatelessWidget {
  /// Membuat [AppHardCard] dengan [child].
  const AppHardCard({
    required this.child,
    this.elevation = AppHardElevation.card,
    this.pressed = false,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.borderRadius,
    this.color,
    super.key,
  });

  /// Isi panel.
  final Widget child;

  /// Level bayangan, dari [AppHardElevation].
  final AppHardElevation elevation;

  /// True saat elemen [AppHardElevation.interactive] sedang ditekan —
  /// bayangan ditarik ke 0 dan isi bergeser sejauh offset bayangannya ke
  /// kanan-bawah, meniru `AppButton`. Diabaikan untuk level lain.
  final bool pressed;

  /// Padding di dalam panel.
  final EdgeInsetsGeometry padding;

  /// Sudut panel. Bawaan [AppRadius.pixelSmAll]. Pakai [AppRadius.none]
  /// (lewat `BorderRadius.zero`) untuk lencana status/pil kategori, yang
  /// ADR-015 sengaja memakai sudut tegas.
  final BorderRadius? borderRadius;

  /// Warna isian panel. Bawaan `context.appColors.cardBackground`.
  final Color? color;

  double get _offset => switch (elevation) {
        AppHardElevation.flat => 0,
        AppHardElevation.card => AppElevation.pixelCard,
        AppHardElevation.interactive => AppElevation.pixelInteractive,
        AppHardElevation.bottomSheet => AppElevation.pixelInteractive,
      };

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = borderRadius ?? AppRadius.pixelSmAll;
    final isPressed = pressed && elevation == AppHardElevation.interactive;
    final shadowOffset = isPressed ? 0.0 : _offset;

    final border = elevation == AppHardElevation.bottomSheet
        ? Border(
            top: BorderSide(color: colors.textPrimary, width: AppBorder.pixelThick),
            left: BorderSide(color: colors.textPrimary, width: AppBorder.pixelThick),
            right: BorderSide(color: colors.textPrimary, width: AppBorder.pixelThick),
          )
        : Border.all(color: colors.textPrimary, width: AppBorder.pixelThick);

    final shadow = switch (elevation) {
      AppHardElevation.flat => const <BoxShadow>[],
      AppHardElevation.bottomSheet => AppElevation.pixelBottomSheetShadow(colors.textPrimary),
      AppHardElevation.card || AppHardElevation.interactive =>
        AppElevation.hardShadow(colors.textPrimary, offset: shadowOffset),
    };

    return AnimatedContainer(
      duration: AppDurations.fast,
      transform: Matrix4.translationValues(isPressed ? _offset : 0, isPressed ? _offset : 0, 0),
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? colors.cardBackground,
        borderRadius: radius,
        border: border,
        boxShadow: shadow,
      ),
      child: child,
    );
  }
}
