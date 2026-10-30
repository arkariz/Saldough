import 'package:flutter/material.dart';

/// `MaterialApp.builder` yang menyalakan "kurangi animasi" (ADR-043).
///
/// Beranda dan komponen design system v2 punya animasi berulang (partikel
/// latar, denyut, meter bernapas); tanpa ini `pumpAndSettle` di uji
/// fungsional tidak pernah selesai. Animasinya sendiri diuji di
/// `test/core/design_system/ds_motion_test.dart`.
Widget reducedMotion(BuildContext context, Widget? child) => MediaQuery(
  data: MediaQuery.of(context).copyWith(disableAnimations: true),
  child: child ?? const SizedBox.shrink(),
);
