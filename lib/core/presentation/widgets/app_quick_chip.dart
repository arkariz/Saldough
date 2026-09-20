import 'package:flutter/material.dart';
import 'package:saldough/core/presentation/widgets/kind_surfaces.dart';
import 'package:saldough/core/theme/theme.dart';

/// Chip kecil pilihan cepat ("+10rb", "Bersihkan") di bawah kolom nominal.
///
/// Lebarnya mengikuti isi, dan tinggi minimumnya 40px supaya nyaman diketuk.
/// `Center(widthFactor: 1)`, BUKAN `Container(alignment: center)`:
/// `alignment` membuat Container mengisi seluruh lebar yang ditawarkan
/// `Wrap`, sehingga tiap chip melebar penuh dan bertumpuk vertikal.
class AppQuickChip extends StatelessWidget {
  /// Membuat [AppQuickChip].
  const AppQuickChip({required this.label, required this.onTap, this.color, super.key});

  /// Teks chip.
  final String label;

  /// Dipanggil saat chip diketuk.
  final VoidCallback onTap;

  /// Warna isian. Bawaan `surfaceMid`.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 44, minHeight: 40),
        child: DecoratedBox(
          decoration: BoxDecoration(color: color ?? colors.surfaceMid, borderRadius: BorderRadius.circular(8)),
          child: Center(
            widthFactor: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text(label, style: transactionLabelStyle(context, color: colors.textPrimary)),
            ),
          ),
        ),
      ),
    );
  }
}
