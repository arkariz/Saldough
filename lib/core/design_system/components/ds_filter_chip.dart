import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/components/ds_pressable.dart';
import 'package:saldough/core/design_system/ds_theme.dart';
import 'package:saldough/core/design_system/tokens/ds_motion.dart';
import 'package:saldough/core/design_system/tokens/ds_radius.dart';

/// Chip penyaring berbentuk pil (acuan Riwayat): terpilih berisi
/// `actionPrimary` dengan teks putih, lainnya putih bergaris rambut. Area
/// sentuh minimal 44 tinggi.
class DsFilterChip extends StatelessWidget {
  /// Membuat chip penyaring.
  const DsFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  /// Teks chip.
  final String label;

  /// Chip sedang dipilih.
  final bool selected;

  /// Dipanggil saat diketuk.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final reduced = DsMotion.reduced(context);
    return Semantics(
      selected: selected,
      child: DsPressable(
        onPressed: onTap,
        pressedScale: 0.96,
        builder: (context, _) => ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          // widthFactor 1: chip selebar isinya, tidak memenuhi lebar induk
          // (di `Wrap` Center biasa membuat tiap chip turun satu baris).
          child: Center(
            widthFactor: 1,
            child: AnimatedContainer(
              duration: reduced ? Duration.zero : DsMotion.standard,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? c.actionPrimary : c.surfaceCard,
                borderRadius: DsRadius.fullAll,
                border: Border.all(
                  color: selected ? c.actionPrimary : c.outlineSubtle,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: c.actionPrimary.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                label,
                style: ds.typography.labelMd.copyWith(
                  fontSize: 12,
                  color: selected ? c.onActionPrimary : c.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
