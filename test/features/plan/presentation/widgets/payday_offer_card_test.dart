import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/plan/presentation/widgets/payday_offer_card.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/transaction/transaction.dart';

void main() {
  late GetIt container;
  late FinancialMonthPreferenceRepository preferences;
  late TransactionRepository ledger;

  final now = DateTime(2026, 10, 19);

  setUp(() async {
    final storage = InMemoryKeyValueStorage();
    preferences = FinancialMonthPreferenceRepositoryImpl(storage: storage);
    ledger = TransactionRepositoryImpl(storage: storage);
    final categories = CategoryRepositoryImpl(storage: storage);
    await categories.saveCategory(
      const Category(id: 'builtin.salary', kind: CategoryKind.income, name: 'Gaji', builtInKey: 'salary'),
    );
    container = GetIt.asNewInstance()
      ..registerSingleton<FinancialMonthPreferenceRepository>(preferences)
      ..registerSingleton<TransactionRepository>(ledger)
      ..registerSingleton<CategoryRepository>(categories);
    ActiveFinancialMonth.notifier.value = FinancialMonthSchedule.initial;
  });

  tearDown(() => ActiveFinancialMonth.notifier.value = FinancialMonthSchedule.initial);

  Future<void> recordSalary(DateTime date) => ledger.saveTransaction(
    IncomeTransaction(
      id: 'salary-${date.toIso8601String()}',
      date: date,
      amount: 5000000,
      note: '',
      walletId: 'w',
      categoryId: 'builtin.salary',
    ),
  );

  Future<void> pumpCard(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PixelTheme.light,
        home: Scaffold(
          body: PaydayOfferCard(container: container, now: () => now),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('pengguna lama dengan gaji tanggal 25: kartu menawarkan tanggal itu', (tester) async {
    await recordSalary(DateTime(2026, 9, 25));
    await pumpCard(tester);

    expect(find.byKey(const ValueKey('payday-offer-card')), findsOneWidget);
    expect(find.text(t.discovery.payday.title(d: 25)), findsOneWidget);
    expect(find.text(t.discovery.payday.action), findsOneWidget);
  });

  testWidgets('tanpa gaji tercatat: kartu tidak tampil', (tester) async {
    await pumpCard(tester);

    expect(find.byKey(const ValueKey('payday-offer-card')), findsNothing);
  });

  testWidgets('gaji bertanggal 1: kartu tidak tampil', (tester) async {
    await recordSalary(DateTime(2026, 9));
    await pumpCard(tester);

    expect(find.byKey(const ValueKey('payday-offer-card')), findsNothing);
  });

  testWidgets('ditutup: hilang dan tidak muncul lagi di pembukaan berikutnya', (tester) async {
    await recordSalary(DateTime(2026, 9, 25));
    await pumpCard(tester);

    await tester.tap(find.byKey(const ValueKey('payday-offer-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('payday-offer-card')), findsNothing);

    await pumpCard(tester);
    expect(find.byKey(const ValueKey('payday-offer-card')), findsNothing);
    final offer = (await preferences.loadOffer()).getOrElse((_) => throw StateError(''));
    expect(offer.paydayCardAnswered, isTrue);
    // Menutup tidak mengubah jadwal: hanya menyarankan.
    expect((await preferences.load()).getOrElse((_) => throw StateError('')), FinancialMonthSchedule.initial);
  });

  testWidgets('jadwal diubah sendiri: kartu hilang tanpa dimuat ulang', (tester) async {
    await recordSalary(DateTime(2026, 9, 25));
    await pumpCard(tester);
    expect(find.byKey(const ValueKey('payday-offer-card')), findsOneWidget);

    await preferences.saveOffer((changedByUser: true, offeredRuleIds: const {}, paydayCardAnswered: false));
    ActiveFinancialMonth.notifier.value = FinancialMonthSchedule.initial.changedOn(
      now,
      const FinancialMonthStart.day(25),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('payday-offer-card')), findsNothing);
  });
}
