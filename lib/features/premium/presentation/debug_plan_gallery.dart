// SEMENTARA -- galeri debug Rencana › Bulan ini. JANGAN DI-COMMIT.
// Hapus berkas ini dan dua baris DEBUG-SEMENTARA di account_page.dart.
// Penyimpanan di memori, hari ini dikunci 2 Okt 2026 (contoh RECURRING_AND_
// FORECAST §7.6): kartu tinjau awal bulan tampil. Rute lain tidak terpasang.
import 'dart:async';

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter/material.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/budget/presentation/widgets/financial_month_sheet.dart';
import 'package:saldough/features/plan/data/month_review_repository_impl.dart';
import 'package:saldough/features/plan/domain/plan_sources.dart';
import 'package:saldough/features/plan/presentation/bloc/plan_month_bloc.dart';
import 'package:saldough/features/plan/presentation/bloc/plan_month_state.dart';
import 'package:saldough/features/plan/presentation/pages/plan_month_page.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

final class _Budgets implements PlanBudgetSource {
  _Budgets(this.budgets);
  final List<PlanBudget> budgets;
  DateTime? _first;

  @override
  Future<Either<Failure, List<PlanBudget>>> budgetsStartingIn(DateTime from, DateTime until) async {
    _first ??= from;
    return right(from == _first ? budgets : const []);
  }

  @override
  Future<Either<Failure, List<PlanBudget>>> scheduledBudgetsStartingIn(DateTime from, DateTime until) async =>
      right(const []);
}

final class _NoFreelance implements PlanFreelanceSource {
  const _NoFreelance();

  @override
  Future<Either<Failure, List<UncertainIncome>>> unpaid() async => right(const []);
}

Future<PlanMonthBloc> _seed({required bool empty}) async {
  final storage = InMemoryKeyValueStorage();
  final rules = RecurringRuleRepositoryImpl(storage: storage);
  final transactions = TransactionRepositoryImpl(storage: storage);
  final wallets = WalletRepositoryImpl(storage: storage);
  RecurringRule rule(String id, int amount, int day, {RecurringKind kind = RecurringKind.expense}) => RecurringRule(
    id: id,
    kind: kind,
    amount: amount,
    amountMode: id == 'Listrik' ? RecurringAmountMode.estimated : RecurringAmountMode.fixed,
    walletId: 'bca',
    toWalletId: kind == RecurringKind.transfer ? 'tabungan' : null,
    note: id,
    schedule: RecurringSchedule(frequency: RecurringFrequency.monthly, anchorDate: DateTime(2026, 9, day)),
  );
  if (!empty) {
    for (final r in [
      rule('Kos', 190000000, 1),
      rule('Netflix', 6500000, 1),
      rule('Listrik', 20000000, 5),
      rule('Cicilan', 291400000, 10),
      rule('Gaji', 1200000000, 25, kind: RecurringKind.income),
      rule('Tabungan', 100000000, 26, kind: RecurringKind.transfer),
      rule('Sabil', 80000000, 28),
    ]) {
      await rules.saveRule(r);
    }
  }
  await wallets.saveWallet(
    const Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 0, currentBalance: 650000000),
  );
  await wallets.saveWallet(
    const Wallet(id: 'tabungan', name: 'Tabungan', iconKey: 'walletBank', initialBalance: 0, currentBalance: 300000000),
  );
  for (final t in <Transaction>[
    ExpenseTransaction(id: 'jul', date: DateTime(2026, 7), amount: 276000000, note: '', walletId: 'bca'),
    ExpenseTransaction(
      id: 'kos',
      date: DateTime(2026, 10, 1, 8),
      amount: 190000000,
      note: 'Kos',
      walletId: 'bca',
      recurrence: RecurrenceLink(ruleId: 'Kos', occurrenceDate: DateTime(2026, 10)),
    ),
    ExpenseTransaction(id: 'jajan', date: DateTime(2026, 10, 2, 8), amount: 5700000, note: '', walletId: 'bca'),
  ]) {
    await transactions.saveTransaction(t);
  }
  final bloc = PlanMonthBloc(
    wallets: wallets,
    transactions: transactions,
    rules: rules,
    budgets: _Budgets([
      PlanBudget(
        walletId: 'bca',
        periodEnd: DateTime(2026, 11),
        lines: const [(key: null, itemId: 'bulanan', planned: 306850000, spent: 36850000)],
      ),
    ]),
    freelance: const _NoFreelance(),
    ledgerChanges: LedgerChanges(),
    recurringChanges: RecurringChanges(),
    reviews: MonthReviewRepositoryImpl(storage: storage),
    now: () => DateTime(2026, 10, 2, 9),
  )..add(const PlanMonthLoaded());
  await bloc.stream.firstWhere((s) => !s.isLoading);
  return bloc;
}

/// Tombol di app bar Akun yang membuka skenario Rencana › Bulan ini.
class DebugPlanGalleryButton extends StatelessWidget {
  const DebugPlanGalleryButton({super.key});

  Future<void> _month(BuildContext context, {bool empty = false}) async {
    final bloc = await _seed(empty: empty);
    if (!context.mounted) return;
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            appBar: AppBar(),
            body: BlocProvider<PlanMonthBloc>.value(
              value: bloc,
              child: EffectListener<PlanMonthBloc, PlanMonthState>(
                child: PlanMonthView(onShowRecurring: () {}, onShowBudget: () {}),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _sheet(BuildContext context, {int? initialDay}) => unawaited(
    showFullScreenSheet<void>(
      context,
      builder: (_) => FinancialMonthSheet(
        schedule: FinancialMonthSchedule.single(FinancialMonthStart.day(1)),
        initial: initialDay == null ? null : FinancialMonthStart.day(initialDay),
        today: DateTime(2026, 10, 10),
        budgets: const [],
        onSave: (start, moved) async => true,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => PopupMenuButton<int>(
    icon: const Icon(Icons.rocket_launch),
    tooltip: 'Bulan ini (debug)',
    onSelected: (i) => switch (i) {
      0 => _month(context),
      1 => _month(context, empty: true),
      2 => _sheet(context),
      _ => _sheet(context, initialDay: 25),
    },
    itemBuilder: (_) => const [
      PopupMenuItem(value: 0, child: Text('Bulan ini: penuh (dengan tinjau awal bulan)')),
      PopupMenuItem(value: 1, child: Text('Bulan ini: kosong')),
      PopupMenuItem(value: 2, child: Text('Lembar Awal bulan keuangan')),
      PopupMenuItem(value: 3, child: Text('Lembar Awal bulan: pilih tgl 25 (pratinjau)')),
    ],
  );
}
