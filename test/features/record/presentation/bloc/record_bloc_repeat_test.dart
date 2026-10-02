import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/features/record/presentation/bloc/record_bloc.dart';
import 'package:saldough/features/record/presentation/widgets/record_repeat_field.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

import '../../../../helpers/mocks.dart';

/// Mode jadwal CATAT (T-14.3, ADR-034 §3.3, J2) di atas penyimpanan
/// sungguhan: rutin dan transaksi ditulis bersama, tanpa ganda.
void main() {
  late InMemoryKeyValueStorage storage;
  late TransactionRepositoryImpl transactions;
  late WalletRepositoryImpl wallets;
  late RecurringRuleRepositoryImpl rules;
  late RecurringChanges recurringChanges;
  late RecordBloc bloc;

  // "Hari ini" 2 Okt 2026, seperti contoh di RECURRING_AND_FORECAST §7.6.
  final today = DateTime(2026, 10, 2, 9);

  T read<T>(Either<Failure, T> result) => result.getOrElse((_) => throw StateError('expected Right'));

  setUp(() async {
    storage = InMemoryKeyValueStorage();
    transactions = TransactionRepositoryImpl(storage: storage);
    wallets = WalletRepositoryImpl(storage: storage);
    rules = RecurringRuleRepositoryImpl(storage: storage);
    recurringChanges = RecurringChanges();
    await wallets.saveWallet(
      const Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 500000000, currentBalance: 500000000),
    );
    bloc = RecordBloc(
      walletRepository: wallets,
      transactionRepository: transactions,
      budgetItemCatalog: stubBudgetItemCatalog(),
      createCategory: CreateCategory(repository: CategoryRepositoryImpl(storage: storage)),
      recurringRepository: rules,
      recurringChanges: recurringChanges,
      now: () => today,
      recordTransaction: RecordTransaction(
        ledgerChanges: LedgerChanges(),
        transactionRepository: transactions,
        recomputeWalletBalances: RecomputeWalletBalances(
          walletRepository: wallets,
          transactionRepository: transactions,
        ),
      ),
    );
  });

  tearDown(() => bloc.close());

  Future<void> settle(int saveCountBefore) =>
      bloc.stream.firstWhere((s) => !s.isSaving && (s.saveCount > saveCountBefore || s.effect != null));

  ExpenseRecorded netflix(DateTime date, {RecurringPattern? repeat = const RecurringPattern()}) => ExpenseRecorded(
    walletId: 'bca',
    amount: 6500000,
    date: date,
    note: 'Netflix',
    categoryId: 'builtin.entertainment',
    repeat: repeat,
  );

  test('tanggal lampau: Catat & Jadwalkan — transaksi menjadi kemunculan pertama rutinnya', () async {
    final signals = <Object?>[];
    recurringChanges.changes.listen(signals.add);
    bloc.add(netflix(DateTime(2026, 10, 1, 20)));
    await settle(0);

    final rule = read(await rules.listRules()).single;
    expect(rule.kind, RecurringKind.expense);
    expect(rule.amount, 6500000);
    expect(rule.categoryId, 'builtin.entertainment');
    expect(rule.schedule.anchorDate, DateTime(2026, 10));
    final recorded = read(await transactions.listTransactionsInMonth(DateTime(2026, 10))).single;
    expect(recorded.recurrence, RecurrenceLink(ruleId: rule.id, occurrenceDate: DateTime(2026, 10)));
    expect(recorded.date, DateTime(2026, 10, 1, 20));
    expect(read(await wallets.listWallets()).single.currentBalance, 500000000 - 6500000);
    expect(bloc.state.saveCount, 1);
    expect(signals, hasLength(1));
  });

  test('tanggal masa depan: Simpan Jadwal — hanya rutin, tidak ada transaksi', () async {
    bloc.add(netflix(DateTime(2026, 11, 1, 9)));
    await settle(0);

    expect(read(await rules.listRules()).single.schedule.anchorDate, DateTime(2026, 11));
    expect(read(await transactions.listAllTransactions()), isEmpty);
    expect(read(await wallets.listWallets()).single.currentBalance, 500000000);
    expect(bloc.state.saveCount, 1);
  });

  test('tanpa Ulangi: perilaku CATAT lama, tanpa rutin', () async {
    bloc.add(netflix(DateTime(2026, 10), repeat: null));
    await settle(0);

    expect(read(await rules.listRules()), isEmpty);
    expect(read(await transactions.listAllTransactions()).single.recurrence, isNull);
  });

  test('Jadikan Rutin menautkan transaksi asal, tidak mencatat ulang', () async {
    final source = ExpenseTransaction(
      id: 'kos-sep',
      date: DateTime(2026, 9, 1, 8),
      amount: 150000000,
      note: 'Kos',
      walletId: 'bca',
      budgetItemId: 'pos-kos',
    );
    await transactions.saveTransaction(source);
    bloc.add(
      RecordMadeRecurring(
        source: source,
        recorded: ExpenseRecorded(
          walletId: 'bca',
          amount: 150000000,
          date: source.date,
          note: 'Kos',
          repeat: const RecurringPattern(paymentMode: RecurringPaymentMode.manual),
        ),
      ),
    );
    await settle(0);

    final rule = read(await rules.listRules()).single;
    expect(rule.schedule.anchorDate, DateTime(2026, 9));
    expect(rule.paymentMode, RecurringPaymentMode.manual);
    final all = read(await transactions.listAllTransactions());
    expect(all, hasLength(1));
    final linked = all.single as ExpenseTransaction;
    expect(linked.id, 'kos-sep');
    expect(linked.budgetItemId, 'pos-kos');
    expect(linked.recurrence?.ruleId, rule.id);
    // Kemunculan Okt menunggu; Sep tercatat oleh transaksi asal.
    final statuses = occurrenceStatusesOf(
      rule,
      from: DateTime(2026, 9),
      until: DateTime(2026, 11),
      today: today,
      transactions: all,
    );
    expect(statuses.map((o) => o.status), [OccurrenceStatus.recorded, OccurrenceStatus.pending]);
  });

  group('repeatSubmitLabel', () {
    test('tanpa Ulangi: label biasa; lampau: Catat & Jadwalkan; masa depan: Simpan Jadwal', () {
      final now = DateTime.now();
      expect(repeatSubmitLabel(repeat: null, date: now, plain: 'Catat'), 'Catat');
      expect(repeatSubmitLabel(repeat: const RecurringPattern(), date: now, plain: 'Catat'), 'Catat & Jadwalkan');
      expect(
        repeatSubmitLabel(repeat: const RecurringPattern(), date: now.add(const Duration(days: 2)), plain: 'Catat'),
        'Simpan Jadwal',
      );
    });
  });
}
