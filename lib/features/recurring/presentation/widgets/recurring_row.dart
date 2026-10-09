import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/recurring/presentation/recurring_display.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/category/category_presentation.dart';
import 'package:saldough/shared/recurring/recurring.dart';

/// Satu baris segmen Rutin (PLAN_TAB_LAYOUT §4.9, menggantikan §6.3): kolom
/// tanggal di kiri seperti jadwal, nama + glyph status, nominal bertanda.
/// Meta hanya bila bermakna ("4 dari 12", "ke Tabungan", kenaikan harga);
/// dompet dan cara bayar ada di rincian rutin.
class RecurringRow extends StatelessWidget {
  /// Membuat [RecurringRow].
  const RecurringRow({
    required this.entry,
    required this.toWalletName,
    required this.today,
    required this.onTap,
    super.key,
  });

  /// Barisnya.
  final RecurringEntry entry;

  /// Nama dompet tujuan (transfer).
  final String? toWalletName;

  /// Hari ini.
  final DateTime today;

  /// Ketukan baris.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final rule = entry.rule;
    final occurrence = entry.occurrence;
    final recorded = occurrence?.transaction;
    final status = occurrence?.status;
    final priceUp =
        recorded != null &&
        rule.amountMode == RecurringAmountMode.fixed &&
        isPriceIncrease(planned: rule.amount, recorded: recorded.amount);
    final amount = recorded?.amount ?? rule.amount;
    final approximate = recorded == null && rule.amountMode == RecurringAmountMode.estimated;
    final glyph = switch (status) {
      _ when priceUp => ' !',
      OccurrenceStatus.recorded => ' ✓',
      OccurrenceStatus.pending || OccurrenceStatus.missed => ' ●',
      _ => '',
    };
    final end = rule.end;
    final meta = <String>[
      if (priceUp)
        t.recurring.priceUp(
          amount: AppMoneyFormatter.format(recorded.amount),
          usual: AppMoneyFormatter.format(rule.amount),
        ),
      if (entry.missedCount > 0) t.recurring.missedMeta(n: entry.missedCount),
      if ((entry.position, end) case (final k?, RecurringEndsAfter(:final count)))
        t.recurring.positionMeta(k: k, n: count),
      if (rule.kind == RecurringKind.transfer && toWalletName != null) t.recurring.toWalletMeta(wallet: toWalletName!),
    ];
    final muted =
        status == OccurrenceStatus.recorded ||
        entry.group == RecurringGroup.paused ||
        entry.group == RecurringGroup.ended;
    final date = occurrence?.date;
    final category = ActiveCategories.byId(rule.categoryId);
    final icon = category != null
        ? categoryIcon(category, title: rule.note)
        : switch (rule.kind) {
            RecurringKind.income => IconKey.income,
            RecurringKind.expense => IconKey.expense,
            RecurringKind.transfer => IconKey.transfer,
          };
    final ink = muted ? colors.ink3 : colors.ink;
    // Baris jadwal (`rencana.css` `.sched`): kolom tanggal 40px, tile,
    // judul + meta, nominal bertanda; yang sudah tercatat diredupkan `ink3`.
    return Semantics(
      button: true,
      label: rule.note,
      child: InkWell(
        onTap: onTap,
        overlayColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.pressed) ? colors.surface2 : Colors.transparent,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSize.row),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: AppSize.tile,
                  child: date == null
                      ? null
                      : Column(
                          children: [
                            Text(
                              date.year == today.year ? '${date.day}' : CycleMonthFormatter.formatMonthShort(date),
                              style: context.numberStyles.amountLg.copyWith(fontSize: 18, height: 22 / 18, color: ink),
                            ),
                            Text(
                              date.year == today.year
                                  ? CycleMonthFormatter.formatWeekday(date).substring(0, 3)
                                  : "'${date.year % 100}",
                              style: textTheme.bodySmall?.copyWith(color: colors.ink2),
                            ),
                          ],
                        ),
                ),
                const SizedBox(width: AppSpacing.space3),
                AppIconTile(icon),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${rule.note.isEmpty ? t.record.repeat.fallbackName : rule.note}$glyph',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          color: muted ? colors.ink3 : (priceUp ? colors.warning : colors.ink),
                        ),
                      ),
                      if (meta.isNotEmpty)
                        Text(
                          meta.join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium?.copyWith(color: colors.ink2),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.space2),
                Flexible(
                  flex: 0,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      signedAmount(rule.kind, amount, approximate: approximate),
                      style: context.numberStyles.amount.copyWith(
                        color: muted
                            ? colors.ink3
                            : switch (rule.kind) {
                                RecurringKind.income => colors.positive,
                                RecurringKind.expense => colors.ink,
                                RecurringKind.transfer => colors.ink2,
                              },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
