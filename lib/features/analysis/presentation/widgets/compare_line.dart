import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/analysis/domain/period_comparison.dart';

/// Label pembanding: "rata-rata 3 bulan", "bulan lalu", atau "rata-rata s.d.
/// tanggal 10" untuk periode berjalan (B-6, B-16).
String compareLabel(PeriodComparison comparison) => compareLabelOf(months: comparison.months, toDay: comparison.toDay);

/// Label pembanding untuk [months] bulan pembanding; [toDay] bila periode berjalan.
String compareLabelOf({required int months, int? toDay}) {
  if (toDay != null) return t.analysis.compare.toDate(day: toDay);
  return months == 1 ? t.analysis.compare.lastMonth : t.analysis.compare.avg(n: months);
}

/// Selisih terhadap pembanding di bawah donat (`tk-cmp`): panah, nominal
/// tebal, "dibanding {label}"; atau "baru bulan ini" untuk kategori tanpa
/// riwayat. Tidak tampil bila tidak ada rata-rata untuk dibandingkan.
class CompareLine extends StatelessWidget {
  /// Membuat [CompareLine].
  const CompareLine({
    required this.label,
    required this.result,
    required this.isGroup,
    required this.isUncategorized,
    this.alignStart = false,
    super.key,
  });

  /// Label pembanding, mis. "rata-rata 3 bulan" ([compareLabelOf]).
  final String label;

  /// Selisih yang ditampilkan: total atau satu baris.
  final Comparison result;

  /// [result] milik satu baris/kategori (boleh "baru bulan ini").
  final bool isGroup;

  /// Baris itu Tanpa kategori (tidak pernah "baru bulan ini").
  final bool isUncategorized;

  /// Rata kiri tanpa lekuk (di dalam kartu rincian); bawaannya rata tengah di bawah donat.
  final bool alignStart;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    if (isGroup && result.isNew && !isUncategorized) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.space2),
        child: Center(
          child: AppBadge(
            t.analysis.compare.newThisMonth,
            key: const ValueKey('analysis-new'),
          ),
        ),
      );
    }
    if (!result.hasBaseline) return const SizedBox.shrink();
    final style = textTheme.bodyMedium?.copyWith(color: colors.ink2);
    final amount = AppMoneyFormatter.format(result.difference);
    final label = t.analysis.compare.vs(label: this.label);
    return Padding(
      key: const ValueKey('analysis-compare'),
      padding: alignStart
          ? EdgeInsets.zero
          : const EdgeInsets.only(
              top: AppSpacing.space2,
              left: AppSpacing.space4,
              right: AppSpacing.space4,
            ),
      child: Semantics(
        container: true,
        label: result.isHigher
            ? t.analysis.compare.srHigher(amount: amount, label: label)
            : t.analysis.compare.srLower(amount: amount, label: label),
        excludeSemantics: true,
        child: Row(
          mainAxisAlignment: alignStart ? MainAxisAlignment.start : MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: AppIcon(
                result.isHigher ? IconKey.arrowUp : IconKey.arrowDown,
                size: 16,
                color: colors.ink2,
              ),
            ),
            const SizedBox(width: AppSpacing.space1),
            Flexible(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: amount,
                      style: style?.copyWith(
                        color: colors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(text: ' $label'),
                  ],
                ),
                style: style,
                textAlign: alignStart ? TextAlign.start : TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
