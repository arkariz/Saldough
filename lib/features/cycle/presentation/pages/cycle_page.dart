import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/features/cycle/domain/entities/roll_up_source.dart';
import 'package:saldough/features/cycle/presentation/bloc/cycle_bloc.dart';
import 'package:saldough/features/cycle/presentation/bloc/cycle_state.dart';
import 'package:saldough/features/cycle/presentation/widgets/cycle_line_tile.dart';
import 'package:saldough/features/cycle/presentation/widgets/line_edit_sheet.dart';
import 'package:state_management/state_management.dart';

/// Layar siklus bulanan — menampilkan baris pemasukan, baris anggaran,
/// total, dan sisa (FR-CYCLE-001).
class CyclePage extends StatelessWidget {
  /// Membuat [CyclePage]. [cycleId] hanya dipakai untuk judul awal sebelum
  /// state bloc termuat — navigasi antar bulan selanjutnya membaca
  /// `state.cycle.id`.
  const CyclePage({required this.cycleId, super.key});

  /// Identitas siklus awal.
  final String cycleId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: EffectListener<CycleBloc, CycleState>(
        child: BlocBuilder<CycleBloc, CycleState>(
          builder: (context, state) {
            // UX-17: pemuatan PERTAMA (belum ada siklus sama sekali) tampil
            // skeleton penuh; pemuatan ULANG (pindah bulan lewat chevron,
            // data lama masih ada) tidak mengganti body -- lihat indikator
            // halus di PreferredSize app bar bawaan Scaffold di bawah.
            if (state.isLoading && state.cycle.id.isEmpty) {
              return const AppSkeletonPage();
            }
            // UX-16: kegagalan baca TIDAK dirender sebagai siklus kosong --
            // pemilik butuh tahu ini kegagalan (bisa dicoba lagi), bukan
            // "belum ada baris".
            if (state.hasLoadError) {
              final retryId = state.cycle.id.isNotEmpty ? state.cycle.id : cycleId;
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisSize: .min,
                    children: [
                      Text(t.common.genericErrorMessage, textAlign: .center),
                      const SizedBox(height: AppSpacing.md),
                      AppButton(
                        label: t.common.retry,
                        onPressed: () => context.read<CycleBloc>().add(CycleOpened(retryId)),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    _AppBarSliver(state: state),
                    SliverPadding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      sliver: SliverList.list(
                        children: [
                          if (state.cycle.isClosed) _ClosedBanner(),
                          if (state.unreviewedCount > 0)
                            _UnreviewedBanner(count: state.unreviewedCount),
                          _TotalsCard(state: state),
                          const SizedBox(height: AppSpacing.lg),
                          _IncomeSection(state: state),
                          const SizedBox(height: AppSpacing.lg),
                          _BudgetSection(state: state),
                          const SizedBox(height: AppSpacing.lg),
                          _ActionsRow(state: state),
                        ],
                      ),
                    ),
                  ],
                ),
                // UX-17: pemuatan ULANG (mis. pindah bulan lewat chevron) --
                // data lama tetap tampil, hanya indikator halus di puncak
                // layar, bukan mengganti seluruh body dengan spinner.
                if (state.isLoading)
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AppBarSliver extends StatelessWidget {
  const _AppBarSliver({required this.state});

  final CycleState state;

  @override
  Widget build(BuildContext context) {
    final previousId = _shiftMonth(state.cycle.id, -1);
    final nextId = _shiftMonth(state.cycle.id, 1);
    return SliverAppBar(
      title: Row(
        mainAxisAlignment: .center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            // Hanya bisa bergeser ke siklus yang benar-benar sudah ada —
            // menggeser tidak pernah membuat siklus baru (itu tugas tombol
            // "Buat bulan berikutnya"). Perbaikan atas laporan pemilik:
            // sebelumnya chevron ini bisa menggeser ke bulan yang belum
            // pernah dibuat sama sekali.
            onPressed: state.hasCycle(previousId)
                ? () => context.read<CycleBloc>().add(CycleOpened(previousId))
                : null,
          ),
          Text(CycleMonthFormatter.format(state.cycle.id)),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: state.hasCycle(nextId)
                ? () => context.read<CycleBloc>().add(CycleOpened(nextId))
                : null,
          ),
          if (state.cycle.isClosed)
            Icon(Icons.lock, size: 16, color: context.appColors.textMuted),
        ],
      ),
      centerTitle: true,
    );
  }

  static String _shiftMonth(String id, int delta) {
    final parts = id.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]) + delta;
    final normalizedMonth = ((month - 1) % 12 + 12) % 12 + 1;
    final normalizedYear = year + ((month - 1) ~/ 12 - (month <= 0 ? 1 : 0));
    return '$normalizedYear-${normalizedMonth.toString().padLeft(2, '0')}';
  }
}

