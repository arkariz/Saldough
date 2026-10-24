import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/plan/active_plan.dart';
import 'package:saldough/features/recurring/presentation/host/auto_record_host.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Host catat otomatis (T-17.5): sekali per kemunculan, Batalkan tidak
/// membuatnya tercatat lagi.
void main() {
  // Otomasi R3 hanya untuk Plus (ADR-041 §3.8); uji ini menguji perilakunya.
  setUp(() => ActivePlan.notifier.value = const PlusPlan(source: PlanSource.prelaunch));
  tearDown(ActivePlan.reset);

  testWidgets('dibuka dua kali tetap satu transaksi; yang dibatalkan (log undone) tidak dicatat ulang', (tester) async {
    final storage = InMemoryKeyValueStorage();
    final transactions = TransactionRepositoryImpl(storage: storage);
    final rules = RecurringRuleRepositoryImpl(storage: storage);
    final now = DateTime.now();
    await WalletRepositoryImpl(storage: storage).saveWallet(
      const Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 0, currentBalance: 0),
    );
    await rules.saveRule(
      RecurringRule(
        id: 'kos',
        kind: RecurringKind.expense,
        amount: 190000000,
        walletId: 'bca',
        note: 'Kos',
        schedule: RecurringSchedule(
          frequency: RecurringFrequency.monthly,
          anchorDate: DateTime(now.year, now.month, now.day),
        ),
        autoRecord: true,
      ),
    );
    final c = GetIt.asNewInstance()
      ..registerSingleton<AutoRecordLogRepository>(AutoRecordLogRepositoryImpl(storage: storage))
      ..registerSingleton<RecurringRuleRepository>(rules)
      ..registerSingleton<TransactionRepository>(transactions)
      ..registerSingleton<WalletRepository>(WalletRepositoryImpl(storage: storage))
      ..registerSingleton<LedgerChanges>(LedgerChanges());

    Future<List<Transaction>> thisMonth() async =>
        (await transactions.listTransactionsInMonth(DateTime(now.year, now.month))).getOrElse((_) => const []);

    Future<void> open() async {
      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          home: AutoRecordHost(container: c, child: const Scaffold()),
        ),
      );
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
    }

    await open();
    expect((await thisMonth()).single.recurrence?.ruleId, 'kos');
    expect(find.text(t.recurring.autoRecordedOne(name: 'Kos')), findsOneWidget);

    await open();
    expect(await thisMonth(), hasLength(1));

    await open();
    final recorded = (await thisMonth()).single;
    await tester.runAsync(() async {
      await RecordTransaction(
        ledgerChanges: LedgerChanges(),
        transactionRepository: transactions,
        recomputeWalletBalances: RecomputeWalletBalances(
          walletRepository: WalletRepositoryImpl(storage: storage),
          transactionRepository: transactions,
        ),
      ).delete(recorded);
      await AutoRecordLogRepositoryImpl(storage: storage).markUndone(recorded.id);
    });
    await open();
    expect(await thisMonth(), isEmpty);
  });

  testWidgets('Gratis: tidak mencatat otomatis; saat paket menjadi Plus mencatat tanpa buka ulang (ADR-041 §3.8)', (
    tester,
  ) async {
    ActivePlan.notifier.value = const FreePlan();
    final storage = InMemoryKeyValueStorage();
    final transactions = TransactionRepositoryImpl(storage: storage);
    final rules = RecurringRuleRepositoryImpl(storage: storage);
    final now = DateTime.now();
    await WalletRepositoryImpl(storage: storage).saveWallet(
      const Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 0, currentBalance: 0),
    );
    await rules.saveRule(
      RecurringRule(
        id: 'kos',
        kind: RecurringKind.expense,
        amount: 190000000,
        walletId: 'bca',
        note: 'Kos',
        schedule: RecurringSchedule(
          frequency: RecurringFrequency.monthly,
          anchorDate: DateTime(now.year, now.month, now.day),
        ),
        autoRecord: true,
      ),
    );
    final c = GetIt.asNewInstance()
      ..registerSingleton<AutoRecordLogRepository>(AutoRecordLogRepositoryImpl(storage: storage))
      ..registerSingleton<RecurringRuleRepository>(rules)
      ..registerSingleton<TransactionRepository>(transactions)
      ..registerSingleton<WalletRepository>(WalletRepositoryImpl(storage: storage))
      ..registerSingleton<LedgerChanges>(LedgerChanges());
    Future<List<Transaction>> thisMonth() async =>
        (await transactions.listTransactionsInMonth(DateTime(now.year, now.month))).getOrElse((_) => const []);
    Future<void> settle() async {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
    }

    await tester.pumpWidget(MaterialApp(home: AutoRecordHost(container: c, child: const Scaffold())));
    await settle();
    expect(await thisMonth(), isEmpty, reason: 'Gratis: kemunculan dibiarkan menunggu konfirmasi');
    expect((await rules.listRules()).getOrElse((_) => const []).single.autoRecord, isTrue, reason: 'setelan tidak dihapus');

    ActivePlan.notifier.value = const PlusPlan(source: PlanSource.purchase);
    await settle();
    expect((await thisMonth()).single.recurrence?.ruleId, 'kos');
  });
}
