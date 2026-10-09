import 'package:flutter/material.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
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
import 'package:saldough/features/record/presentation/navigation/record_route_keys.dart';
import 'package:saldough/features/transaction/presentation/navigation/transaction_route_keys.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/transaction/transaction_presentation.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

part 'budget_detail_sections.dart';

/// Layar rincian satu anggaran (T-4.10, FR-BUD-007, rujukan
/// `pixel_kas_detail_anggaran_rumah_tangga`): nama, dompet, periode, angka
/// anggaran, seluruh pos dengan progres dan statusnya, transaksi tertaut,
/// serta pintasan **Catat Pengeluaran** dan **Catat Transfer**.
///
/// ⚠ Pencatatan dari layar ini HANYA lewat kartu pos (ADR-018): tiap pos
/// punya satu tombol sesuai jenisnya, yang membuka CATAT biasa
/// (`RecordRouteKeys.sheet`) dengan dompet, pos, dan sisa nominal sudah terisi —
/// untuk pos transfer, dompet tujuannya juga. Tidak ada pintasan di tingkat
/// anggaran, karena transaksi tanpa pos tidak terhitung ke anggaran mana pun.
/// Bukan formulir pencatatan tersendiri (aturan 8 CLAUDE.md, FR-REC-002).
///
/// Membaca anggaran dari `BudgetBloc` milik rutenya (`BudgetRouteModule`,
/// ADR-030 §3.3) supaya progres yang berubah sesudah CATAT tampil tanpa
/// menutup layar ini.
class BudgetDetailPage extends StatelessWidget {
  /// Membuat [BudgetDetailPage].
  const BudgetDetailPage({required this.budgetId, super.key});

  /// Anggaran yang dibuka.
  final String budgetId;

  /// Membuka CATAT untuk pos [progress]: jenis formulir mengikuti jenis pos,
  /// dengan dompet anggaran, pos, sisa nominal, dan — untuk pos transfer —
  /// dompet tujuan sudah terisi.
  Future<void> _record(BuildContext context, Budget current, BudgetItemProgress progress) async {
    final item = progress.item;
    // Progres, riwayat, dan saldo dimuat ulang oleh `LedgerChanges` sesudah
    // transaksinya tersimpan (ADR-030 §3.4).
    await context.pushRoute(
      RecordRouteKeys.sheet,
      RecordSheetInput(
        initialWalletId: current.walletId,
        initialChoice: item.isTransfer ? RecordChoice.transfer : RecordChoice.expense,
        initialBudgetItemId: item.id,
        initialAmountSen: progress.remaining,
        initialToWalletId: item.targetWalletId,
      ),
    );
  }

  /// Transaksi tertaut bisa disunting atau dihapus di rinciannya; progres
  /// di sini ikut berubah lewat `LedgerChanges` (FR-BUD-003, ADR-030 §3.4).
  Future<void> _openTransaction(BuildContext context, Transaction transaction) =>
      context.pushRoute(TransactionRouteKeys.detail, TransactionDetailInput(transaction));

  /// Hapus menutup layar ini sesudah hasilnya tampil (bloc rute ini ikut
  /// tertutup); simpan dan arsip tidak (anggarannya masih ada dan layar ini
  /// menampilkan versi terbarunya).
  Future<void> _edit(BuildContext context, Budget current) async {
    final navigator = Navigator.of(context);
    final bloc = context.read<BudgetBloc>();
    final result = await editBudget(context, current);
    if (result is! BudgetFormDeleted) return;
    await bloc.stream.firstWhere((s) => s.effect != null);
    navigator.pop();
  }

  /// Sheet tindakan pos (ketuk baris pos).
  Future<void> _openItem(
    BuildContext context,
    Budget current,
    BudgetItemProgress progress, {
    required bool canRecord,
  }) async {
    final action = await showAppSheet<_ItemAction>(
      context,
      showDragHandle: true,
      builder: (_) => _ItemActionsSheet(progress: progress, canRecord: canRecord),
    );
    if (action == null || !context.mounted) return;
    switch (action) {
      case _ItemAction.record:
        await _record(context, current, progress);
      case _ItemAction.edit:
        await _edit(context, current);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<BudgetBloc, BudgetState>(
          builder: (context, state) {
            final current = state.budgets.where((b) => b.id == budgetId).firstOrNull;
            final progress = current == null ? null : state.progress[current.id];
            if (current == null || progress == null) return const AppSkeletonPage();
            final wallet = state.walletOf(current.walletId);
            final canRecord = progress.status != BudgetStatus.archived;
            final linked = state.linkedTransactions(current);
            final walletsById = {for (final w in state.wallets) w.id: w};
            // TR-BUDGET-DETAIL (ADR-021 §3.4): pos pertama dan tombol catatnya.
            return TourTrigger(
              tour: TourId.budgetDetail,
              ready: true,
              child: Column(
                children: [
                  _TopBar(title: current.name, onEdit: () => _edit(context, current)),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.space4,
                        AppSpacing.space2,
                        AppSpacing.space4,
                        AppSpacing.space12,
                      ),
                      children: [
                        _HeroCard(budget: current, progress: progress, wallet: wallet),
                        const SizedBox(height: AppSpacing.space6),
                        AppSectionHeader(
                          t.budget.detailItemsHeading,
                          hint: t.budget.itemCount(count: current.items.length),
                        ),
                        const SizedBox(height: AppSpacing.space2),
                        if (current.items.isEmpty)
                          Text(t.budget.detailNoItems, style: TextStyle(color: context.appColors.ink2))
                        else
                          AppListCard(
                            dividerIndent: AppListCard.plainIndent,
                            children: [
                              for (final (i, itemProgress) in progress.items.indexed)
                                _ItemRow(
                                  spotlighted: i == 0,
                                  progress: itemProgress,
                                  targetWalletName: state.walletOf(itemProgress.item.targetWalletId ?? '')?.name,
                                  onRecord: canRecord ? () => _record(context, current, itemProgress) : null,
                                  onOpen: () => _openItem(context, current, itemProgress, canRecord: canRecord),
                                ),
                            ],
                          ),
                        const SizedBox(height: AppSpacing.space6),
                        AppSectionHeader(t.budget.detailLinkedHeading),
                        const SizedBox(height: AppSpacing.space2),
                        if (linked.isEmpty)
                          Text(t.budget.detailLinkedEmpty, style: TextStyle(color: context.appColors.ink2))
                        else
                          AppListCard(
                            children: [
                              for (final transaction in linked)
                                TransactionRow(
                                  transaction: transaction,
                                  walletsById: walletsById,
                                  onTap: () => _openTransaction(context, transaction),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
