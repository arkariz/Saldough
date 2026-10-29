import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/tokens/ds_radius.dart';

/// Bentuk permukaan design system baru (spek bagian Shapes, ADR-043).
abstract final class DsShapes {
  DsShapes._();

  /// Kontrol mikro (badge, checkbox, switch): sudut [DsRadius.sm].
  static const RoundedRectangleBorder micro = RoundedRectangleBorder(borderRadius: DsRadius.smAll);

  /// Input, tombol, chip: sudut [DsRadius.base].
  static const RoundedRectangleBorder control = RoundedRectangleBorder(borderRadius: DsRadius.baseAll);

  /// Kartu, panel, dialog, menu: sudut [DsRadius.lg].
  static const RoundedRectangleBorder card = RoundedRectangleBorder(borderRadius: DsRadius.lgAll);

  /// Bottom sheet: sudut atas [DsRadius.xl].
  static const RoundedRectangleBorder sheet = RoundedRectangleBorder(borderRadius: DsRadius.sheetTop);

  /// Avatar dan titik status.
  static const CircleBorder circle = CircleBorder();
}
