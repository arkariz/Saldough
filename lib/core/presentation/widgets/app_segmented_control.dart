import 'package:flutter/material.dart';
import 'package:saldough/core/presentation/widgets/pixel_corner_border.dart';
import 'package:saldough/core/theme/theme.dart';

/// Pilihan satu dari dua sampai empat opsi yang langsung mengubah isi di
/// bawahnya (komponen SegmentedControl, ADR-034): jenis transaksi di Catat,
/// status anggaran, kotak masuk.
///
/// Track `surface2`, segmen terpilih `surfaceRaised` dengan `shadow-raised`
/// dan teks `ink`; segmen lain `ink2`. Jumlah opsional setelah label.
/// Dibaca pembaca layar sebagai kelompok pilihan tunggal.
class AppSegmentedControl<T> extends StatelessWidget {
  /// Membuat [AppSegmentedControl].
  const AppSegmentedControl({
    required this.options,
    required this.selected,
    required this.onChanged,
    this.counts = const {},
    super.key,
  });

  /// Pilihan beserta labelnya, sesuai urutan.
  final List<(T, String)> options;

  /// Pilihan aktif.
  final T selected;

  /// Dipanggil dengan pilihan baru.
  final ValueChanged<T> onChanged;

  /// Jumlah per pilihan, ditampilkan setelah label.
  final Map<T, int> counts;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space1),
      decoration: ShapeDecoration(
        color: colors.surface2,
        shape: const PixelCornerBorder.small(),
      ),
      child: Row(
        children: [
          for (final (i, (value, label)) in options.indexed) ...[
            if (i > 0) const SizedBox(width: AppSpacing.space1),
            Expanded(
              child: Semantics(
                inMutuallyExclusiveGroup: true,
                checked: value == selected,
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(value),
                  child: AnimatedContainer(
                    duration: AppDurations.fast,
                    constraints: const BoxConstraints(minHeight: AppSize.tile),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space2,
                      vertical: AppSpacing.space1,
                    ),
                    decoration: ShapeDecoration(
                      color: value == selected
                          ? colors.surfaceRaised
                          : colors.surface2.withValues(alpha: 0),
                      shape: const PixelCornerBorder.small(),
                      shadows: value == selected
                          ? [
                              BoxShadow(
                                color: colors.ink.withValues(alpha: 0.15),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      heightFactor: 1,
                      child: Text.rich(
                        TextSpan(
                          text: label,
                          children: [
                            if (counts[value] case final count?)
                              TextSpan(
                                text: ' $count',
                                style: TextStyle(
                                  color: value == selected
                                      ? colors.ink2
                                      : colors.ink3,
                                ),
                              ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        style: textTheme.labelLarge?.copyWith(
                          color: value == selected ? colors.ink : colors.ink2,
                        ),
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
