part of 'budget_detail_page.dart';

// Bagian layar rincian anggaran (dipecah dari `budget_detail_page.dart`, ADR-030 A9).

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onEdit});

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AppCard(
      color: colors.surface2,
      padding: const EdgeInsets.all(AppSpacing.space1),
      child: Row(
        children: [
          Expanded(
            child: AppTappable(
              onTap: () => Navigator.of(context).maybePop(),
              child: SizedBox(
                height: 44,
                child: Row(
                  children: [
                    const SizedBox(width: AppSpacing.space1),
                    AppIcon(IconKey.chevronLeft, color: colors.ink),
                    const SizedBox(width: AppSpacing.space1),
                    Text(
                      t.budget.detailBackLabel.toUpperCase(),
                      style: labelSmStyle(context, color: colors.ink),
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
                    decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(4)),
                    child: AppIcon(IconKey.edit, size: 20, color: colors.ink),
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
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(budget.name, style: textTheme.headlineSmall),
          const SizedBox(height: 4),
          Wrap(
            spacing: AppSpacing.space1,
            runSpacing: 4,
            children: [
              BudgetBadge(label: budgetPeriodLabel(budget.period)),
              BudgetBadge(
                label: budgetStatusLabel(progress.status),
                color: progress.status == BudgetStatus.active ? colors.positive : colors.ink2,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space1),
          Row(
            children: [
              AppIcon(IconKey.calendar, size: 16, color: colors.ink2),
              const SizedBox(width: 4),
              Expanded(
                child: Text(budgetRangeLabel(budget), style: textTheme.bodySmall?.copyWith(color: colors.ink2)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          Container(
            padding: const EdgeInsets.all(AppSpacing.space2),
            decoration: BoxDecoration(color: colors.surface2, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                AppIcon(wallet == null ? IconKey.wallets : walletIconKey(wallet!.iconKey), size: 28),
                const SizedBox(width: AppSpacing.space2),
                Expanded(child: Text(wallet?.name ?? t.budget.unknownWallet, style: textTheme.titleMedium)),
                if (wallet != null)
                  Text(
                    AppMoneyFormatter.format(wallet!.currentBalance),
                    style: context.numberStyles.amountSm.copyWith(color: colors.ink2),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Row(
            children: [
              Expanded(
                child: _Stat(label: t.budget.plannedLabel, sen: progress.plannedAmount, color: colors.ink),
              ),
              const SizedBox(width: AppSpacing.space1),
              Expanded(
                child: _Stat(
                  label: t.budget.spentLabel,
                  sen: progress.spent,
                  color: overspent ? colors.danger : colors.ink,
                ),
              ),
              const SizedBox(width: AppSpacing.space1),
              Expanded(
                child: _Stat(
                  label: t.budget.remainingLabel,
                  sen: progress.remaining,
                  color: progress.remaining < 0 ? colors.danger : colors.positive,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          Row(
            children: [
              Expanded(
                child: Text(
                  t.budget
                      .spentPercentLabel(percent: budgetPercent(progress.spent, progress.plannedAmount))
                      .toUpperCase(),
                  style: labelSmStyle(context, color: colors.ink2),
                ),
              ),
              Text(
                budgetItemStatusLabel(progress.spendingStatus).toUpperCase(),
                style: labelSmStyle(context, color: budgetItemStatusColor(context, progress.spendingStatus)),
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
            style: labelSmStyle(context, color: colors.ink2),
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
      padding: const EdgeInsets.all(AppSpacing.space1),
      decoration: BoxDecoration(color: colors.surface2, borderRadius: BorderRadius.circular(4)),
      child: Column(
        children: [
          Text(label.toUpperCase(), style: labelSmStyle(context, size: 9, color: colors.ink2)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(AppMoneyFormatter.format(sen), style: context.numberStyles.amountSm.copyWith(color: color)),
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
      child: AppCard(
        color: overspent ? colors.tinted(colors.danger, 0.08) : null,
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
                        color: item.isTransfer ? colors.ink2 : colors.ink,
                      ),
                      if (item.isItemized)
                        Text(
                          t.budget.itemItemizedDetail(
                            quantity: item.quantity!,
                            price: AppMoneyFormatter.format(item.unitPrice!),
                          ),
                          style: textTheme.bodySmall?.copyWith(color: colors.ink2),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.space1),
                BudgetBadge(label: budgetItemStatusLabel(progress.status), color: statusColor),
              ],
            ),
            const SizedBox(height: AppSpacing.space1),
            BudgetProgressBar(value: progress.progress),
            const SizedBox(height: AppSpacing.space1),
            Wrap(
              spacing: AppSpacing.space4,
              runSpacing: 2,
              children: [
                _Figure(label: t.budget.plannedLabel, sen: item.plannedAmount, color: colors.ink),
                _Figure(
                  label: t.budget.spentLabel,
                  sen: progress.spent,
                  color: overspent ? colors.danger : colors.ink,
                ),
                _Figure(
                  label: t.budget.remainingLabel,
                  sen: progress.remaining,
                  color: progress.remaining < 0 ? colors.danger : colors.positive,
                ),
              ],
            ),
            if (onRecord case final record?) ...[
              const SizedBox(height: AppSpacing.space1),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: SpotlightTarget(
                  spotlightKey: spotlighted ? SpotlightKey.budgetDetailRecord : null,
                  child: item.isTransfer
                      ? AppChip(
                          label: t.budget.detailRecordTransferAction,
                          onTap: record,
                        )
                      : AppChip(label: t.budget.detailRecordExpenseAction, onTap: record),
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
            style: TextStyle(color: context.appColors.ink2),
          ),
          TextSpan(
            text: AppMoneyFormatter.format(sen),
            style: TextStyle(color: color),
          ),
        ],
      ),
      style: context.numberStyles.amountSm,
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
    return AppCard(
      color: colors.surface2,
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
