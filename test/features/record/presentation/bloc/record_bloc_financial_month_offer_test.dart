import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/features/record/presentation/bloc/record_bloc.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

import '../../../../helpers/mocks.dart';

/// Tawaran awal bulan keuangan saat menyimpan rutin gajian (T-18.7,
/// FINANCIAL_PERIOD F2).
void main() {
  late InMemoryKeyValueStorage storage;
  late FinancialMonthPreferenceRepositoryImpl preferences;
  late RecurringRuleRepositoryImpl rules;
  late RecordBloc bloc;
  final today = DateTime(2026, 10, 2, 9);

  T read<T>(Either<Failure, T> result) => result.getOrElse((_) => throw StateError('expected Right'));

  setUp(() async {
    storage = InMemoryKeyValueStorage();
    preferences = FinancialMonthPreferenceRepositoryImpl(storage: storage);
    rules = RecurringRuleRepositoryImpl(storage: storage);
    final transactions = TransactionRepositoryImpl(storage: storage);
    final wallets = WalletRepositoryImpl(storage: storage);
    await wallets.saveWallet(
      const Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 0, currentBalance: 0),
    );
    bloc = RecordBloc(
      walletRepository: wallets,
      transactionRepository: transactions,
      budgetItemCatalog: stubBudgetItemCatalog(),
      createCategory: CreateCategory(repository: CategoryRepositoryImpl(storage: storage)),
      recurringRepository: rules,
      recurringChanges: RecurringChanges(),
      financialMonth: preferences,
      now: () => today,
      recordTransaction: RecordTransaction(
        ledgerChanges: LedgerChanges(),
        transactionRepository: transactions,
        recomputeWalletBalances: RecomputeWalletBalances(walletRepository: wallets, transactionRepository: transactions),
      ),
    );
  });

  tearDown(() async {
    await bloc.close();
    ActiveFinancialMonth.notifier.value = FinancialMonthSchedule.initial;
  });

  Future<UiEffect?> save(RecordEvent event) async {
    final before = bloc.state.saveCount;
    bloc.add(event);
    final state = await bloc.stream.firstWhere((s) => !s.isSaving && s.saveCount > before);
    return state.effect;
  }

  IncomeRecorded gaji(DateTime date) => IncomeRecorded(
    walletId: 'bca',
    amount: 1200000000,
    date: date,
    note: 'Gaji',
    repeat: const RecurringPattern(),
  );

  test('Gaji tiap tanggal 25: ditawarkan sekali, rutin dicatat sudah ditawari', () async {
    final effect = await save(gaji(DateTime(2026, 9, 25, 9)));
    expect(effect, isA<CallbackEffect>());
    final rule = read(await rules.listRules()).single;
    final offer = read(await preferences.loadOffer());
    expect(offer.offeredRuleIds, {rule.id});
    expect(offer.changedByUser, isFalse);
  });

  testWidgets('analitik tawaran: shown dari bloc; accepted dan dismissed dari cara snackbar ditutup (T-18.11)', (
    tester,
  ) async {
    final events = <AnalyticsEvent>[];
    AppAnalytics.debugSink = (event) {
      if (event.name == 'financial_month_offer') events.add(event);
    };
    addTearDown(() => AppAnalytics.debugSink = null);
    final effect = (await tester.runAsync(() => save(gaji(DateTime(2026, 9, 25, 9)))))! as CallbackEffect;
    expect(events, [PeriodEvents.offer('shown')]);
    expect(events.single.name, 'financial_month_offer');
    expect(events.single.parameters, {'action': 'shown'});

    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    Future<void> showAndClose(SnackBarClosedReason reason) async {
      effect.callback(context);
      await tester.pump();
      final messenger = ScaffoldMessenger.of(context)..removeCurrentSnackBar();
      await tester.pump();
      if (reason == SnackBarClosedReason.action) {
        messenger.hideCurrentSnackBar(reason: SnackBarClosedReason.action);
      } else {
        messenger.removeCurrentSnackBar();
      }
      await tester.pumpAndSettle();
    }

    await showAndClose(SnackBarClosedReason.action);
    expect(events.last, PeriodEvents.offer('accepted'));
    await showAndClose(SnackBarClosedReason.remove);
    expect(events.last, PeriodEvents.offer('dismissed'));
    expect(events.length, 3);
  });

  test('sudah pernah mengubah awal bulan sendiri: tidak ditawarkan', () async {
    await preferences.saveOffer((changedByUser: true, offeredRuleIds: const {}));
    final effect = await save(gaji(DateTime(2026, 9, 25, 9)));
    expect(effect, isA<ShowSnackBarEffect>());
    expect(read(await preferences.loadOffer()).offeredRuleIds, isEmpty);
  });

  test('awal bulan bukan bawaan: tidak ditawarkan', () async {
    ActiveFinancialMonth.notifier.value = FinancialMonthSchedule.single(const FinancialMonthStart.day(25));
    expect(await save(gaji(DateTime(2026, 9, 25, 9))), isA<ShowSnackBarEffect>());
  });

  group('financialMonthOfferFor', () {
    RecurringRule rule(
      DateTime anchor, {
      RecurringKind kind = RecurringKind.income,
      RecurringFrequency frequency = RecurringFrequency.monthly,
    }) => RecurringRule(
      id: 'r',
      kind: kind,
      amount: 1200000000,
      walletId: 'bca',
      note: 'Gaji',
      schedule: RecurringSchedule(frequency: frequency, anchorDate: anchor),
    );
    const fresh = (changedByUser: false, offeredRuleIds: <String>{});
    FinancialMonthStart? offerFor(RecurringRule r, {FinancialMonthOffer offer = fresh, FinancialMonthSchedule? schedule}) =>
        financialMonthOfferFor(r, schedule: schedule ?? FinancialMonthSchedule.initial, offer: offer);

    test('pemasukan bulanan tanggal 25 → tanggal 25', () {
      expect(offerFor(rule(DateTime(2026, 9, 25))), const FinancialMonthStart.day(25));
    });

    test('tidak untuk pengeluaran, mingguan, atau tanggal 1', () {
      expect(offerFor(rule(DateTime(2026, 9, 25), kind: RecurringKind.expense)), isNull);
      expect(offerFor(rule(DateTime(2026, 9, 25), frequency: RecurringFrequency.weekly)), isNull);
      expect(offerFor(rule(DateTime(2026, 9))), isNull);
    });

    test('tidak bila pernah diubah sendiri, sudah ditawari, atau jadwal bukan bawaan', () {
      final r = rule(DateTime(2026, 9, 25));
      expect(offerFor(r, offer: (changedByUser: true, offeredRuleIds: const {})), isNull);
      expect(offerFor(r, offer: (changedByUser: false, offeredRuleIds: const {'r'})), isNull);
      expect(
        offerFor(r, schedule: FinancialMonthSchedule.single(const FinancialMonthStart.day(10))),
        isNull,
      );
    });

    test('tanggal 29–31: hari terakhir bulan hanya bila memang hari terakhir', () {
      expect(offerFor(rule(DateTime(2026, 11, 30))), FinancialMonthStart.lastDay);
      expect(offerFor(rule(DateTime(2026, 10, 30))), isNull);
    });
  });
}
