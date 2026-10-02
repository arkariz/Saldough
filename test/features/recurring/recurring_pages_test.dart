import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/recurring/presentation/bloc/recurring_bloc.dart';
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
      now: () => today,
    )..add(const RecurringStarted());
    addTearDown(bloc.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: PixelTheme.light,
        home: BlocProvider.value(value: bloc, child: Scaffold(body: child)),
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

    expect(find.text('${t.recurring.groupPending.toUpperCase()} (1)'), findsOneWidget);
    expect(find.text('${t.recurring.groupThisMonth.toUpperCase()} (1)'), findsOneWidget);
    expect(find.text('${t.recurring.groupLater.toUpperCase()} (1)'), findsOneWidget);
    expect(find.text('${t.recurring.groupPaused.toUpperCase()} (1)'), findsOneWidget);
    expect(find.text('Kos ✓'), findsOneWidget);
    expect(find.text('Netflix ●'), findsOneWidget);
    // Masih akan keluar Okt: Netflix 65.000 (Kos sudah tercatat, Gym dijeda).
    expect(find.text('Rp65.000'), findsOneWidget);

    await tester.tap(find.text(t.recurring.filterIncome(n: 0)));
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
}
