import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/core/financial_month/financial_period.dart';
import 'package:saldough/features/wallet/presentation/bloc/wealth_history_bloc.dart';
import 'package:saldough/features/wallet/presentation/bloc/wealth_history_state.dart';
import 'package:saldough/shared/savings_goal/savings_goal.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Riwayat kekayaan (B-100, ADR-050 §3.6): titik per periode keuangan, batas
/// Gratis, dan pecahan perubahan.
void main() {
  final now = DateTime(2026, 11, 19, 12);
  late InMemoryKeyValueStorage storage;
  late WalletRepositoryImpl wallets;
  late TransactionRepositoryImpl transactions;

  setUp(() async {
    storage = InMemoryKeyValueStorage();
    wallets = WalletRepositoryImpl(storage: storage);
    transactions = TransactionRepositoryImpl(storage: storage);
    await wallets.saveWallet(
      Wallet(
        id: 'a',
        name: 'A',
        iconKey: 'walletBank',
        initialBalance: 1000000,
        currentBalance: 1000000,
        createdAt: DateTime(2026, 4, 2),
      ),
    );
    // Satu pemasukan di tiap bulan April–November 2026.
    for (var m = 4; m <= 11; m++) {
      await transactions.saveTransaction(
        IncomeTransaction(id: 'i$m', date: DateTime(2026, m, 10), amount: 100000, note: '', walletId: 'a'),
      );
    }
  });

  WealthHistoryBloc build({required bool plus, int free = 6}) => WealthHistoryBloc(
    walletRepository: wallets,
    transactionRepository: transactions,
    goalRepository: SavingsGoalRepositoryImpl(storage: storage),
    schedule: () => FinancialMonthSchedule.initial,
    isPlus: () => plus,
    freePeriods: () => free,
    now: () => now,
  );

  Future<WealthHistoryState> load(WealthHistoryBloc bloc) async {
    bloc.add(const WealthHistoryStarted());
    return bloc.stream.firstWhere((s) => !s.isLoading);
  }

  test('Plus melihat seluruh periode sejak data pertama; titik terakhir terpilih', () async {
    final state = await load(build(plus: true));
    expect(state.points.length, 8);
    expect(state.hasLockedOlder, isFalse);
    expect(state.selected, 7);
    expect(state.points.first.change, isNull);
    // Tiap bulan bertambah 100.000; total akhir = 1.000.000 + 8 × 100.000.
    expect(state.points.last.point.total, 1800000);
    expect(state.points.last.change?.flow, 100000);
    expect(state.points.last.change?.total, 100000);
  });

  test('Gratis hanya dihitung untuk periode terakhir sesuai batas dan menandai yang terkunci', () async {
    final state = await load(build(plus: false));
    expect(state.points.length, 6);
    expect(state.hasLockedOlder, isTrue);
    expect(state.points.first.period.start, DateTime(2026, 6));
  });

  test('Gratis dengan data lebih sedikit dari batas tidak menandai terkunci', () async {
    final state = await load(build(plus: false, free: 12));
    expect(state.points.length, 8);
    expect(state.hasLockedOlder, isFalse);
  });

  test('memilih titik berpindah; indeks di luar rentang dijepit', () async {
    final bloc = build(plus: true);
    await load(bloc);
    bloc.add(const WealthHistoryPointSelected(2));
    expect((await bloc.stream.firstWhere((s) => s.selected == 2)).current?.period.start, DateTime(2026, 6));
    bloc.add(const WealthHistoryPointSelected(99));
    expect((await bloc.stream.firstWhere((s) => s.selected != 2)).selected, 7);
  });
}
