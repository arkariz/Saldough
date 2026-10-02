import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/core/foundation/effect_handler/app_effect_registry.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/recurring/presentation/bloc/recurring_bloc.dart';
import 'package:saldough/features/recurring/presentation/bloc/recurring_state.dart';
import 'package:saldough/features/recurring/presentation/pages/recurring_detail_page.dart';
import 'package:saldough/features/recurring/presentation/pages/recurring_page.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

void main() {
  late InMemoryKeyValueStorage storage;
  late RecurringRuleRepositoryImpl rules;
  late TransactionRepositoryImpl transactions;
  late RecurringChanges changes;
  late RecurringBloc bloc;
  final today = DateTime(2026, 10, 2, 9);

  T read<T>(Either<Failure, T> result) => result.getOrElse((_) => throw StateError('expected Right'));

  RecurringRule rule(String id, int amount, DateTime anchor, {RecurringFrequency? frequency, bool paused = false}) =>
      RecurringRule(
        id: id,
        kind: RecurringKind.expense,
        amount: amount,
        walletId: 'bca',
        note: id,
        schedule: RecurringSchedule(frequency: frequency ?? RecurringFrequency.monthly, anchorDate: anchor),
        isPaused: paused,
      );

  setUpAll(registerEffectHandlers);

  setUp(() async {
    storage = InMemoryKeyValueStorage();
    rules = RecurringRuleRepositoryImpl(storage: storage);
    transactions = TransactionRepositoryImpl(storage: storage);
    changes = RecurringChanges();
    await WalletRepositoryImpl(storage: storage).saveWallet(
      const Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 0, currentBalance: 0),
    );
  });

  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    bloc = RecurringBloc(
      rules: rules,
      transactions: transactions,
      wallets: WalletRepositoryImpl(storage: storage),
      ledgerChanges: LedgerChanges(),
      recurringChanges: changes,
      recordTransaction: RecordTransaction(
        ledgerChanges: LedgerChanges(),
        transactionRepository: transactions,
        recomputeWalletBalances: RecomputeWalletBalances(
          walletRepository: WalletRepositoryImpl(storage: storage),
          transactionRepository: transactions,
        ),
      ),
      now: () => today,
    )..add(const RecurringStarted());
    addTearDown(bloc.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: PixelTheme.light,
        home: BlocProvider.value(
          value: bloc,
          child: EffectListener<RecurringBloc, RecurringState>(child: Scaffold(body: child)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('kosong: penjelasan satu kalimat dan chip pembuka', (tester) async {
    await pump(tester, const RecurringSegmentView());
    expect(find.text(t.recurring.emptyTitle), findsOneWidget);
    expect(find.text(t.recurring.starters.salary), findsOneWidget);
  });

  testWidgets('kelompok Menunggu, Bulan ini, Nanti, Dijeda; penyaring jenis kosong', (tester) async {
    await rules.saveRule(rule('Netflix', 6500000, DateTime(2026, 9)));
    await rules.saveRule(rule('Kos', 190000000, DateTime(2026, 10)));
    await rules.saveRule(rule('Asuransi', 125000000, DateTime(2026, 3, 12), frequency: RecurringFrequency.yearly));
    await rules.saveRule(rule('Gym', 30000000, DateTime(2026, 9), paused: true));
    await transactions.saveTransaction(
      ExpenseTransaction(
        id: 'kos',
        date: DateTime(2026, 10, 1, 8),
        amount: 190000000,
        note: 'Kos',
        walletId: 'bca',
        recurrence: RecurrenceLink(ruleId: 'Kos', occurrenceDate: DateTime(2026, 10)),
      ),
    );
    await transactions.saveTransaction(
      ExpenseTransaction(
        id: 'netflix-sep',
        date: DateTime(2026, 9),
        amount: 6500000,
        note: 'Netflix',
        walletId: 'bca',
        recurrence: RecurrenceLink(ruleId: 'Netflix', occurrenceDate: DateTime(2026, 9)),
      ),
    );
    await pump(tester, const RecurringSegmentView());

    expect(find.text(t.recurring.groupPending.toUpperCase()), findsOneWidget);
    expect(find.text(t.recurring.groupThisMonth.toUpperCase()), findsOneWidget);
    expect(find.text(t.recurring.groupLater.toUpperCase()), findsOneWidget);
    // Dijeda terlipat jadi satu baris (PLAN_TAB_LAYOUT §4.9).
    expect(find.text('${t.recurring.groupPaused} (1) ›'), findsOneWidget);
    expect(find.text('Gym'), findsNothing);
    expect(find.text('Kos ✓'), findsOneWidget);
    expect(find.text('Netflix ●'), findsOneWidget);
    // Sisa rutin keluar Okt: Netflix 65.000 (Kos sudah keluar, Gym dijeda).
    expect(find.text('Rp65.000'), findsOneWidget);

    await tester.tap(find.text(t.recurring.chipIncome));
    await tester.pumpAndSettle();
    expect(find.text(t.recurring.filteredEmpty), findsOneWidget);
  });

  testWidgets('rincian: Lewati menulis tanggal dilewati; Jeda lewat menu', (tester) async {
    await rules.saveRule(rule('Netflix', 6500000, DateTime(2026, 9)));
    await pump(tester, const RecurringDetailPage(ruleId: 'Netflix'));

    await tester.tap(find.text(t.recurring.skipAction).first);
    await tester.pumpAndSettle();
    expect(read(await rules.listRules()).single.skippedDates, {DateTime(2026, 11)});
    expect(find.text(t.recurring.unskipAction), findsOneWidget);

    await tester.tap(find.byTooltip(t.recurring.moreActions));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.recurring.pauseAction));
    await tester.pumpAndSettle();
    expect(read(await rules.listRules()).single.isPaused, isTrue);
  });

  group('Menunggu dicatat (T-14.6)', () {
    Future<List<Transaction>> october() async => read(await transactions.listTransactionsInMonth(DateTime(2026, 10)));

    testWidgets('Catat satu ketuk: transaksi bertanggal kemunculan, tertaut; Batalkan menghapusnya', (tester) async {
      await rules.saveRule(rule('Netflix', 6500000, DateTime(2026, 10)));
      await pump(tester, const RecurringSegmentView());

      await tester.tap(find.text(t.recurring.recordAction));
      await tester.pumpAndSettle();
      final recorded = (await october()).single;
      expect(recorded.recurrence, RecurrenceLink(ruleId: 'Netflix', occurrenceDate: DateTime(2026, 10)));
      expect(recorded.date, DateTime(2026, 10, 1, 9));
      expect(recorded.amount, 6500000);
      expect(find.text('Netflix ✓'), findsOneWidget);

      await tester.tap(find.text(t.recurring.undoAction));
      await tester.pumpAndSettle();
      expect(await october(), isEmpty);
    });

    testWidgets('transaksi mirip yang belum tertaut: ditanya dulu, Tautkan tidak menambah transaksi (E4)', (
      tester,
    ) async {
      await rules.saveRule(rule('Netflix', 6500000, DateTime(2026, 10)));
      await transactions.saveTransaction(
        ExpenseTransaction(id: 'dari-notif', date: DateTime(2026, 10, 2), amount: 6500000, note: '', walletId: 'bca'),
      );
      await pump(tester, const RecurringSegmentView());

      await tester.tap(find.text(t.recurring.recordAction));
      await tester.pumpAndSettle();
      expect(find.text(t.recurring.similarTitle), findsOneWidget);
      await tester.tap(find.text(t.recurring.linkAction));
      await tester.pumpAndSettle();

      final all = await october();
      expect(all, hasLength(1));
      expect(all.single.id, 'dari-notif');
      expect(all.single.recurrence?.ruleId, 'Netflix');
    });

    testWidgets('Lewati menulis tanggal dilewati; Catat semua hanya rutin bernominal tetap', (tester) async {
      await rules.saveRule(rule('Netflix', 6500000, DateTime(2026, 10)));
      await rules.saveRule(rule('Spotify', 5499000, DateTime(2026, 9, 30)));
      await rules.saveRule(
        RecurringRule(
          id: 'Listrik',
          kind: RecurringKind.expense,
          amount: 20000000,
          amountMode: RecurringAmountMode.estimated,
          walletId: 'bca',
          note: 'Listrik',
          schedule: RecurringSchedule(frequency: RecurringFrequency.monthly, anchorDate: DateTime(2026, 10)),
        ),
      );
      await rules.saveRule(rule('Gym', 30000000, DateTime(2026, 10, 2)));
      await pump(tester, const RecurringSegmentView());

      await tester.tap(find.text(t.recurring.skipAction).last);
      await tester.pumpAndSettle();
      expect(read(await rules.listRules()).firstWhere((r) => r.id == 'Gym').skippedDates, {DateTime(2026, 10, 2)});

      await tester.tap(find.text(t.recurring.recordAllAction));
      await tester.pumpAndSettle();
      final recorded = [
        ...read(await transactions.listTransactionsInMonth(DateTime(2026, 9))),
        ...await october(),
      ];
      expect(recorded.map((t) => t.recurrence?.ruleId).toSet(), {'Netflix', 'Spotify'});
    });
  });
}
