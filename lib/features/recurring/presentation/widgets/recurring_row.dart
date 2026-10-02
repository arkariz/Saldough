import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/recurring/presentation/recurring_display.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction_presentation.dart';

/// Satu baris segmen Rutin (PLAN_TAB_LAYOUT §6.3): kotak ikon kategori
/// (satu-satunya penanda warna), nama + glyph status, nominal bertanda, dan
/// meta paling banyak empat butir.
class RecurringRow extends StatelessWidget {
  /// Membuat [RecurringRow].
  const RecurringRow({
    required this.entry,
    required this.walletName,
    required this.toWalletName,
    required this.today,
    required this.onTap,
    super.key,
  });

  /// Barisnya.
  final RecurringEntry entry;

  /// Nama dompet rutin.
  final String? walletName;

  /// Nama dompet tujuan (transfer).
  final String? toWalletName;

  /// Hari ini.
  final DateTime today;

  /// Membuka rincian rutin.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final rule = entry.rule;
    final occurrence = entry.occurrence;
    final recorded = occurrence?.transaction;
    final status = occurrence?.status;
    final isRecorded = status == OccurrenceStatus.recorded;
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
    final wallet = rule.kind == RecurringKind.transfer ? '${walletName ?? '?'} → ${toWalletName ?? '?'}' : walletName;
    final meta = <String>[
      ?wallet,
      if (occurrence != null) occurrenceDateText(occurrence.date, today),
      if (priceUp)
        t.recurring.priceUp(
          amount: AppMoneyFormatter.format(recorded.amount),
          usual: AppMoneyFormatter.format(rule.amount),
        )
      else if (isRecorded)
        t.recurring.recordedMeta
      else if (entry.missedCount > 0)
        t.recurring.missedMeta(n: entry.missedCount)
      else if (rule.paymentMode != null)
        rule.paymentMode == RecurringPaymentMode.autoDebit ? t.recurring.paymentAutoDebit : t.recurring.paymentManual,
      if (entry.position case final k? when rule.end is RecurringEndsAfter)
        '$k/${(rule.end as RecurringEndsAfter).count}'
      else if (rule.schedule.frequency == RecurringFrequency.yearly)
        t.recurring.yearlyMeta,
    ].take(4);
    final muted = isRecorded || entry.group == RecurringGroup.paused || entry.group == RecurringGroup.ended;
    return AppTappable(
      label: rule.note,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            children: [
              TransactionIcon(kind: transactionKindOf(rule.kind), categoryId: rule.categoryId),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${rule.note.isEmpty ? t.record.repeat.fallbackName : rule.note}$glyph',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: muted ? colors.textMuted : (priceUp ? colors.pending : null),
                      ),
                    ),
                    Text(
                      meta.join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                signedAmount(rule.kind, amount, approximate: approximate),
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: muted
                      ? colors.textMuted
                      : switch (rule.kind) {
                          RecurringKind.income => colors.income,
                          RecurringKind.expense => colors.expense,
                          RecurringKind.transfer => colors.textPrimary,
                        },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
