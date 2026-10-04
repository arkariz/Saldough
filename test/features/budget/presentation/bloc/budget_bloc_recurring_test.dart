import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/budget/data/repositories/budget_repository_impl.dart';
import 'package:saldough/features/budget/data/repositories/budget_template_repository_impl.dart';
import 'package:saldough/features/budget/domain/entities/budget.dart';
import 'package:saldough/features/budget/domain/entities/budget_item.dart';
import 'package:saldough/features/budget/domain/entities/budget_period.dart';
import 'package:saldough/features/budget/domain/usecases/plan_recurring_budget_save.dart';
import 'package:saldough/features/budget/presentation/bloc/budget_bloc.dart';
import 'package:saldough/features/budget/presentation/widgets/budget_form_sheet.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Sakelar Ulangi dan dialog lingkup sampai penyimpanan (ADR-036 §3.1,
/// §3.3; T-16.3, T-16.4).
void main() {
  late InMemoryKeyValueStorage storage;
  late BudgetRepositoryImpl budgets;
  late BudgetTemplateRepositoryImpl templates;
  late BudgetBloc bloc;

  const wallet = Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 0, currentBalance: 0);

  setUp(() async {
    storage = InMemoryKeyValueStorage();
    budgets = BudgetRepositoryImpl(storage: storage);
    templates = BudgetTemplateRepositoryImpl(storage: storage);
    await WalletRepositoryImpl(storage: storage).saveWallet(wallet);
    bloc = BudgetBloc(
      budgetRepository: budgets,
      walletRepository: WalletRepositoryImpl(storage: storage),
      transactionRepository: TransactionRepositoryImpl(storage: storage),
      templateRepository: templates,
      ledgerChanges: LedgerChanges(),
      now: () => DateTime(2026, 10, 5),
    )..add(const BudgetStarted());
    addTearDown(bloc.close);
    await bloc.stream.firstWhere((s) => !s.isLoading);
  });

  Future<Budget> saved() async => (await budgets.listBudgets()).getOrElse((_) => const []).single;

  test('Ulangi nyala: template berjadwal tersimpan dan anggaran bertanda rutin', () async {
    bloc.add(
      BudgetAdded(
        name: 'Bulanan',
        walletId: 'bca',
        period: BudgetPeriod.monthly,
        startDate: DateTime(2026, 10),
        items: const [BudgetItem(id: 'kos', name: 'Kos', enteredAmount: 190000000)],
        repeat: true,
      ),
    );
    await bloc.stream.firstWhere((s) => s.budgets.isNotEmpty);
    final budget = await saved();
    final template = (await templates.listTemplates()).getOrElse((_) => const []).single;
    expect(template.isScheduled, isTrue);
    expect(budget.templateId, template.id);
    expect(budget.items.single.templateItemId, template.items.single.id);
    expect(bloc.state.isRecurring(budget), isTrue);

    // Hanya periode ini: template tetap.
    bloc.add(BudgetEdited(budget.copyWith(name: 'Rumah'), repeat: true));
    await bloc.stream.firstWhere((s) => s.budgets.single.name == 'Rumah');
    expect((await templates.listTemplates()).getOrElse((_) => const []).single.name, 'Bulanan');

    // Periode ini dan berikutnya: template ikut.
    bloc.add(BudgetEdited((await saved()).copyWith(name: 'Rumah 2'), repeat: true, scope: BudgetEditScope.thisAndNext));
    await bloc.stream.firstWhere((s) => s.budgets.single.name == 'Rumah 2');
    expect((await templates.listTemplates()).getOrElse((_) => const []).single.name, 'Rumah 2');
  });

  testWidgets('formulir: kalimat Ulangi di 360dp, dan tanggal 29 tidak bisa diulang', (tester) async {
    tester.view.physicalSize = const Size(360, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final budget = Budget(
      id: 'b',
      name: 'Bulanan',
      walletId: 'bca',
      period: BudgetPeriod.monthly,
      startDate: DateTime(2099, 10, 29),
      items: const [BudgetItem(id: 'a', name: 'A', enteredAmount: 1)],
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: PixelTheme.light,
        home: Scaffold(
          body: BudgetFormSheet(wallets: const [wallet], initial: budget),
        ),
      ),
    );
    expect(find.text(t.budget.repeatLabel), findsOneWidget);
    expect(find.text(t.budget.repeatUnavailable), findsOneWidget);
    expect(tester.widget<Switch>(find.byKey(const ValueKey('budget-repeat-switch'))).onChanged, isNull);
    expect(tester.takeException(), isNull);
  });
}