class _ClosedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        elevation: AppElevation.none,
        child: Row(
          children: [
            // textMuted, bukan overBudget -- siklus tertutup bukan kondisi
            // lewat anggaran, dan ikon kunci yang sama di app bar (:93) sudah
            // memakai textMuted (UX-25).
            Icon(Icons.lock, color: colors.textMuted),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(t.cycle.closedBanner)),
            TextButton(
              onPressed: () =>
                  context.read<CycleBloc>().add(const CycleReopened()),
              child: Text(t.cycle.reopenCycle),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnreviewedBanner extends StatelessWidget {
  const _UnreviewedBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        elevation: AppElevation.none,
        child: Row(
          children: [
            // needsReviewOnLight, bukan needsReview: ikon ini digambar di
            // atas kartu terang, bukan sebagai isian — slot mentahnya cuma
            // 1.43:1 di sana (ADR-0006 bagian "Varian on-light").
            Icon(Icons.flag, color: colors.needsReviewOnLight),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Text(t.cycle.unreviewedBanner(count: count)),
                  Text(
                    t.cycle.unreviewedBannerHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.state});

  final CycleState state;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      borderRadius: AppRadius.comicCut,
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Row(
            mainAxisAlignment: .spaceBetween,
            children: [
              Text(t.cycle.incomeSectionTitle, style: textTheme.bodyMedium),
              AppMoneyText(
                sen: state.totals.totalIncome,
                color: context.appColors.incomeOnLight,
                style: textTheme.titleMedium,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: .spaceBetween,
            children: [
              Text(t.cycle.budgetSectionTitle, style: textTheme.bodyMedium),
              AppMoneyText(
                sen: state.totals.totalBudget,
                // expenseOnLight, bukan pewarnaan otomatis -- total anggaran
                // dan total pemasukan sebelumnya tampil warna sama (hijau
                // income) karena keduanya selalu positif (UX-23).
                color: context.appColors.expenseOnLight,
                style: textTheme.titleMedium,
              ),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: .spaceBetween,
            children: [
              Text(t.cycle.remainderLabel, style: textTheme.titleMedium),
              AppMoneyText(
                sen: state.totals.remainder,
                style: textTheme.headlineSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IncomeSection extends StatelessWidget {
  const _IncomeSection({required this.state});

  final CycleState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CycleBloc>();
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Text(
          t.cycle.incomeSectionTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (state.cycle.incomeLines.isEmpty) Text(t.cycle.emptyIncome),
        for (final line in state.cycle.incomeLines)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: CycleLineTile(
              label: line.label,
              amount: line.amount,
              isTemplate: line.isTemplate,
              needsReview: line.needsReview,
              onTap: () async {
                final result = await LineEditSheet.show(
                  context,
                  title: t.cycle.editIncomeLine,
                  initialLabel: line.label,
                  initialAmount: line.amount,
                  sources: state.incomeSources,
                  initialSourceId: line.sourceId,
                  isIncomeLine: true,
                  onIncomeSourceAdded: () =>
                      bloc.add(const CycleIncomeSourcesRefreshRequested()),
                );
                if (result != null) {
                  bloc.add(
                    IncomeLineSaved(
                      id: line.id,
                      label: result.label,
                      amount: result.amount,
                      sourceId: result.sourceId,
                    ),
                  );
                }
              },
              onDelete: () async {
                final confirmed = await showConfirmDelete(
                  context,
                  title: t.cycle.confirmDeleteIncomeLineTitle(name: line.label),
                  message: t.cycle.confirmDeleteLineMessage,
                );
                if (confirmed) bloc.add(IncomeLineRemoved(line.id));
              },
              onToggleTemplate: () =>
                  bloc.add(IncomeLineTemplateToggled(line.id)),
              onConfirmReview: line.needsReview
                  ? () => bloc.add(IncomeLineReviewed(line.id))
                  : null,
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: t.cycle.addIncomeLine,
          icon: Icons.add,
          onPressed: () async {
            final result = await LineEditSheet.show(
              context,
              title: t.cycle.addIncomeLine,
              sources: state.incomeSources,
              isIncomeLine: true,
              onIncomeSourceAdded: () =>
                  bloc.add(const CycleIncomeSourcesRefreshRequested()),
            );
            if (result != null) {
              bloc.add(
                IncomeLineSaved(
                  label: result.label,
                  amount: result.amount,
                  sourceId: result.sourceId,
                ),
              );
            }
          },
        ),
      ],
    );
  }
}

class _BudgetSection extends StatelessWidget {
  const _BudgetSection({required this.state});

  final CycleState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CycleBloc>();
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Text(
          t.cycle.budgetSectionTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (state.cycle.budgetLines.isEmpty) Text(t.cycle.emptyBudget),
        for (final line in state.cycle.budgetLines)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: CycleLineTile(
              label: line.label,
              amount: line.amount,
              isTemplate: line.isTemplate,
              needsReview: line.needsReview,
              isEditable: line.kind == .manual,
              isExpense: true,
              rollUpSourceUnavailable: line.rollUpSourceUnavailable,
              rollUpSourceIsCard: line.rollUpSource is CardRollUpSource,
              onTap: () async {
                final result = await LineEditSheet.show(
                  context,
                  title: t.cycle.editBudgetLine,
                  initialLabel: line.label,
                  initialAmount: line.amount,
                );
                if (result != null) {
                  bloc.add(
                    BudgetLineSaved(
                      id: line.id,
                      label: result.label,
                      amount: result.amount,
                    ),
                  );
                }
              },
              onDelete: line.kind == .manual
                  ? () async {
                      final confirmed = await showConfirmDelete(
                        context,
                        title: t.cycle.confirmDeleteBudgetLineTitle(name: line.label),
                        message: t.cycle.confirmDeleteLineMessage,
                      );
                      if (confirmed) bloc.add(BudgetLineRemoved(line.id));
                    }
                  : null,
              onToggleTemplate: () =>
                  bloc.add(BudgetLineTemplateToggled(line.id)),
              onConfirmReview: line.needsReview
                  ? () => bloc.add(BudgetLineReviewed(line.id))
                  : null,
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: t.cycle.addBudgetLine,
          icon: Icons.add,
          onPressed: () async {
            final result = await LineEditSheet.show(
              context,
              title: t.cycle.addBudgetLine,
              isBudgetLine: true,
              cards: state.cards,
              usedRollUpSources: [
                for (final line in state.cycle.budgetLines)
                  if (line.kind == .rollUp) line.rollUpSource!,
              ],
            );
            if (result != null) {
              bloc.add(
                BudgetLineSaved(
                  label: result.label,
                  amount: result.amount,
                  rollUpSource: result.rollUpSource,
                ),
              );
            }
          },
        ),
      ],
    );
  }
}

class _ActionsRow extends StatelessWidget {
  const _ActionsRow({required this.state});

  final CycleState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CycleBloc>();
    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: t.cycle.rollOverButton,
            icon: Icons.fast_forward,
            onPressed: () => bloc.add(const CycleRollOverRequested()),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        if (!state.cycle.isClosed)
          Expanded(
            child: AppButton(
              label: t.cycle.closeCycle,
              icon: Icons.lock_outline,
              color: context.appColors.textMuted,
              onPressed: () => bloc.add(const CycleClosed()),
            ),
          ),
        if (state.canDeleteCycle)
          IconButton(
            tooltip: t.cycle.deleteCycle,
            // textMuted, bukan expense -- hapus adalah aksi netral sampai
            // dikonfirmasi (dialognya sendiri yang memikul warna destruktif
            // lewat showConfirmDelete). expense sebelumnya dipakai untuk
            // pengeluaran, aksi destruktif, DAN galat sekaligus (UX-24).
            icon: Icon(Icons.delete_outline, color: context.appColors.textMuted),
            onPressed: () async {
              final confirmed = await showConfirmDelete(
                context,
                message: t.cycle.deleteCycleConfirmMessage,
                confirmLabel: t.cycle.deleteCycle,
              );
              if (confirmed) bloc.add(const CycleDeleteRequested());
            },
          ),
      ],
    );
  }
}
