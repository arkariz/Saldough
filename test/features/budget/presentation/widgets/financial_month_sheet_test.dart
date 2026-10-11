import 'package:di/di.dart' show GetIt, ScopeProvider;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/budget/data/repositories/budget_repository_impl.dart';
import 'package:saldough/features/budget/data/repositories/budget_template_repository_impl.dart';
import 'package:saldough/features/budget/domain/entities/budget.dart';
import 'package:saldough/features/budget/domain/entities/budget_item.dart';
import 'package:saldough/features/budget/domain/entities/budget_period.dart';
import 'package:saldough/features/budget/domain/entities/budget_schedule.dart';
import 'package:saldough/features/budget/domain/entities/budget_template.dart';
import 'package:saldough/features/budget/domain/repositories/budget_repository.dart';
import 'package:saldough/features/budget/domain/repositories/budget_template_repository.dart';
import 'package:saldough/features/budget/presentation/pages/financial_month_page.dart';
import 'package:saldough/features/budget/presentation/widgets/financial_month_sheet.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Lembar Awal bulan keuangan (T-18.6, FINANCIAL_PERIOD F1, F3, contoh A dan
/// B; komponen DayPicker).
void main() {
  final today = DateTime(2026, 10, 10);
  FinancialMonthSchedule single(int day) => FinancialMonthSchedule.single(FinancialMonthStart.day(day));

  BudgetTemplate template(String id, String name, {int day = 25, bool weekly = false, bool active = true}) =>
      BudgetTemplate(
        id: id,
        name: name,
        items: [BudgetItem(id: '$id-i', name: 'Belanja', enteredAmount: 306850000, templateItemId: '$id-i')],
        schedule: BudgetSchedule(
          walletId: 'bca',
          period: weekly ? BudgetPeriod.weekly : BudgetPeriod.monthly,
          anchorDate: DateTime(2026, 6, day),
          isActive: active,
        ),
      );

  Future<({FinancialMonthStart start, Set<String> moved})? Function()> pump(
    WidgetTester tester, {
    required FinancialMonthSchedule schedule,
    List<FinancialMonthBudgetOption> budgets = const [],
  }) async {
    tester.view.physicalSize = const Size(360, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    ({FinancialMonthStart start, Set<String> moved})? saved;
    await tester.pumpWidget(
        MaterialApp(
          theme: PixelTheme.light,
          home: Scaffold(
            body: FinancialMonthSheet(
              schedule: schedule,
              today: today,
              budgets: budgets,
              onSave: (start, moved) async {
                saved = (start: start, moved: moved);
                return true;
              },
            ),
          ),
        ),
    );
    return () => saved;
  }

  AppButton saveButton(WidgetTester tester) =>
      tester.widget<AppButton>(find.byKey(const ValueKey('financial-month-save')));

  test('anggaran yang bisa ikut: patokan sama dengan awal bulan aktif, bulanan, aktif', () {
    final options = movableRecurringBudgets([
      template('bulanan', 'Anggaran Bulanan'),
      template('kartu', 'Kartu kredit', day: 15),
      template('mingguan', 'Jajan mingguan', weekly: true),
      template('mati', 'Lama', active: false),
    ], const FinancialMonthStart.day(25));
    expect(options, [(templateId: 'bulanan', name: 'Anggaran Bulanan')]);
  });

  testWidgets('terpilih tanggal aktif, tanpa pratinjau, Simpan nonaktif', (tester) async {
    await pump(tester, schedule: single(25));
    await tester.pump();
    expect(find.text(t.plan.financialMonthTitle), findsOneWidget);
    expect(find.text(t.plan.financialMonthHint), findsOneWidget);
    expect(find.byKey(const ValueKey('financial-month-preview')), findsNothing);
    expect(saveButton(tester).onPressed, isNull);
    expect(tester.getSemantics(find.byKey(const ValueKey('day-25'))), matchesSemantics(isChecked: true, hasCheckedState: true, isInMutuallyExclusiveGroup: true, isButton: true, label: t.plan.financialMonthDay(day: 25), hasTapAction: true));
  });

  testWidgets('A: 25 → 1 pada 10 Okt: 25 Sep – 31 Okt (37 hari), lalu 1 – 30 Nov', (tester) async {
    final saved = await pump(
      tester,
      schedule: single(25),
      budgets: const [(templateId: 'bulanan', name: 'Anggaran Bulanan')],
    );
    await tester.tap(find.byKey(const ValueKey('day-1')));
    await tester.pump();
    expect(find.text('Mulai tanggal 1'), findsOneWidget);
    expect(find.text('Periode ini jadi 25 Sep – 31 Okt (37 hari), lalu 1 – 30 Nov.'), findsOneWidget);
    expect(find.text('Periode sebelumnya tidak berubah.'), findsOneWidget);
    expect(find.text('Yang dicentang ikut mulai tanggal 1. Yang tidak, tetap mulai tanggal 25.'), findsOneWidget);
    expect(find.text('Berjalan sampai 31 Okt, berikutnya mulai 1 Nov'), findsOneWidget);
    // Satu anggaran: tanpa tautan Pilih semua/Kosongkan.
    expect(find.byKey(const ValueKey('financial-month-bulk')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('financial-month-save')));
    await tester.pumpAndSettle();
    expect(saved()?.start, FinancialMonthStart.first);
    expect(saved()?.moved, {'bulanan'});
  });

  testWidgets('B: 1 → 25 pada 10 Okt: 1 – 24 Okt (24 hari), lalu 25 Okt – 24 Nov', (tester) async {
    await pump(tester, schedule: single(1));
    await tester.tap(find.byKey(const ValueKey('day-25')));
    await tester.pump();
    expect(find.text('Mulai tanggal 25'), findsOneWidget);
    expect(find.text('Periode ini jadi 1 – 24 Okt (24 hari), lalu 25 Okt – 24 Nov.'), findsOneWidget);
    // Tanpa anggaran rutin: bagian anggaran tidak tampil.
    expect(find.text(t.plan.financialMonthBudgetsTitle), findsNothing);
  });

  testWidgets('hari terakhir bulan: 25 → hari terakhir pada 10 Okt', (tester) async {
    final saved = await pump(tester, schedule: single(25));
    await tester.tap(find.byKey(const ValueKey('day-last')));
    await tester.pump();
    expect(find.text('Mulai hari terakhir bulan'), findsOneWidget);
    expect(find.text('Periode ini jadi 25 Sep – 30 Okt (36 hari), lalu 31 Okt – 29 Nov.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('financial-month-save')));
    await tester.pumpAndSettle();
    expect(saved()?.start, FinancialMonthStart.lastDay);
  });

  testWidgets('centang dilepas: "Tetap mulai tanggal 25" dan tidak ikut disimpan; Kosongkan/Pilih semua', (tester) async {
    final saved = await pump(
      tester,
      schedule: single(25),
      budgets: const [(templateId: 'bulanan', name: 'Anggaran Bulanan'), (templateId: 'darurat', name: 'Dana darurat')],
    );
    await tester.tap(find.byKey(const ValueKey('day-1')));
    await tester.pump();
    expect(find.text(t.plan.financialMonthClearAll), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('financial-month-budget-bulanan')));
    await tester.pump();
    expect(find.text('Tetap mulai tanggal 25'), findsOneWidget);
    expect(find.text(t.plan.financialMonthSelectAll), findsOneWidget);
    expect(
      tester.getSemantics(find.byKey(const ValueKey('financial-month-budget-bulanan'))),
      matchesSemantics(hasCheckedState: true, label: 'Anggaran Bulanan', hint: 'Tetap mulai tanggal 25', hasTapAction: true),
    );
    await tester.tap(find.byKey(const ValueKey('financial-month-save')));
    await tester.pumpAndSettle();
    expect(saved()?.start, FinancialMonthStart.first);
    expect(saved()?.moved, {'darurat'});
  });

  testWidgets('Batal tidak mengubah apa pun', (tester) async {
    final saved = await pump(
      tester,
      schedule: single(25),
      budgets: const [(templateId: 'bulanan', name: 'Anggaran Bulanan')],
    );
    await tester.tap(find.byKey(const ValueKey('day-1')));
    await tester.pump();
    await tester.tap(find.text(t.common.cancel));
    await tester.pumpAndSettle();
    expect(saved(), isNull);
  });

  group('rute: menyimpan jadwal, memindah anggaran, menyegarkan layar', () {
    late InMemoryKeyValueStorage storage;
    late BudgetRepositoryImpl budgets;
    late BudgetTemplateRepositoryImpl templates;
    late FinancialMonthPreferenceRepositoryImpl preferences;
    late LedgerChanges ledger;

    setUp(() async {
      storage = InMemoryKeyValueStorage();
      budgets = BudgetRepositoryImpl(storage: storage);
      templates = BudgetTemplateRepositoryImpl(storage: storage);
      preferences = FinancialMonthPreferenceRepositoryImpl(storage: storage);
      ledger = LedgerChanges();
      ActiveFinancialMonth.notifier.value = single(25);
      await templates.saveTemplate(template('bulanan', 'Anggaran Bulanan'));
      await budgets.saveBudget(
        Budget(
          id: 'sep',
          name: 'Anggaran Bulanan',
          walletId: 'bca',
          period: BudgetPeriod.monthly,
          startDate: DateTime(2026, 9, 25),
          templateId: 'bulanan',
          items: const [BudgetItem(id: 'sep-i', name: 'Belanja', enteredAmount: 306850000, templateItemId: 'bulanan-i')],
        ),
      );
    });

    tearDown(() => ActiveFinancialMonth.notifier.value = FinancialMonthSchedule.initial);

    Future<void> open(WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final container = GetIt.asNewInstance()
        ..registerSingleton<BudgetRepository>(budgets)
        ..registerSingleton<BudgetTemplateRepository>(templates)
        ..registerSingleton<FinancialMonthPreferenceRepository>(preferences)
        ..registerSingleton<TransactionRepository>(TransactionRepositoryImpl(storage: storage))
        ..registerSingleton<LedgerChanges>(ledger);
      await tester.pumpWidget(
        ScopeProvider(
          container: container,
          child: MaterialApp(
            theme: PixelTheme.light,
            home: Scaffold(body: FinancialMonthPage(now: () => today)),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('contoh A tersimpan: jadwal, preferensi, anggaran diregangkan, LedgerChanges', (tester) async {
      var notified = 0;
      final subscription = ledger.changes.listen((_) => notified++);
      addTearDown(subscription.cancel);
      await open(tester);
      expect(find.text('Anggaran Bulanan'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('day-1')));
      await tester.pump();
      expect(find.text('Anggaran Bulanan'), findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('financial-month-save')));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();

      final expected = single(25).changedOn(today, FinancialMonthStart.first);
      expect(ActiveFinancialMonth.schedule, expected);
      expect((await tester.runAsync(preferences.load))!.getOrElse((_) => FinancialMonthSchedule.initial), expected);
      final stretched = (await tester.runAsync(budgets.listBudgets))!.getOrElse((_) => const []).single;
      expect(stretched.endDate, DateTime(2026, 11));
      final moved = (await tester.runAsync(templates.listTemplates))!.getOrElse((_) => const []).single;
      expect(moved.schedule!.anchorDate, DateTime(2026, 11));
      expect(notified, 1);
    });

    testWidgets('Batal: jadwal dan anggaran tetap', (tester) async {
      await open(tester);
      await tester.tap(find.byKey(const ValueKey('day-1')));
      await tester.pump();
      await tester.tap(find.text(t.common.cancel));
      await tester.pumpAndSettle();
      expect(ActiveFinancialMonth.schedule, single(25));
      expect((await tester.runAsync(preferences.load))!.getOrElse((_) => FinancialMonthSchedule.initial), FinancialMonthSchedule.initial);
      final budget = (await tester.runAsync(budgets.listBudgets))!.getOrElse((_) => const []).single;
      expect(budget.hasCustomEnd, isFalse);
    });
  });
}
