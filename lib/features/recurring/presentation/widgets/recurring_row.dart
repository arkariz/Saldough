import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/recurring/presentation/recurring_display.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/category/category_presentation.dart';
import 'package:saldough/shared/recurring/recurring.dart';

/// Satu baris segmen Rutin (PLAN_TAB_LAYOUT §4.9): kotak tanggal di kiri
/// seperti jadwal, ubin ikon clay, nama + glyph status, nominal bertanda.
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
    final ds = context.ds;
    final c = ds.colors;
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
    final glyphColor = switch (status) {
      _ when priceUp => c.warning,
      OccurrenceStatus.recorded => c.income,
      _ => c.actionPrimary,
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
    final clay =
        ClayIcons.forIcon(icon) ??
        switch (rule.kind) {
          RecurringKind.income => ClayIcons.incomeArrow,
          RecurringKind.expense => ClayIcons.expenseArrow,
          RecurringKind.transfer => ClayIcons.transfer,
        };
    final due = status == OccurrenceStatus.pending || status == OccurrenceStatus.missed;
    final name = rule.note.isEmpty ? t.record.repeat.fallbackName : rule.note;
    final titleColor = muted ? c.textMuted : (priceUp ? c.warning : c.textPrimary);
    final amountColor = muted
        ? c.textMuted
        : switch (rule.kind) {
            RecurringKind.income => c.income,
            RecurringKind.expense => c.textPrimary,
            RecurringKind.transfer => c.textSecondary,
          };
    return DsPressable(
      semanticLabel: rule.note,
      onPressed: onTap,
      pressedScale: 0.99,
      builder: (context, _) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                child: date == null
                    ? null
                    : DecoratedBox(
                        decoration: BoxDecoration(
                          color: due ? c.actionPrimary.withValues(alpha: 0.12) : c.surfaceSunken,
                          borderRadius: DsRadius.mdAll,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                date.year == today.year ? '${date.day}' : CycleMonthFormatter.formatMonthShort(date),
                                style: ds.typography.amount.copyWith(
                                  fontSize: 17,
                                  height: 20 / 17,
                                  color: due ? c.actionPrimary : (muted ? c.textMuted : c.textPrimary),
                                ),
                              ),
                              Text(
                                date.year == today.year
                                    ? CycleMonthFormatter.formatWeekday(date).substring(0, 3)
                                    : "'${date.year % 100}",
                                style: ds.typography.bodySm.copyWith(fontSize: 11, color: c.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Opacity(
                opacity: muted ? 0.55 : 1,
                child: DsIconTile.asset(asset: clay, size: DsIconTileSize.sm),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        text: name,
                        children: [
                          if (glyph.isNotEmpty)
                            TextSpan(
                              text: glyph,
                              style: TextStyle(color: glyphColor),
                            ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ds.typography.titleMd.copyWith(color: titleColor),
                    ),
                    if (meta.isNotEmpty)
                      Text(
                        meta.join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ds.typography.bodySm.copyWith(color: c.textSecondary),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Nominal mengecil bila lebar sempit; judul tetap mendapat sisanya.
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 104),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerEnd,
                  child: Text(
                    signedAmount(rule.kind, amount, approximate: approximate),
                    style: ds.typography.amount.copyWith(color: amountColor),
                  ),
                ),
              ),
              if (status == OccurrenceStatus.recorded) ...[
                const SizedBox(width: 6),
                SvgPicture.asset(ClayIcons.done, width: 18, height: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
