part of 'budget_detail_page.dart';

// Bagian layar rincian anggaran (dipecah dari `budget_detail_page.dart`, ADR-030 A9).
// Prototipe `RincianAnggaran.dc.html` (ADR-034).

/// Bar atas halaman turunan: kembali, nama anggaran, tombol ubah.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.onEdit});

  final String title;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSize.topbar,
      child: Row(
        children: [
          AppIconButton(
            icon: IconKey.back,
            label: t.budget.detailBackLabel,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          AppIconButton(
            key: const ValueKey('budget-detail-edit'),
            icon: IconKey.edit,
            label: t.budget.detailEditAction,
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}

/// Ringkasan anggaran: sisa (angka utama) dengan badge status, bar kotak
/// dengan penanda waktu, terpakai dari rencana dan hari ke-berapa periode,
/// lalu badge periode, rentang, dan dompet.
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.budget, required this.progress, required this.wallet});

  final Budget budget;
  final BudgetProgress progress;
  final Wallet? wallet;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final active = progress.status == BudgetStatus.active;
    final ratio = progress.progress;
    final (badge, tone) = switch (AppProgressBar.statusFor(ratio)) {
      AppBarStatus.safe => (t.home.budgetSafe, AppTone.positive),
      AppBarStatus.nearlyOut => (t.home.budgetNearlyOut, AppTone.warning),
      AppBarStatus.over => (t.home.budgetOverBy(amount: AppMoneyFormatter.format(-progress.remaining)), AppTone.danger),
    };
    final totalDays = budget.endDate.difference(budget.startDate).inDays;
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day).difference(budget.startDate).inDays + 1;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(t.budget.remainingLabel, style: textTheme.bodyMedium?.copyWith(color: colors.ink2)),
              ),
              Flexible(child: AppBadge(active ? badge : budgetStatusLabel(progress.status), tone: active ? tone : AppTone.neutral)),
            ],
          ),
          HeroAmount(AppMoneyFormatter.format(progress.remaining), color: progress.remaining < 0 ? colors.danger : null),
          const SizedBox(height: AppSpacing.space3),
          AppProgressBar(value: ratio, pace: active ? budget.elapsedRatio(today) : null),
          const SizedBox(height: AppSpacing.space2),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: AppSpacing.space2,
            children: [
              Text(
                t.home.budgetSpentOf(
                  spent: AppMoneyFormatter.format(progress.spent),
                  planned: AppMoneyFormatter.format(progress.plannedAmount),
                ),
                style: textTheme.bodyMedium?.copyWith(color: colors.ink2),
              ),
              if (active && day >= 1 && day <= totalDays)
                Text(
                  t.budget.dayOfPeriod(day: day, total: totalDays),
                  style: textTheme.bodyMedium?.copyWith(color: colors.ink2),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          const Divider(),
          const SizedBox(height: AppSpacing.space3),
          Wrap(
            spacing: AppSpacing.space2,
            runSpacing: AppSpacing.space2,
            children: [
              AppBadge(budgetPeriodLabel(budget.period)),
              AppBadge(budgetRangeLabel(budget)),
              AppBadge(wallet?.name ?? t.budget.unknownWallet, icon: IconKey.wallets),
            ],
          ),
        ],
      ),
    );
  }
}

/// Satu pos di daftar pos (`tk-list--plain`): nama, bar tipis, keterangan
/// jenis/rencana di kiri; sisa dan statusnya di kanan. Diketuk membuka sheet
/// tindakan pos. Pintasan CATAT tetap terlihat di baris (ADR-018: mencatat
/// dari rincian anggaran hanya lewat pos).
class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.progress,
    required this.targetWalletName,
    required this.onRecord,
    required this.onOpen,
    this.spotlighted = false,
  });

  /// True untuk pos pertama: baris dan tombol catatnya jadi target tur.
  final bool spotlighted;

  final BudgetItemProgress progress;

  /// Nama dompet tujuan pos transfer.
  final String? targetWalletName;

  /// Membuka CATAT untuk pos ini, atau `null` (anggaran nonaktif).
  final VoidCallback? onRecord;

  /// Membuka sheet tindakan pos.
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final item = progress.item;
    final overspent = progress.status == BudgetItemStatus.overspent;
    final caption = [
      if (item.isTransfer)
        '${t.budget.itemKindTransfer} · ${t.budget.itemTransferTo(wallet: targetWalletName ?? t.budget.unknownWallet)}',
      if (item.isItemized)
        t.budget.itemItemizedDetail(quantity: item.quantity!, price: AppMoneyFormatter.format(item.unitPrice!))
      else
        t.home.budgetSpentOf(
          spent: AppMoneyFormatter.format(progress.spent),
          planned: AppMoneyFormatter.format(item.plannedAmount),
        ),
    ].join(' · ');
    return SpotlightTarget(
      spotlightKey: spotlighted ? SpotlightKey.budgetDetailItem : null,
      child: Semantics(
        button: true,
        label: item.name,
        child: InkWell(
          onTap: onOpen,
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed) ? colors.surface2 : Colors.transparent,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4, vertical: AppSpacing.space3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(item.name, style: textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.space2),
                      AppProgressBar(value: progress.progress, thin: true),
                      const SizedBox(height: AppSpacing.space2),
                      Text(caption, style: textTheme.bodySmall?.copyWith(color: colors.ink2)),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AppMoneyText(progress.remaining, kind: MoneyKind.remaining),
                    Text(
                      budgetItemStatusLabel(progress.status),
                      style: textTheme.bodySmall?.copyWith(color: overspent ? colors.danger : colors.ink2),
                    ),
                    if (onRecord case final record?) ...[
                      const SizedBox(height: AppSpacing.space1),
                      SpotlightTarget(
                        spotlightKey: spotlighted ? SpotlightKey.budgetDetailRecord : null,
                        child: AppButton.secondary(
                          small: true,
                          label: item.isTransfer
                              ? t.budget.detailRecordTransferAction
                              : t.budget.detailRecordExpenseAction,
                          onPressed: record,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tindakan sheet pos.
enum _ItemAction { record, edit }

/// Sheet tindakan pos (prototipe: ketuk pos): catat untuk pos ini dan ubah
/// anggaran (pos diubah di formulir anggaran).
class _ItemActionsSheet extends StatelessWidget {
  const _ItemActionsSheet({required this.progress, required this.canRecord});

  final BudgetItemProgress progress;
  final bool canRecord;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final item = progress.item;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(item.name, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
        Text(
          t.home.budgetSpentOf(
            spent: AppMoneyFormatter.format(progress.spent),
            planned: AppMoneyFormatter.format(item.plannedAmount),
          ),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.ink2),
        ),
        const SizedBox(height: AppSpacing.space3),
        if (canRecord)
          AppListRow(
            compact: true,
            leading: AppIcon(IconKey.add, color: colors.ink2),
            title: item.isTransfer ? t.budget.detailRecordTransferAction : t.budget.detailRecordExpenseAction,
            onTap: () => Navigator.of(context).pop(_ItemAction.record),
          ),
        AppListRow(
          compact: true,
          leading: AppIcon(IconKey.edit, color: colors.ink2),
          title: t.budget.detailEditAction,
          onTap: () => Navigator.of(context).pop(_ItemAction.edit),
        ),
        const SizedBox(height: AppSpacing.space4),
      ],
    );
  }
}
