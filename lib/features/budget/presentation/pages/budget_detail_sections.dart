part of 'budget_detail_page.dart';

// Bagian layar rincian anggaran (dipecah dari `budget_detail_page.dart`, ADR-030 A9).

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onEdit});

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return TransactionSlab(
      color: colors.surfaceMid,
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: AppTappable(
              onTap: () => Navigator.of(context).maybePop(),
              child: SizedBox(
                height: 44,
                child: Row(
                  children: [
                    const SizedBox(width: AppSpacing.xs),
                    AppIcon(IconKey.chevronLeft, color: colors.textPrimary),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      t.budget.detailBackLabel.toUpperCase(),
                      style: transactionLabelStyle(context, size: 12, color: colors.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Semantics(
            button: true,
            label: t.budget.detailEditAction,
            child: GestureDetector(
              onTap: onEdit,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: colors.cardBackground, borderRadius: BorderRadius.circular(4)),
                    child: AppIcon(IconKey.edit, size: 20, color: colors.textPrimary),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu utama: nama, periode + status, rentang tanggal, dompet beserta
/// saldonya, lalu rencana/terpakai/sisa dan bilah progres.
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.budget, required this.progress, required this.wallet});

  final Budget budget;
  final BudgetProgress progress;
  final Wallet? wallet;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final overspent = progress.spendingStatus == BudgetItemStatus.overspent;
    return TransactionSlab(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(budget.name, style: textTheme.headlineSmall),
          const SizedBox(height: 4),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: 4,
            children: [
              BudgetBadge(label: budgetPeriodLabel(budget.period)),
              BudgetBadge(
                label: budgetStatusLabel(progress.status),
                color: progress.status == BudgetStatus.active ? colors.income : colors.textMuted,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              AppIcon(IconKey.calendar, size: 16, color: colors.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(budgetRangeLabel(budget), style: textTheme.bodySmall?.copyWith(color: colors.textMuted)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(color: colors.surfaceLow, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                AppIcon(wallet == null ? IconKey.wallets : walletIconKey(wallet!.iconKey), size: 28),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(wallet?.name ?? t.budget.unknownWallet, style: textTheme.titleMedium)),
                if (wallet != null)
                  Text(
                    AppMoneyFormatter.format(wallet!.currentBalance),
                    style: PixelTypography.tabularMono(context, color: colors.textMuted),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _Stat(label: t.budget.plannedLabel, sen: progress.plannedAmount, color: colors.textPrimary),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _Stat(
                  label: t.budget.spentLabel,
                  sen: progress.spent,
                  color: overspent ? colors.overBudget : colors.expense,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _Stat(
                  label: t.budget.remainingLabel,
                  sen: progress.remaining,
                  color: progress.remaining < 0 ? colors.overBudget : colors.income,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  t.budget
                      .spentPercentLabel(percent: budgetPercent(progress.spent, progress.plannedAmount))
                      .toUpperCase(),
                  style: transactionLabelStyle(context, color: colors.textMuted),
                ),
              ),
              Text(
                budgetItemStatusLabel(progress.spendingStatus).toUpperCase(),
                style: transactionLabelStyle(context, color: budgetItemStatusColor(context, progress.spendingStatus)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          BudgetProgressBar(value: progress.progress, height: 14),
          const SizedBox(height: 4),
          // Penanda laju waktu (ADR-020 §3.5/UX-10): "terpakai X%" sendirian
          // tidak menjawab "apakah aku masih di jalur" -- dibandingkan
          // dengan fraksi periode yang sudah berlalu.
          Text(
            t.budget.paceLabel(percent: (budget.elapsedRatio(DateTime.now()) * 100).round()).toUpperCase(),
            style: transactionLabelStyle(context, color: colors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.sen, required this.color});

  final String label;
  final int sen;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(color: colors.surfaceLow, borderRadius: BorderRadius.circular(4)),
      child: Column(
        children: [
          Text(label.toUpperCase(), style: transactionLabelStyle(context, size: 9, color: colors.textMuted)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(AppMoneyFormatter.format(sen), style: PixelTypography.tabularMono(context, color: color)),
          ),
        ],
      ),
    );
  }
}

/// Kartu satu pos: nama, status (empat kondisi), bilah progres,
/// rencana/terpakai/sisa, dan pintasan CATAT dengan pos ini terpilih.
/// Lewat anggaran memakai `overBudget`, bukan gaya kesalahan (FR-BUD-007).
class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.progress,
    required this.targetWalletName,
    required this.onRecord,
    this.spotlighted = false,
  });

  /// True untuk pos pertama: kartunya dan tombol catatnya jadi target tur.
  final bool spotlighted;

  final BudgetItemProgress progress;

  /// Nama dompet tujuan pos transfer.
  final String? targetWalletName;

  /// Membuka CATAT untuk pos ini, atau `null` (anggaran nonaktif).
  final VoidCallback? onRecord;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final item = progress.item;
    final statusColor = budgetItemStatusColor(context, progress.status);
    final overspent = progress.status == BudgetItemStatus.overspent;
    return SpotlightTarget(
      spotlightKey: spotlighted ? SpotlightKey.budgetDetailItem : null,
      child: TransactionSlab(
        color: overspent ? colors.tinted(colors.expenseFill, 0.08) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: textTheme.titleMedium),
                      const SizedBox(height: 2),
                      BudgetBadge(
                        label: item.isTransfer
                            ? '${t.budget.itemKindTransfer} · ${t.budget.itemTransferTo(wallet: targetWalletName ?? t.budget.unknownWallet)}'
                            : t.budget.itemKindExpense,
                        color: item.isTransfer ? colors.transfer : colors.textMuted,
                      ),
                      if (item.isItemized)
                        Text(
                          t.budget.itemItemizedDetail(
                            quantity: item.quantity!,
                            price: AppMoneyFormatter.format(item.unitPrice!),
                          ),
                          style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                BudgetBadge(label: budgetItemStatusLabel(progress.status), color: statusColor),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            BudgetProgressBar(value: progress.progress),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: 2,
              children: [
                _Figure(label: t.budget.plannedLabel, sen: item.plannedAmount, color: colors.textPrimary),
                _Figure(
                  label: t.budget.spentLabel,
                  sen: progress.spent,
                  color: overspent ? colors.overBudget : colors.textPrimary,
                ),
                _Figure(
                  label: t.budget.remainingLabel,
                  sen: progress.remaining,
                  color: progress.remaining < 0 ? colors.overBudget : colors.income,
                ),
              ],
            ),
            if (onRecord case final record?) ...[
              const SizedBox(height: AppSpacing.xs),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: SpotlightTarget(
                  spotlightKey: spotlighted ? SpotlightKey.budgetDetailRecord : null,
                  child: item.isTransfer
                      ? AppQuickChip(
                          label: t.budget.detailRecordTransferAction,
                          color: colors.tinted(colors.transferFill, 0.2),
                          onTap: record,
                        )
                      : AppQuickChip(label: t.budget.detailRecordExpenseAction, onTap: record),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.sen, required this.color});

  final String label;
  final int sen;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(color: context.appColors.textMuted),
          ),
          TextSpan(
            text: AppMoneyFormatter.format(sen),
            style: TextStyle(color: color),
          ),
        ],
      ),
      style: PixelTypography.tabularMono(context, fontSize: 12),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks({required this.walletName});

  final String walletName;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    return TransactionSlab(
      color: colors.surfaceLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.budget.detailHowTitle, style: textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(t.budget.detailHowBody(wallet: walletName), style: textTheme.bodySmall),
        ],
      ),
    );
  }
}
