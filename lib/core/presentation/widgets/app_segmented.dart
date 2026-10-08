import 'package:flutter/material.dart';
import 'package:saldough/core/presentation/widgets/kind_surfaces.dart';
import 'package:saldough/core/theme/theme.dart';

/// Dua (atau lebih) pilihan bergaya tab: periode dan mode nominal pos
/// anggaran, potongan proyek, dan jenis transaksi CATAT (UX-1). Dipindah dari
/// fitur budget (`AppSegmented`) supaya fitur lain tidak mengimpor budget.
class AppSegmented<T> extends StatelessWidget {
  /// Membuat [AppSegmented].
  const AppSegmented({required this.options, required this.selected, required this.onChanged, super.key});

  /// Pilihan beserta labelnya, sesuai urutan.
  final List<(T, String)> options;

  /// Pilihan aktif.
  final T selected;

  /// Dipanggil dengan pilihan baru.
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return TransactionSlab(
      color: colors.surface2,
      padding: const EdgeInsets.all(AppSpacing.space1),
      shadow: 2,
      child: Row(
        children: [
          for (final (value, label) in options) ...[
            if (value != options.first.$1) const SizedBox(width: AppSpacing.space1),
            Expanded(
              child: Semantics(
                button: true,
                selected: value == selected,
                child: GestureDetector(
                  onTap: () => onChanged(value),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 44),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: value == selected ? colors.brand : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      label.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: transactionLabelStyle(
                        context,
                        color: value == selected ? colors.onBrand : colors.ink2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
