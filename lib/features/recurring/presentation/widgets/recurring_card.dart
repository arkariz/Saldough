import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/recurring/presentation/recurring_display.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/category/category_presentation.dart';
import 'package:saldough/shared/recurring/recurring.dart';

/// Kartu satu rutin di umpan segmen Rutin: ubin ikon clay 48 berwarna, judul
/// dengan penanda kategori, dompet dan jadwal, nominal dengan jatuh tempo
/// relatif di kanan, lalu kaki kartu (status pembayaran, Jeda, dan panah ke
/// rincian). Ketuk kartu = rincian. Nominal dan jatuh tempo hanya
/// menampilkan; tidak ada yang mengubah transaksi atau saldo.
class RecurringCard extends StatelessWidget {
  /// Membuat [RecurringCard].
  const RecurringCard({
    required this.entry,
    required this.walletName,
    required this.toWalletName,
    required this.today,
    required this.onTap,
    required this.onTogglePause,
    super.key,
  });

  /// Barisnya.
  final RecurringEntry entry;

  /// Nama dompet sumber.
  final String? walletName;

  /// Nama dompet tujuan (transfer).
  final String? toWalletName;

  /// Hari ini.
  final DateTime today;

  /// Membuka rincian.
  final VoidCallback onTap;

  /// Menjeda atau melanjutkan.
  final VoidCallback onTogglePause;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final rule = entry.rule;
    final occurrence = entry.occurrence;
    final recorded = occurrence?.transaction;
    final status = occurrence?.status;
    final paused = rule.isPaused;
    final ended = entry.group == RecurringGroup.ended;
    final muted = paused || ended || status == OccurrenceStatus.recorded;
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
    final tone = switch (rule.kind) {
      RecurringKind.income => DsIconTileTone.income,
      RecurringKind.expense => DsIconTileTone.neutral,
      RecurringKind.transfer => DsIconTileTone.info,
    };
    final name = rule.note.isEmpty ? t.record.repeat.fallbackName : rule.note;
    final where = rule.kind == RecurringKind.transfer ? '${walletName ?? '?'} → ${toWalletName ?? '?'}' : walletName;
    final subtitle = [?where, scheduleText(rule)].join(' · ');
    final date = occurrence?.date;
    final dueLabel = paused
        ? t.recurring.pausedLine
        : date == null
        ? null
        : (entry.group == RecurringGroup.later ? occurrenceDateText(date, today) : dueText(date, today));
    final dueColor = switch ((paused, date == null ? null : dueStateOf(date, today))) {
      (true, _) => c.textMuted,
      (_, DueState.overdue) => c.warning,
      (_, DueState.today) => c.actionPrimary,
      _ => c.textSecondary,
    };
    final amountColor = muted
        ? c.textMuted
        : switch (rule.kind) {
            RecurringKind.income => c.income,
            RecurringKind.expense => c.textPrimary,
            RecurringKind.transfer => c.textSecondary,
          };
    // Kaki kartu: cara bayar (expense) atau jenisnya; titik aksi saat aktif.
    final footerText = rule.kind == RecurringKind.expense
        ? (rule.effectivePaymentMode == RecurringPaymentMode.autoDebit
              ? t.recurring.autoDebitLine
              : t.recurring.reminderLine(n: rule.remindDaysBefore))
        : switch (rule.kind) {
            RecurringKind.income => t.record.kindIncome,
            _ => t.record.kindTransfer,
          };
    final meta = <String>[
      if (priceUp)
        t.recurring.priceUp(
          amount: AppMoneyFormatter.format(recorded.amount),
          usual: AppMoneyFormatter.format(rule.amount),
        ),
      if (entry.missedCount > 0) t.recurring.missedMeta(n: entry.missedCount),
      if ((entry.position, rule.end) case (final k?, RecurringEndsAfter(:final count)))
        t.recurring.positionMeta(k: k, n: count),
    ];
    return DsCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 10),
      onTap: onTap,
      child: Semantics(
        button: true,
        label: rule.note,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Opacity(
                  opacity: muted ? 0.55 : 1,
                  child: DsIconTile.asset(asset: clay, tone: tone, size: DsIconTileSize.lg),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text.rich(
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
                              style: ds.typography.titleMd.copyWith(color: muted ? c.textMuted : c.textPrimary),
                            ),
                          ),
                          if (category != null) ...[
                            const SizedBox(width: 6),
                            Flexible(
                              flex: 0,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 84),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: DsBadge(label: category.name),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ds.typography.bodySm.copyWith(color: c.textSecondary),
                      ),
                      if (meta.isNotEmpty)
                        Text(
                          meta.join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ds.typography.bodySm.copyWith(color: priceUp ? c.warning : c.textSecondary),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 110),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerEnd,
                        child: Text(
                          signedAmount(rule.kind, amount, approximate: approximate),
                          style: ds.typography.amount.copyWith(fontSize: 17, height: 24 / 17, color: amountColor),
                        ),
                      ),
                    ),
                    if (dueLabel != null)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 110),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerEnd,
                          child: Text(
                            dueLabel,
                            style: ds.typography.labelMd.copyWith(fontSize: 11, color: dueColor),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Divider(height: 1, color: c.outlineSubtle),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: muted ? c.outline : c.actionPrimary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    footerText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ds.typography.labelMd.copyWith(fontSize: 12, color: c.textSecondary),
                  ),
                ),
                if (!ended) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 92,
                    child: DsInlineAction(
                      dense: true,
                      label: paused ? t.recurring.resumeAction : t.recurring.pauseAction,
                      onPressed: onTogglePause,
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                Icon(Icons.more_horiz, size: 20, color: c.textMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
