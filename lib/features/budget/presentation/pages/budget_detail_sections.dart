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
      height: 56,
      child: Row(
        children: [
          const SizedBox(width: 4),
          DsIconButton(
            icon: Icons.arrow_back,
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
                style: context.ds.typography.headlineMd.copyWith(fontSize: 20),
              ),
            ),
          ),
          DsIconButton(
            key: const ValueKey('budget-detail-edit'),
            icon: Icons.edit_outlined,
            label: t.budget.detailEditAction,
            onPressed: onEdit,
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

/// Judul bagian dengan keterangan kecil di kanan (mis. jumlah pos).
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.hint});

  final String title;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Row(
      children: [
        Expanded(child: DsSectionHeader(title: title)),
        if (hint != null) Text(hint!, style: ds.typography.bodySm.copyWith(color: ds.colors.textMuted)),
      ],
    );
  }
}

/// Ringkasan anggaran: sisa (angka utama) dengan badge status, meter dengan
/// penanda waktu, terpakai dari rencana dan hari ke-berapa periode, lalu
/// badge periode, rentang, dan dompet.
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.budget, required this.progress, required this.wallet});

  final Budget budget;
  final BudgetProgress progress;
  final Wallet? wallet;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final active = progress.status == BudgetStatus.active;
    final ratio = progress.progress;
    final (badge, tone) = switch (AppProgressBar.statusFor(ratio)) {
      AppBarStatus.safe => (t.home.budgetSafe, DsBadgeTone.income),
      AppBarStatus.nearlyOut => (t.home.budgetNearlyOut, DsBadgeTone.warning),
      AppBarStatus.over => (
        t.home.budgetOverBy(amount: AppMoneyFormatter.format(-progress.remaining)),
        DsBadgeTone.danger,
      ),
    };
    final totalDays = budget.endDate.difference(budget.startDate).inDays;
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day).difference(budget.startDate).inDays + 1;
    final statusBadge = DsBadge(
      label: active ? badge : budgetStatusLabel(progress.status),
      tone: active ? tone : DsBadgeTone.neutral,
    );
    return DecoratedBox(
      decoration: ds.elevation.card.decoration().copyWith(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c.actionPrimary.withValues(alpha: 0.10), c.surfaceCard],
          stops: const [0, 0.55],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ExcludeSemantics(
                  child: DsIdleMotion(
                    kind: DsIdleKind.float,
                    child: DsIconTile.asset(
                      asset: progress.remaining < 0 ? ClayIcons.warning : ClayIcons.piggy,
                      tone: progress.remaining < 0 ? DsIconTileTone.warning : DsIconTileTone.neutral,
                      size: DsIconTileSize.sm,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(t.budget.remainingLabel, style: ds.typography.bodyMd.copyWith(color: c.textSecondary)),
                ),
                Flexible(
                  child: progress.remaining < 0 && active ? DsPulse(child: statusBadge) : statusBadge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: DsCountUp(
                value: progress.remaining,
                builder: (context, current) => Text(
                  AppMoneyFormatter.format(current),
                  style: ds.typography.numericalDisplay.copyWith(
                    color: progress.remaining < 0 ? c.error : c.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            DsSegmentMeter(
              value: ratio,
              tone: budgetMeterTone(ratio),
              pace: active ? budget.elapsedRatio(today) : null,
              semanticLabel: '${(ratio * 100).round()}%',
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 8,
              children: [
                Text(
                  t.home.budgetSpentOf(
                    spent: AppMoneyFormatter.format(progress.spent),
                    planned: AppMoneyFormatter.format(progress.plannedAmount),
                  ),
                  style: ds.typography.bodySm.copyWith(color: c.textSecondary),
                ),
                if (active && day >= 1 && day <= totalDays)
                  Text(
                    t.budget.dayOfPeriod(day: day, total: totalDays),
                    style: ds.typography.bodySm.copyWith(color: c.textSecondary),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: c.outlineSubtle),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                DsBadge(label: budgetPeriodLabel(budget.period), tone: DsBadgeTone.neutral),
                DsBadge(label: budgetRangeLabel(budget), tone: DsBadgeTone.neutral),
                DsBadge(label: wallet?.name ?? t.budget.unknownWallet, tone: DsBadgeTone.neutral),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Satu pos di daftar pos: nama, meter tipis, keterangan jenis/rencana di
/// kiri; sisa dan statusnya di kanan. Diketuk membuka sheet tindakan pos.
/// Pintasan CATAT tetap terlihat di baris (ADR-018: mencatat dari rincian
/// anggaran hanya lewat pos).
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
    final ds = context.ds;
    final c = ds.colors;
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
      child: DsPressable(
        semanticLabel: item.name,
        onPressed: onOpen,
        pressedScale: 0.99,
        builder: (context, _) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DsIconTile.asset(
                asset: switch (progress.status) {
                  BudgetItemStatus.completed => ClayIcons.done,
                  BudgetItemStatus.overspent => ClayIcons.warning,
                  _ => item.isTransfer ? ClayIcons.transfer : ClayIcons.expenseArrow,
                },
                tone: overspent ? DsIconTileTone.warning : DsIconTileTone.neutral,
                size: DsIconTileSize.sm,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(item.name, style: ds.typography.titleMd),
                    const SizedBox(height: 8),
                    DsSegmentMeter(
                      value: progress.progress,
                      tone: budgetMeterTone(progress.progress),
                      thin: true,
                      semanticLabel: '${(progress.progress * 100).round()}%',
                    ),
                    const SizedBox(height: 8),
                    Text(caption, style: ds.typography.bodySm.copyWith(color: c.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppMoneyFormatter.format(progress.remaining),
                    style: ds.typography.amountSm.copyWith(color: progress.remaining < 0 ? c.error : c.textPrimary),
                  ),
                  Text(
                    budgetItemStatusLabel(progress.status),
                    style: ds.typography.bodySm.copyWith(color: overspent ? c.error : c.textSecondary),
                  ),
                  if (onRecord case final record?) ...[
                    const SizedBox(height: 4),
                    SpotlightTarget(
                      spotlightKey: spotlighted ? SpotlightKey.budgetDetailRecord : null,
                      child: DsButton.compact(
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
    );
  }
}

/// Tindakan sheet pos.
enum _ItemAction { record, edit }

/// Sheet tindakan pos (ketuk pos): catat untuk pos ini dan ubah anggaran
/// (pos diubah di formulir anggaran).
class _ItemActionsSheet extends StatelessWidget {
  const _ItemActionsSheet({required this.progress, required this.canRecord});

  final BudgetItemProgress progress;
  final bool canRecord;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final item = progress.item;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(item.name, textAlign: TextAlign.center, style: ds.typography.headlineMd.copyWith(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            t.home.budgetSpentOf(
              spent: AppMoneyFormatter.format(progress.spent),
              planned: AppMoneyFormatter.format(item.plannedAmount),
            ),
            textAlign: TextAlign.center,
            style: ds.typography.bodySm.copyWith(color: ds.colors.textSecondary),
          ),
          const SizedBox(height: 12),
          DsListCard(
            children: [
              if (canRecord)
                DsSettingRow(
                  leading: DsIconTile.asset(
                    asset: item.isTransfer ? ClayIcons.transfer : ClayIcons.expenseArrow,
                    size: DsIconTileSize.sm,
                  ),
                  title: item.isTransfer ? t.budget.detailRecordTransferAction : t.budget.detailRecordExpenseAction,
                  onTap: () => Navigator.of(context).pop(_ItemAction.record),
                ),
              DsSettingRow(
                leading: DsIconTile.asset(asset: ClayIcons.note, size: DsIconTileSize.sm),
                title: t.budget.detailEditAction,
                onTap: () => Navigator.of(context).pop(_ItemAction.edit),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
