import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/color/ds_color_scheme.dart';
import 'package:saldough/core/design_system/tokens/ds_radius.dart';
import 'package:saldough/core/design_system/typography/ds_typography.dart';

/// Tema snackbar v2: permukaan terbalik bersudut 16px, mengambang di atas
/// bilah bawah, tanpa bayangan.
SnackBarThemeData dsSnackBarTheme(DsColorScheme colors, DsTypography typography) => SnackBarThemeData(
  backgroundColor: colors.inverseSurface,
  contentTextStyle: typography.bodyMd.copyWith(color: colors.inverseOnSurface),
  actionTextColor: colors.inversePrimary,
  behavior: SnackBarBehavior.floating,
  elevation: 0,
  insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
  shape: const RoundedRectangleBorder(borderRadius: DsRadius.lgAll),
);
