import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/ds_theme.dart';

/// Bilah tindakan yang menempel di dasar layar: latar `surfaceCanvas`, garis
/// atas rambut, mengikuti area aman bawah. Isinya biasanya satu tombol
/// selebar penuh atau kolom tombol.
class DsStickyBar extends StatelessWidget {
  /// Membuat bilah.
  const DsStickyBar({required this.child, super.key});

  /// Isi bilah.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.ds.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surfaceCanvas,
        border: Border(top: BorderSide(color: c.outlineSubtle)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 16), child: child),
      ),
    );
  }
}
