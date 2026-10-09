import 'package:flutter/material.dart';
import 'package:saldough/core/presentation/widgets/pixel_corner_border.dart';
import 'package:saldough/core/theme/theme.dart';

/// Kotak pilihan di pemilih formulir (jenis dompet, dompet anggaran, warna
/// proyek, bahasa): `surface2` biasa; terpilih `brandSoft` dengan garis
/// dalam `brand` 2px, sama dengan tile kategori terpilih di Catat.
class AppChoiceBox extends StatelessWidget {
  /// Membuat [AppChoiceBox].
  const AppChoiceBox({
    required this.selected,
    required this.onTap,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.space2),
    this.constraints,
    this.unselectedColor,
    super.key,
  });

  /// Terpilih.
  final bool selected;

  /// Dipanggil saat diketuk.
  final VoidCallback onTap;

  /// Isi kotak.
  final Widget child;

  /// Jarak dalam.
  final EdgeInsetsGeometry padding;

  /// Batas ukuran, mis. tinggi minimal.
  final BoxConstraints? constraints;

  /// Latar saat tidak terpilih; bawaan `surface2`.
  final Color? unselectedColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: constraints,
          padding: padding,
          decoration: ShapeDecoration(
            color: selected ? colors.brandSoft : (unselectedColor ?? colors.surface2),
            shape: PixelCornerBorder(
              side: selected ? BorderSide(color: colors.brand, width: 2) : BorderSide.none,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
