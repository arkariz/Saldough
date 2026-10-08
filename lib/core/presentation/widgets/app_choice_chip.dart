import 'package:flutter/material.dart';
import 'package:saldough/core/presentation/widgets/kind_surfaces.dart';
import 'package:saldough/core/theme/theme.dart';

/// Chip penyaring yang bisa terpilih (PLAN_TAB_LAYOUT §3.2): pilihan aktif
/// terisi `accent`, lainnya `surfaceMid`. Untuk mempersempit isi layar yang
/// sama, mis. status anggaran atau jenis rutin, bukan untuk berpindah tempat
/// (`AppSubTabs`) atau memilih nilai formulir (`AppSegmented`).
class AppChoiceChip extends StatelessWidget {
  /// Membuat [AppChoiceChip].
  const AppChoiceChip({required this.label, required this.selected, required this.onTap, super.key});

  /// Teks chip.
  final String label;

  /// Apakah chip ini pilihan aktif.
  final bool selected;

  /// Dipanggil saat chip diketuk.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: selected ? colors.brand : colors.surface2,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              widthFactor: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space2),
                child: Text(
                  label,
                  maxLines: 1,
                  style: transactionLabelStyle(context, color: selected ? colors.onBrand : colors.ink),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
