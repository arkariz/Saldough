import 'package:dependencies/dependencies.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/features/budget/data/models/budget_model.dart';
import 'package:saldough/features/budget/data/models/budget_template_model.dart';
import 'package:saldough/features/budget/data/repositories/budget_repository_impl.dart';
import 'package:saldough/features/budget/data/repositories/budget_template_repository_impl.dart';
import 'package:saldough/features/budget/domain/entities/budget.dart';
import 'package:saldough/features/budget/domain/entities/budget_item.dart';
import 'package:saldough/features/budget/domain/entities/budget_period.dart';
import 'package:saldough/features/budget/domain/entities/budget_schedule.dart';
import 'package:saldough/features/budget/domain/entities/budget_template.dart';
import 'package:saldough/features/budget/domain/usecases/align_recurring_budgets.dart';
import 'package:saldough/features/budget/domain/usecases/birth_recurring_budgets.dart';
import 'package:saldough/features/budget/domain/usecases/calculate_budget_progress.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Memindah anggaran rutin ke awal bulan keuangan baru (T-18.5, ADR-038
/// §3.3–3.4, FINANCIAL_PERIOD P-6, P-7, contoh A–C).
void main() {
  late BudgetRepositoryImpl budgets;
  late BudgetTemplateRepositoryImpl templates;
  late TransactionRepositoryImpl transactions;
  late WalletRepositoryImpl wallets;
  late AlignRecurringBudgets align;
  late BirthRecurringBudgets birth;
  var ids = 0;

  setUp(() async {
    final storage = InMemoryKeyValueStorage();
    budgets = BudgetRepositoryImpl(storage: storage);
    templates = BudgetTemplateRepositoryImpl(storage: storage);
    transactions = TransactionRepositoryImpl(storage: storage);
    wallets = WalletRepositoryImpl(storage: storage);
    birth = BirthRecurringBudgets(
      budgets: budgets,
      templates: templates,
      transactions: transactions,
      newId: () => 'id${ids++}',
    );
    align = AlignRecurringBudgets(budgets: budgets, templates: templates, birth: birth);
    await wallets.saveWallet(
      const Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 1000000000, currentBalance: 1000000000),
    );
  });

  T read<T>(Either<Object, T> result) => result.getOrElse((_) => throw StateError('expected Right'));

  /// Anggaran rutin "Bulanan" Rp3.068.500 berpatokan [day], dengan periode
  /// yang mulai [starts] sudah lahir.
  Future<void> seed(String id, int day, List<DateTime> starts) async {
    await templates.saveTemplate(
      BudgetTemplate(
        id: id,
        name: 'Bulanan',
        items: [BudgetItem(id: '$id-belanja', name: 'Belanja', enteredAmount: 306850000, templateItemId: '$id-belanja')],
        schedule: BudgetSchedule(walletId: 'bca', period: BudgetPeriod.monthly, anchorDate: DateTime(2026, 6, day)),
      ),
    );
    for (final start in starts) {
      await budgets.saveBudget(
        Budget(
          id: '$id-${start.month}',
          name: 'Bulanan',
          walletId: 'bca',
          period: BudgetPeriod.monthly,
          startDate: start,
          templateId: id,
          items: [
            BudgetItem(
              id: '$id-${start.month}-belanja',
              name: 'Belanja',
              enteredAmount: 306850000,
              templateItemId: '$id-belanja',
            ),
          ],
        ),
      );
    }
  }

  Future<List<Budget>> budgetsOf(String templateId) async =>
      read(await budgets.listBudgets()).where((b) => b.templateId == templateId).toList()
        ..sort((a, b) => a.startDate.compareTo(b.startDate));

  /// Periode berurutan tanpa celah atau tumpang-tindih.
  void expectContiguous(List<Budget> list) {
    for (var i = 1; i < list.length; i++) {
      expect(list[i].startDate, list[i - 1].endDate, reason: '${list[i - 1].id} → ${list[i].id}');
    }
  }

  /// Mengubah awal bulan [before] ke [start] pada [today] dan memindah
  /// anggaran rutin `tpl`; mengembalikan akhir periode peralihan.
  Future<DateTime> change(FinancialMonthSchedule before, DateTime today, FinancialMonthStart start) async {
    final after = before.changedOn(today, start);
    final transitionEnd = after.periodOf(before.periodOf(today).start).end;
    read(await align(templateIds: {'tpl'}, today: today, transitionEnd: transitionEnd, start: start));
    return transitionEnd;
  }

  test('A: 25 → 1 pada 10 Okt: Bulanan diregangkan sampai 31 Okt, berikutnya lahir 1 Nov', () async {
    await seed('tpl', 25, [DateTime(2026, 8, 25), DateTime(2026, 9, 25)]);
    final before = FinancialMonthSchedule.single(const FinancialMonthStart.day(25));
    expect(await change(before, DateTime(2026, 10, 10), FinancialMonthStart.first), DateTime(2026, 11));

    var list = await budgetsOf('tpl');
    expect(list.map((b) => b.startDate), [DateTime(2026, 8, 25), DateTime(2026, 9, 25)]);
    expect(list.last.endDate, DateTime(2026, 11));
    expect(list.last.plannedAmount, 306850000);
    expect(list.first.endDate, DateTime(2026, 9, 25));
    expect(list.first.hasCustomEnd, isFalse);

    read(await birth(DateTime(2026, 10, 31)));
    expect(await budgetsOf('tpl'), list);
    read(await birth(DateTime(2026, 11, 1, 7)));
    read(await birth(DateTime(2026, 12, 2)));
    list = await budgetsOf('tpl');
    expect(list.map((b) => b.startDate), [
      DateTime(2026, 8, 25),
      DateTime(2026, 9, 25),
      DateTime(2026, 11),
      DateTime(2026, 12),
    ]);
    expectContiguous(list);
    expect(list[2].hasCustomEnd, isFalse);
  });

  test('B: 1 → 25 pada 10 Okt: Bulanan dipendekkan sampai 24 Okt, berikutnya lahir 25 Okt', () async {
    await seed('tpl', 1, [DateTime(2026, 9), DateTime(2026, 10)]);
    final before = FinancialMonthSchedule.single(FinancialMonthStart.first);
    expect(await change(before, DateTime(2026, 10, 10), const FinancialMonthStart.day(25)), DateTime(2026, 10, 25));
    read(await birth(DateTime(2026, 10, 25)));
    final list = await budgetsOf('tpl');
    expect(list.map((b) => (b.startDate, b.endDate)), [
      (DateTime(2026, 9), DateTime(2026, 10)),
      (DateTime(2026, 10), DateTime(2026, 10, 25)),
      (DateTime(2026, 10, 25), DateTime(2026, 11, 25)),
    ]);
    expectContiguous(list);
  });

  test('C: 1 → 25 pada 28 Okt: periode 25 Okt lahir sekarang, tautan 25 – 28 Okt dipindah, saldo tetap', () async {
    await seed('tpl', 1, [DateTime(2026, 10)]);
    // Anggaran berpatokan lain (15) tidak tersentuh (P-6).
    await seed('lain', 15, [DateTime(2026, 10, 15)]);
    final record = RecordTransaction(
      transactionRepository: transactions,
      recomputeWalletBalances: RecomputeWalletBalances(walletRepository: wallets, transactionRepository: transactions),
      ledgerChanges: LedgerChanges(),
    );
    ExpenseTransaction belanja(String id, DateTime date) => ExpenseTransaction(
      id: id,
      date: date,
      amount: 5000000,
      note: id,
      walletId: 'bca',
      budgetItemId: 'tpl-10-belanja',
    );
    for (final t in [belanja('b20', DateTime(2026, 10, 20, 9)), belanja('b27', DateTime(2026, 10, 27, 9))]) {
      read(await record(t));
    }
    final balanceBefore = read(await wallets.listWallets()).single.currentBalance;
    final otherBefore = await budgetsOf('lain');

    await change(
      FinancialMonthSchedule.single(FinancialMonthStart.first),
      DateTime(2026, 10, 28),
      const FinancialMonthStart.day(25),
    );

    final list = await budgetsOf('tpl');
    expect(list.map((b) => (b.startDate, b.endDate)), [
      (DateTime(2026, 10), DateTime(2026, 10, 25)),
      (DateTime(2026, 10, 25), DateTime(2026, 11, 25)),
    ]);
    expectContiguous(list);
    final linked = {
      for (final t in read(await transactions.listTransactionsInMonth(DateTime(2026, 10))))
        t.id: (t as ExpenseTransaction).budgetItemId,
    };
    expect(linked['b20'], 'tpl-10-belanja');
    expect(linked['b27'], list.last.items.single.id);
    final all = read(await transactions.listAllTransactions());
    expect(const CalculateBudgetProgress()(list.first, all, now: DateTime(2026, 10, 28)).spent, 5000000);
    expect(const CalculateBudgetProgress()(list.last, all, now: DateTime(2026, 10, 28)).spent, 5000000);
    expect(await budgetsOf('lain'), otherBefore);
    final lainTemplate = read(await templates.listTemplates()).singleWhere((t) => t.id == 'lain');
    expect(lainTemplate.schedule!.anchorDate, DateTime(2026, 6, 15));

    // Saldo tidak berubah dan sama dengan hitung ulang dari buku besar.
    expect(balanceBefore, 990000000);
    expect(read(await wallets.listWallets()).single.currentBalance, balanceBefore);
    read(await RecomputeWalletBalances(walletRepository: wallets, transactionRepository: transactions)());
    expect(read(await wallets.listWallets()).single.currentBalance, balanceBefore);
  });

  test('tidak dipilih: tidak ada yang berubah', () async {
    await seed('tpl', 25, [DateTime(2026, 9, 25)]);
    final before = await budgetsOf('tpl');
    read(
      await align(
        templateIds: {'lain'},
        today: DateTime(2026, 10, 10),
        transitionEnd: DateTime(2026, 11),
        start: FinancialMonthStart.first,
      ),
    );
    expect(await budgetsOf('tpl'), before);
  });

  test('patokan hari terakhir: 31 Okt, 30 Nov, 31 Des, 31 Jan, 28 Feb tanpa celah', () async {
    await seed('tpl', 25, [DateTime(2026, 9, 25)]);
    final end = await change(
      FinancialMonthSchedule.single(const FinancialMonthStart.day(25)),
      DateTime(2026, 10, 10),
      FinancialMonthStart.lastDay,
    );
    expect(end, DateTime(2026, 10, 31));
    for (final day in [
      DateTime(2026, 10, 31),
      DateTime(2026, 11, 30),
      DateTime(2026, 12, 31),
      DateTime(2027, 1, 31),
      DateTime(2027, 2, 28),
    ]) {
      read(await birth(day));
    }
    final list = await budgetsOf('tpl');
    expect(list.map((b) => b.startDate), [
      DateTime(2026, 9, 25),
      DateTime(2026, 10, 31),
      DateTime(2026, 11, 30),
      DateTime(2026, 12, 31),
      DateTime(2027, 1, 31),
      DateTime(2027, 2, 28),
    ]);
    expectContiguous(list);
    expect(list.last.endDate, DateTime(2027, 3, 31));
    expect(read(await templates.listTemplates()).single.schedule!.onLastDay, isTrue);
  });

  test('simpan dan baca: endDate dan onLastDay bertahan; mengubah awal membuang akhir yang disimpan', () {
    final budget = Budget(
      id: 'b',
      name: 'Bulanan',
      walletId: 'bca',
      period: BudgetPeriod.monthly,
      startDate: DateTime(2026, 9, 25),
      endDate: DateTime(2026, 11),
    );
    final json = BudgetModel.fromEntity(budget).toJson();
    expect(json['endDate'], isNotNull);
    expect(BudgetModel.fromJson(json).toEntity(), budget);
    expect(BudgetModel.fromEntity(budget.copyWith(endDate: () => null)).toJson().containsKey('endDate'), isFalse);
    expect(budget.copyWith(startDate: DateTime(2026, 10)).hasCustomEnd, isFalse);
    expect(budget.copyWith(name: 'Lain').endDate, DateTime(2026, 11));

    final template = BudgetTemplate(
      id: 't',
      name: 'Bulanan',
      schedule: BudgetSchedule.startingAt(
        walletId: 'bca',
        period: BudgetPeriod.monthly,
        startDate: DateTime(2026, 10, 31),
      ),
    );
    expect(template.schedule!.onLastDay, isTrue);
    expect(BudgetTemplateModel.fromJson(BudgetTemplateModel.fromEntity(template).toJson()).toEntity(), template);
    expect(BudgetSchedule.canRepeat(BudgetPeriod.monthly, DateTime(2026, 10, 30)), isFalse);
    expect(BudgetSchedule.canRepeat(BudgetPeriod.monthly, DateTime(2026, 11, 30)), isTrue);
  });
}
