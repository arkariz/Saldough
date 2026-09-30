import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/spotlight/spotlight.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/tutorial/tutorial.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/budget/domain/entities/budget.dart';
import 'package:saldough/features/budget/domain/entities/budget_item_status.dart';
import 'package:saldough/features/budget/domain/entities/budget_status.dart';
import 'package:saldough/features/budget/domain/usecases/calculate_budget_progress.dart';
import 'package:saldough/features/budget/presentation/bloc/budget_bloc.dart';
import 'package:saldough/features/budget/presentation/bloc/budget_state.dart';
import 'package:saldough/features/budget/presentation/budget_actions.dart';
import 'package:saldough/features/budget/presentation/budget_display.dart';
import 'package:saldough/features/budget/presentation/widgets/budget_form_sheet.dart';
import 'package:saldough/features/record/presentation/bloc/record_bloc.dart';
import 'package:saldough/features/record/presentation/open_record_sheet.dart';
import 'package:saldough/features/record/presentation/widgets/record_choice.dart';
import 'package:saldough/features/transaction/presentation/bloc/transaction_bloc.dart';
import 'package:saldough/features/transaction/presentation/pages/transaction_detail_page.dart';
import 'package:saldough/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/transaction/transaction_presentation.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

/// Membuka [BudgetDetailPage] untuk [budget] (T-4.10, FR-BUD-007).
///
/// Rute yang di-push tidak mewarisi `Theme` maupun `BlocProvider`, jadi
/// dipasang ulang di sini: [PixelTheme], `BudgetBloc` yang SAMA (sunting,
/// arsip, hapus), `RecordBloc` (pintasan CATAT), serta `TransactionBloc` dan
/// `WalletBloc` (disegarkan sesudah CATAT, dan membuka rincian transaksi).
Future<void> openBudgetDetail(BuildContext context, Budget budget) {
  final budgetBloc = context.read<BudgetBloc>();
  final recordBloc = context.read<RecordBloc>();
  final transactionBloc = context.read<TransactionBloc>();
  final walletBloc = context.read<WalletBloc>();
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PixelTheme(
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: budgetBloc),
            BlocProvider.value(value: recordBloc),
            BlocProvider.value(value: transactionBloc),
            BlocProvider.value(value: walletBloc),
          ],
          child: BudgetDetailPage(budget: budget),
        ),
      ),
    ),
  );
}

/// Layar rincian satu anggaran (T-4.10, FR-BUD-007, rujukan
/// `pixel_kas_detail_anggaran_rumah_tangga`): nama, dompet, periode, angka
/// anggaran, seluruh pos dengan progres dan statusnya, transaksi tertaut,
/// serta pintasan **Catat Pengeluaran** dan **Catat Transfer**.
///
/// ⚠ Pencatatan dari layar ini HANYA lewat kartu pos (ADR-018): tiap pos
/// punya satu tombol sesuai jenisnya, yang membuka CATAT biasa
/// (`openRecordSheet`) dengan dompet, pos, dan sisa nominal sudah terisi —
/// untuk pos transfer, dompet tujuannya juga. Tidak ada pintasan di tingkat
/// anggaran, karena transaksi tanpa pos tidak terhitung ke anggaran mana pun.
/// Bukan formulir pencatatan tersendiri (aturan 8 CLAUDE.md, FR-REC-002).
///
/// Membaca anggaran dari `BudgetBloc` (bukan [budget] langsung) supaya
/// progres yang berubah sesudah CATAT tampil tanpa menutup layar ini.
class BudgetDetailPage extends StatelessWidget {
  /// Membuat [BudgetDetailPage].
  const BudgetDetailPage({required this.budget, super.key});

  /// Anggaran yang dibuka (cuplikan, cadangan sebelum bloc memancarkan
  /// salinan terbarunya).
  final Budget budget;

  /// Membuka CATAT untuk pos [progress]: jenis formulir mengikuti jenis pos,
  /// dengan dompet anggaran, pos, sisa nominal, dan — untuk pos transfer —
  /// dompet tujuan sudah terisi.
  Future<void> _record(BuildContext context, Budget current, BudgetItemProgress progress) async {
    final item = progress.item;
    // Progres, riwayat, dan saldo dimuat ulang oleh `LedgerChanges` sesudah
    // transaksinya tersimpan (ADR-030 §3.4).
    await openRecordSheet(
      context,
      initialWalletId: current.walletId,
      initialChoice: item.isTransfer ? RecordChoice.transfer : RecordChoice.expense,
      initialBudgetItemId: item.id,
      initialAmountSen: progress.remaining,
      initialToWalletId: item.targetWalletId,
    );
  }

  /// Transaksi tertaut bisa disunting atau dihapus di rinciannya; progres
  /// di sini ikut berubah lewat `LedgerChanges` (FR-BUD-003, ADR-030 §3.4).
  Future<void> _openTransaction(BuildContext context, Transaction transaction) =>
      openTransactionDetail(context, transaction);

  /// Hapus menutup layar ini; simpan dan arsip tidak (anggarannya masih ada
  /// dan layar ini menampilkan versi terbarunya).
  Future<void> _edit(BuildContext context, Budget current) async {
    final navigator = Navigator.of(context);
    final result = await editBudget(context, current);
    if (result is BudgetFormDeleted) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<BudgetBloc, BudgetState>(
          builder: (context, state) {
            final current = state.budgets.firstWhere((b) => b.id == budget.id, orElse: () => budget);
            final progress = state.progress[current.id];
            if (progress == null) return const AppSkeletonPage();
            final wallet = state.walletOf(current.walletId);
            final canRecord = progress.status != BudgetStatus.archived;
            final linked = state.linkedTransactions(current);
            final walletsById = {for (final w in state.wallets) w.id: w};
            // TR-BUDGET-DETAIL (ADR-021 §3.4): pos pertama dan tombol catatnya.
            return TourTrigger(
              tour: TourId.budgetDetail,
              ready: true,
              child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                _TopBar(onEdit: () => _edit(context, current)),
                const SizedBox(height: AppSpacing.md),
                _HeroCard(budget: current, progress: progress, wallet: wallet),
                const SizedBox(height: AppSpacing.lg),
                AppSectionLabel(t.budget.detailItemsHeading, hint: t.budget.itemCount(count: current.items.length)),
                const SizedBox(height: AppSpacing.xs),
                if (current.items.isEmpty)
                  Text(t.budget.detailNoItems, style: TextStyle(color: context.appColors.textMuted))
                else
                  for (final (i, itemProgress) in progress.items.indexed) ...[
                    _ItemCard(
                      spotlighted: i == 0,
                      progress: itemProgress,
                      targetWalletName: state.walletOf(itemProgress.item.targetWalletId ?? '')?.name,
                      onRecord: canRecord ? () => _record(context, current, itemProgress) : null,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                const SizedBox(height: AppSpacing.md),
                AppSectionLabel(t.budget.detailLinkedHeading),
                const SizedBox(height: AppSpacing.xs),
                if (linked.isEmpty)
                  Text(t.budget.detailLinkedEmpty, style: TextStyle(color: context.appColors.textMuted))
                else
                  for (var i = 0; i < linked.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.sm),
                    TransactionRow(
                      transaction: linked[i],
                      walletsById: walletsById,
                      onTap: () => _openTransaction(context, linked[i]),
                    ),
                  ],
                const SizedBox(height: AppSpacing.lg),
                _HowItWorks(walletName: wallet?.name ?? t.budget.unknownWallet),
              ],
              ),
            );
          },
        ),
      ),
    );
  }
}

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
