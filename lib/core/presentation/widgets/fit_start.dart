import 'package:flutter/material.dart';

/// Memperkecil [child] (bukan memotong atau meluap) kalau lebih lebar dari
/// ruang yang tersedia, rata awal.
class FitStart extends StatelessWidget {
  /// Membuat [FitStart].
  const FitStart({required this.child, super.key});

  /// Isi yang boleh mengecil.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: child);
  }
}
