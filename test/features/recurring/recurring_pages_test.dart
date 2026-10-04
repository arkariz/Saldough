import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
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
  var clock = today;

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
    clock = today;
    storage = InMemoryKeyValueStorage();
    rules = RecurringRuleRepositoryImpl(storage: storage);
    transactions = TransactionRepositoryImpl(storage: storage);
    changes = RecurringChanges();
    await WalletRepositoryImpl(storage: storage).saveWallet(
      const Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 0, currentBalance: 0),
    );
  });

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    int monthsBack = 1,
    AutoRecordLogRepository? autoRecordLog,
  }) async {
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
      monthsBack: monthsBack,
      autoRecordLog: autoRecordLog,
      now: () => clock,
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

  testWidgets('tanggal berganti saat aplikasi hidup: kemunculan hari itu jadi menunggu (T-15.17)', (tester) async {
    ActiveDay.sync(today);
    await rules.saveRule(rule('Internet', 35000000, DateTime(2026, 10, 3)));
    await pump(tester, const RecurringSegmentView());
    expect(find.text(t.recurring.groupPending.toUpperCase()), findsNothing);

    clock = DateTime(2026, 10, 3, 10);
    ActiveDay.sync(clock);
    await tester.pumpAndSettle();
    expect(find.text(t.recurring.groupPending.toUpperCase()), findsOneWidget);
  });

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

  group('Menunggu dicatat (T-15.6)', () {
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

    testWidgets('autodebet H+2: label belum terlihat; Belum terjadi menunda 2 hari, Lewati dan Catat tetap (T-17.2)', (
      tester,
    ) async {
      await rules.saveRule(
        rule('Asuransi', 20000000, DateTime(2026, 9, 30)).copyWith(paymentMode: RecurringPaymentMode.autoDebit),
      );
      await pump(tester, const RecurringSegmentView());
      tester.view.physicalSize = const Size(360, 1600);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('recurring-unseen-Asuransi')), findsOneWidget);
      expect(find.text(t.recurring.skipAction), findsOneWidget);
      expect(find.text(t.recurring.recordAction), findsOneWidget);
      expect(find.text(t.recurring.editFirstAction), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text(t.recurring.notYetAction));
      await tester.pumpAndSettle();
      expect(read(await rules.listRules()).single.snoozedUntil, DateTime(2026, 10, 4));
      expect(find.byKey(const ValueKey('recurring-unseen-Asuransi')), findsNothing);
      expect(find.text(t.recurring.editFirstAction), findsOneWidget);
    });

    testWidgets('W6: dua kali dilewati memunculkan kartu Masih memakai; Biarkan menyembunyikannya (T-17.3)', (
      tester,
    ) async {
      await rules.saveRule(
        RecurringRule(
          id: 'Spotify',
          kind: RecurringKind.expense,
          amount: 5499000,
          walletId: 'bca',
          note: 'Spotify',
          schedule: RecurringSchedule(frequency: RecurringFrequency.monthly, anchorDate: DateTime(2026, 9)),
          skippedDates: {DateTime(2026, 9), DateTime(2026, 10)},
        ),
      );
      await pump(tester, const RecurringSegmentView());
      expect(find.byKey(const ValueKey('recurring-idle-Spotify')), findsOneWidget);
      await tester.tap(find.text(t.recurring.idleKeep));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('recurring-idle-Spotify')), findsNothing);
      expect(read(await rules.listRules()).single.idleDismissedAt, DateTime(2026, 10, 2));
    });

    testWidgets(
      'W3 dari notifikasi: nominal naik tidak bisa Catat ganda; Perbarui rutin menautkan dan mengubah nominal (T-17.6)',
      (
        tester,
      ) async {
        await rules.saveRule(rule('Netflix', 6500000, DateTime(2026, 10)));
        await transactions.saveTransaction(
          ExpenseTransaction(id: 'notif', date: DateTime(2026, 10, 2), amount: 7900000, note: '', walletId: 'bca'),
        );
        await pump(tester, const RecurringSegmentView());
        expect(find.byKey(const ValueKey('recurring-price-up-Netflix')), findsOneWidget);
        expect(find.text(t.recurring.recordAction), findsNothing);

        await tester.tap(find.text(t.recurring.priceUpUpdate));
        await tester.pumpAndSettle();
        final october = read(await transactions.listTransactionsInMonth(DateTime(2026, 10)));
        expect(october.single.recurrence?.ruleId, 'Netflix');
        expect(read(await rules.listRules()).single.amount, 7900000);
      },
    );

    testWidgets('Sepertinya rutin: tiga bulan Gym memunculkan saran; Bukan rutin menyembunyikannya (T-17.7)', (
      tester,
    ) async {
      for (final month in [8, 9, 10]) {
        await transactions.saveTransaction(
          ExpenseTransaction(
            id: 'gym-$month',
            date: DateTime(2026, month),
            amount: 30000000,
            note: 'Gym',
            walletId: 'bca',
          ),
        );
      }
      await pump(tester, const RecurringSegmentView(), monthsBack: suggestionMonths);
      expect(find.byKey(const ValueKey('recurring-suggestions')), findsOneWidget);
      await tester.tap(find.text(t.recurring.suggestDismiss));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('recurring-suggestions')), findsNothing);
    });

    testWidgets('analitik: Lewati mengirim occurrence_skipped tanpa nominal (T-17.8)', (tester) async {
      final events = <AnalyticsEvent>[];
      AppAnalytics.debugSink = events.add;
      addTearDown(() => AppAnalytics.debugSink = null);
      await rules.saveRule(rule('Gym', 30000000, DateTime(2026, 10, 2)));
      await pump(tester, const RecurringSegmentView());
      await tester.tap(find.text(t.recurring.skipAction));
      await tester.pumpAndSettle();
      expect(events, contains(RecurringEvents.occurrenceSkipped));
    });

    testWidgets('Tercatat otomatis: daftar 7 hari dengan Batalkan menghapus transaksi dan menandai log (T-17.11)', (
      tester,
    ) async {
      final log = AutoRecordLogRepositoryImpl(storage: storage, clock: () => clock);
      await rules.saveRule(rule('Netflix', 6500000, DateTime(2026, 10)).copyWith(autoRecord: true));
      await transactions.saveTransaction(
        ExpenseTransaction(
          id: 'auto-1',
          date: DateTime(2026, 10, 1, 9),
          amount: 6500000,
          note: 'Netflix',
          walletId: 'bca',
          recurrence: RecurrenceLink(ruleId: 'Netflix', occurrenceDate: DateTime(2026, 10)),
        ),
      );
      await log.add([
        AutoRecordEntry(
          transactionId: 'auto-1',
          ruleId: 'Netflix',
          ruleName: 'Netflix',
          occurrenceDate: DateTime(2026, 10),
          recordedAt: DateTime(2026, 10, 1, 9),
        ),
      ]);
      await pump(tester, const RecurringSegmentView(), autoRecordLog: log);
      final card = find.byKey(const ValueKey('recurring-auto-recorded'));
      expect(card, findsOneWidget);
      await tester.tap(find.descendant(of: card, matching: find.text(t.recurring.undoAction)));
      await tester.pumpAndSettle();
      expect(card, findsNothing);
      expect(read(await transactions.listTransactionsInMonth(DateTime(2026, 10))), isEmpty);
      expect(read(await log.list(clock)).single.undone, isTrue);
    });
  });
}
