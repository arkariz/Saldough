import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/tokens/ds_radius.dart';

/// Bentuk permukaan design system baru (`spec.md` bagian Shapes, ADR-043).
abstract final class DsShapes {
  DsShapes._();

  /// Checkbox dan segmen meter: [DsRadius.sm].
  static const RoundedRectangleBorder micro = RoundedRectangleBorder(borderRadius: DsRadius.smAll);

  /// Input, tombol, sel interaktif: [DsRadius.base].
  static const RoundedRectangleBorder control = RoundedRectangleBorder(borderRadius: DsRadius.baseAll);

  /// Tile ikon, tombol di kartu, kotak statistik: [DsRadius.md].
  static const RoundedRectangleBorder tile = RoundedRectangleBorder(borderRadius: DsRadius.mdAll);

  /// Kartu dan panel: [DsRadius.lg].
  static const RoundedRectangleBorder card = RoundedRectangleBorder(borderRadius: DsRadius.lgAll);

  /// Dialog dan overlay: [DsRadius.xl].
  static const RoundedRectangleBorder overlay = RoundedRectangleBorder(borderRadius: DsRadius.xlAll);

  /// Bottom sheet: sudut atas [DsRadius.sheet].
  static const RoundedRectangleBorder sheet = RoundedRectangleBorder(borderRadius: DsRadius.sheetTop);

  /// Badge, tag, chip: pil.
  static const StadiumBorder pill = StadiumBorder();

  /// Avatar dan titik status.
  static const CircleBorder circle = CircleBorder();
}
