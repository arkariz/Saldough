import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/investment/domain/entities/allocation_percentage.dart';
import 'package:saldough/features/investment/domain/entities/goal_loan.dart';
import 'package:saldough/features/investment/presentation/bloc/investment_bloc.dart';
import 'package:saldough/features/investment/presentation/bloc/investment_state.dart';
import 'package:saldough/features/investment/presentation/widgets/goal_edit_sheet.dart';
import 'package:saldough/features/investment/presentation/widgets/goal_loan_edit_sheet.dart';
import 'package:saldough/shared/goal/goal.dart';
import 'package:state_management/state_management.dart';

/// Layar investasi — FR-INV-001 sampai FR-INV-005.
class InvestmentPage extends StatelessWidget {
  /// Membuat [InvestmentPage].
  const InvestmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t.investment.pageTitle)),
      body: EffectListener<InvestmentBloc, InvestmentState>(
        child: BlocBuilder<InvestmentBloc, InvestmentState>(
          builder: (context, state) {
            if (state.isLoading && state.goals.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            final bloc = context.read<InvestmentBloc>();
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                _TotalPortfolioCard(state: state),
                const SizedBox(height: AppSpacing.lg),
                Text(t.investment.goalsTitle, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                if (state.goals.isEmpty) Text(t.investment.emptyGoals),
                for (final goal in state.goals)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _GoalTile(goal: goal, state: state),
                  ),
                AppButton(
                  label: t.investment.addGoalTitle,
                  icon: Icons.add,
                  onPressed: () async {
                    final result = await GoalEditSheet.show(context);
                    if (result != null) bloc.add(GoalSaved(result));
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(t.investment.allocationPlanTitle, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                _AllocationPlanForm(state: state),
                const SizedBox(height: AppSpacing.lg),
                Text(t.investment.loansTitle, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                if (state.loans.isEmpty) Text(t.investment.emptyLoans),
                for (final loan in state.loans)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _LoanTile(loan: loan, state: state),
                  ),
                AppButton(
                  label: t.investment.addLoanTitle,
                  icon: Icons.add,
                  onPressed: state.goals.length < 2
                      ? null
                      : () async {
                          final result = await GoalLoanEditSheet.show(context, goals: state.goals);
                          if (result != null) bloc.add(GoalLoanSaved(result));
                        },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TotalPortfolioCard extends StatelessWidget {
  const _TotalPortfolioCard({required this.state});

  final InvestmentState state;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Text(t.investment.totalPortfolioTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          AppMoneyText(
            sen: state.totalPortfolio,
            // investmentOnLight, bukan pewarnaan otomatis income/overBudget
            // -- portofolio investasi bukan pemasukan (UX-26). Sisi negatif
            // tetap overBudgetOnLight: saldo pos yang minus (lebih banyak
            // dipinjamkan daripada yang dimiliki) tetap perlu terlihat beda,
            // sama seperti sisa siklus negatif.
            color: state.totalPortfolio < 0
                ? context.appColors.overBudgetOnLight
                : context.appColors.investmentOnLight,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ],
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({required this.goal, required this.state});

  final Goal goal;
  final InvestmentState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<InvestmentBloc>();
    final history = state.allocationHistoryFor(goal.id);
    final incoming = state.loans.where((l) => l.toGoalId == goal.id);
    final outgoing = state.loans.where((l) => l.fromGoalId == goal.id);
    final hasHistory = history.isNotEmpty || incoming.isNotEmpty || outgoing.isNotEmpty;

    return AppCard(
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          InkWell(
            onTap: () async {
              final result = await GoalEditSheet.show(context, initial: goal);
              if (result != null) bloc.add(GoalSaved(result));
            },
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      Text(goal.name, style: Theme.of(context).textTheme.titleMedium),
                      AppMoneyText(
                        sen: state.balanceOf(goal.id),
                        color: state.balanceOf(goal.id) < 0
                            ? context.appColors.overBudgetOnLight
                            : context.appColors.investmentOnLight,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final confirmed = await showConfirmDelete(
                      context,
                      title: t.investment.confirmDeleteGoalTitle(name: goal.name),
                      message: t.investment.confirmDeleteGoalMessage,
                    );
                    if (confirmed) bloc.add(GoalDeleted(goal.id));
                  },
                ),
              ],
            ),
          ),
          if (hasHistory) ...[
            const Divider(height: AppSpacing.md),
            Text(t.investment.historyTitle, style: Theme.of(context).textTheme.titleSmall),
            for (final entry in history)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Row(
                  mainAxisAlignment: .spaceBetween,
                  children: [
                    Text(t.investment.allocationHistoryLabel(cycleId: CycleMonthFormatter.format(entry.$1))),
                    AppMoneyText(sen: entry.$2, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            for (final loan in incoming)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Row(
                  mainAxisAlignment: .spaceBetween,
                  children: [
                    Text(t.investment.loanInLabel(fromName: _goalName(loan.fromGoalId))),
                    AppMoneyText(sen: loan.repaid, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            for (final loan in outgoing)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Row(
                  mainAxisAlignment: .spaceBetween,
                  children: [
                    Text(t.investment.loanOutLabel(toName: _goalName(loan.toGoalId))),
                    AppMoneyText(sen: -loan.principal, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  String _goalName(String goalId) =>
      state.goals.where((g) => g.id == goalId).firstOrNull?.name ?? goalId;
}

class _AllocationPlanForm extends StatefulWidget {
  const _AllocationPlanForm({required this.state});

  final InvestmentState state;

  @override
  State<_AllocationPlanForm> createState() => _AllocationPlanFormState();
}

class _AllocationPlanFormState extends State<_AllocationPlanForm> {
  late final _returnDepositController = TextEditingController(
    text: ((widget.state.cycleSnapshot?.returnDeposit ?? 0) ~/ 100).toString(),
  );
  final Map<String, TextEditingController> _percentageControllers = {};

  TextEditingController _percentageControllerFor(Goal goal) {
    return _percentageControllers.putIfAbsent(goal.id, () {
      final percentage =
          widget.state.cycleSnapshot?.allocations.where((a) => a.goalId == goal.id).firstOrNull?.percentage ?? 0;
      return TextEditingController(text: percentage.toString());
    });
  }

  @override
  void didUpdateWidget(_AllocationPlanForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.cycleSnapshot == widget.state.cycleSnapshot &&
        oldWidget.state.cycleId == widget.state.cycleId) {
      return;
    }
    _returnDepositController.text = ((widget.state.cycleSnapshot?.returnDeposit ?? 0) ~/ 100).toString();
    for (final controller in _percentageControllers.values) {
      controller.dispose();
    }
    _percentageControllers.clear();
  }

  @override
  void dispose() {
    _returnDepositController.dispose();
    for (final controller in _percentageControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  int get _totalPercentage => widget.state.goals.fold(
        0,
        (sum, goal) => sum + (int.tryParse(_percentageControllerFor(goal).text) ?? 0),
      );

  void _submit() {
    final bloc = context.read<InvestmentBloc>();
    final returnDeposit = (int.tryParse(_returnDepositController.text.trim()) ?? 0) * 100;
    final allocations = [
      for (final goal in widget.state.goals)
        AllocationPercentage(
          goalId: goal.id,
          percentage: int.tryParse(_percentageControllerFor(goal).text) ?? 0,
        ),
    ];
    bloc.add(AllocationPlanSaved(returnDeposit: returnDeposit, allocations: allocations));
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.state.cycleSnapshot;
    final bloc = context.read<InvestmentBloc>();
    final isValidTotal = _totalPercentage == 0 || _totalPercentage == 100;

    return AppCard(
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          if (widget.state.cycleIds.isEmpty)
            Text(t.investment.noCyclesAvailable)
          else
            DropdownButtonFormField<String>(
              initialValue: widget.state.cycleIds.contains(widget.state.cycleId) ? widget.state.cycleId : null,
              decoration: InputDecoration(labelText: t.investment.cycleIdFieldHint),
              items: [
                for (final id in widget.state.cycleIds)
                  DropdownMenuItem(value: id, child: Text(CycleMonthFormatter.format(id))),
              ],
              onChanged: (value) {
                if (value != null) bloc.add(InvestmentCycleSelected(value));
              },
            ),
          const SizedBox(height: AppSpacing.sm),
          if (snapshot == null)
            Text(t.investment.cycleNotFound)
          else if (snapshot.isClosed)
            Text(t.investment.cycleClosedMessage)
          else ...[
            Row(
              mainAxisAlignment: .spaceBetween,
              children: [
                Text(t.investment.remainderLabel),
                AppMoneyText(sen: snapshot.remainder, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _returnDepositController,
              keyboardType: .number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: t.investment.returnDepositFieldHint),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final goal in widget.state.goals)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  children: [
                    Expanded(child: Text(goal.name)),
                    SizedBox(
                      width: 72,
                      child: TextField(
                        controller: _percentageControllerFor(goal),
                        keyboardType: .number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(labelText: t.investment.percentageFieldHint),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              t.investment.totalPercentageLabel(total: _totalPercentage),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isValidTotal ? null : context.appColors.overBudget,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(label: t.common.save, onPressed: isValidTotal ? _submit : null),
          ],
        ],
      ),
    );
  }
}

class _LoanTile extends StatelessWidget {
  const _LoanTile({required this.loan, required this.state});

  final GoalLoan loan;
  final InvestmentState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<InvestmentBloc>();
    final fromName = state.goals.where((g) => g.id == loan.fromGoalId).firstOrNull?.name ?? loan.fromGoalId;
    final toName = state.goals.where((g) => g.id == loan.toGoalId).firstOrNull?.name ?? loan.toGoalId;
    return AppCard(
      child: InkWell(
        onTap: () async {
          final result = await GoalLoanEditSheet.show(context, goals: state.goals, initial: loan);
          if (result != null) bloc.add(GoalLoanSaved(result));
        },
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Text(t.investment.loanRouteLabel(fromName: fromName, toName: toName)),
                  Text(
                    t.investment.loanAmountsLabel(
                      principal: AppMoneyFormatter.format(loan.principal),
                      repaid: AppMoneyFormatter.format(loan.repaid),
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final confirmed = await showConfirmDelete(
                  context,
                  title: t.investment.confirmDeleteLoanTitle,
                  message: t.investment.confirmDeleteLoanMessage,
                );
                if (confirmed) bloc.add(GoalLoanDeleted(loan.id));
              },
            ),
          ],
        ),
      ),
    );
  }
}
