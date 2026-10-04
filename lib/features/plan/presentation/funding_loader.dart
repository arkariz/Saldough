import 'package:di/di.dart';
import 'package:saldough/features/plan/domain/plan_sources.dart';
import 'package:saldough/features/plan/presentation/bloc/plan_month_bloc.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Peringatan siapkan dana untuk notifikasi (ADR-036 §3.6), dari data dan
/// hitungan yang sama dengan segmen Bulan ini: `PlanMonthBloc` sementara di
/// atas kontainer akar [container]. Gagal dibaca → tanpa peringatan.
Future<List<FundingWarning>> loadFundingWarnings(GetIt container) async {
  final bloc = PlanMonthBloc(
    wallets: container<WalletRepository>(),
    transactions: container<TransactionRepository>(),
    rules: container<RecurringRuleRepository>(),
    budgets: container<PlanBudgetSource>(),
    freelance: container<PlanFreelanceSource>(),
    ledgerChanges: LedgerChanges(),
    recurringChanges: RecurringChanges(),
  );
  try {
    bloc.add(const PlanMonthLoaded());
    final state = await bloc.stream.firstWhere((s) => !s.isLoading);
    return state.loadFailed ? const [] : state.fundingWarnings;
  } finally {
    await bloc.close();
  }
}
