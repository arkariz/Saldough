import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/app/shell/app_shell_page.dart';
import 'package:saldough/core/foundation/effect_handler/app_effect_registry.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/budget/data/adapters/budget_item_catalog_impl.dart';
import 'package:saldough/features/budget/data/adapters/budget_overview_source_impl.dart';
import 'package:saldough/features/budget/data/repositories/budget_repository_impl.dart';
import 'package:saldough/features/budget/domain/entities/budget.dart';
import 'package:saldough/features/budget/domain/entities/budget_item.dart';
import 'package:saldough/features/budget/domain/entities/budget_item_kind.dart';
import 'package:saldough/features/budget/domain/entities/budget_period.dart';
import 'package:saldough/features/budget/domain/repositories/budget_repository.dart';
import 'package:saldough/features/budget/presentation/pages/budget_detail_page.dart';
import 'package:saldough/features/budget/presentation/widgets/budget_card.dart';
import 'package:saldough/features/home/domain/budget_overview_source.dart';
import 'package:saldough/features/home/domain/freelance_overview_source.dart';
import 'package:saldough/features/plan/domain/plan_sources.dart';
import 'package:saldough/features/record/presentation/widgets/expense_form_sheet.dart';
import 'package:saldough/features/record/presentation/widgets/transfer_form_sheet.dart';
import 'package:saldough/features/transaction/presentation/pages/transaction_detail_page.dart';
import 'package:saldough/shared/auth/auth.dart';
import 'package:saldough/shared/budget_catalog/budget_catalog.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

import '../../../../helpers/fake_auth_repository.dart';
import '../../../../helpers/mocks.dart';
import '../../../../helpers/plan_sources.dart';
import '../../../../helpers/routes.dart';

/// Uji alur layar Anggaran lewat shell sungguhan dengan penyimpanan di
/// memori: daftar (T-4.5), rincian (T-4.10), dan pintasan CATAT yang membuka
/// formulir pengeluaran dengan dompet dan pos sudah terpilih (FR-REC-002).
void main() {
  late InMemoryKeyValueStorage storage;
  late WalletRepositoryImpl walletRepository;
  late TransactionRepositoryImpl transactionRepository;
  late BudgetRepositoryImpl budgetRepository;
  late GetIt container;

  final now = DateTime.now();
  final budget = Budget(
    id: 'rumah',
    name: 'Rumah tangga',
    walletId: 'bca',
    period: BudgetPeriod.monthly,
    startDate: DateTime(now.year, now.month),
    items: const [BudgetItem(id: 'beras', name: 'Beras', quantity: 2, unitPrice: 7500000)],
  );

  setUpAll(registerEffectHandlers);

  setUp(() {
    storage = InMemoryKeyValueStorage();
    walletRepository = WalletRepositoryImpl(storage: storage);
    transactionRepository = TransactionRepositoryImpl(storage: storage);
    budgetRepository = BudgetRepositoryImpl(storage: storage);
    container = GetIt.asNewInstance()
      ..registerLazySingleton<AuthRepository>(FakeAuthRepository.new)
      ..registerLazySingleton<BudgetOverviewSource>(
        () => BudgetOverviewSourceImpl(
          budgetRepository: budgetRepository,
          transactionRepository: transactionRepository,
        ),
      )
      ..registerLazySingleton<FreelanceOverviewSource>(stubFreelanceOverviewSource)
      ..registerLazySingleton<WalletRepository>(() => walletRepository)
      ..registerLazySingleton<LedgerChanges>(LedgerChanges.new)
      ..registerLazySingleton<RecurringChanges>(RecurringChanges.new)
      ..registerLazySingleton<RecurringRuleRepository>(
        () => RecurringRuleRepositoryImpl(storage: InMemoryKeyValueStorage()),
      )
      ..registerLazySingleton<PlanBudgetSource>(EmptyPlanBudgetSource.new)
      ..registerLazySingleton<PlanFreelanceSource>(EmptyPlanFreelanceSource.new)
      ..registerSingleton<RouteRegistry>(appRouteRegistry())
      ..registerLazySingleton<TransactionRepository>(() => transactionRepository)
      ..registerLazySingleton<BudgetRepository>(() => budgetRepository)
      ..registerLazySingleton<BudgetItemCatalog>(() => BudgetItemCatalogImpl(repository: budgetRepository))
      ..registerLazySingleton<CategoryRepository>(() => CategoryRepositoryImpl(storage: InMemoryKeyValueStorage()));
  });

  void tallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<void> openBudgetTab(WidgetTester tester) async {
    await tester.pumpWidget(ScopeProvider(container: container, child: MaterialApp(theme: PixelTheme.light, home: const AppShellPage())));
    // Empat ScopeWidget bersarang (Record, Transaction, Wallet, Budget).
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }
    await tester.tap(find.descendant(of: find.byType(AppNavBar), matching: find.text(t.appShell.planTabLabel)));
    await tester.pumpAndSettle();
    // Awal sesi membuka Bulan ini (KT-L4).
    await tester.tap(find.text(t.appShell.budgetTabLabel));
    await tester.pumpAndSettle();
  }

  Future<void> seedWalletAndBudget() async {
    await walletRepository.saveWallet(
      const Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 0, currentBalance: 500000000),
    );
    await budgetRepository.saveBudget(budget);
    await transactionRepository.saveTransaction(
      ExpenseTransaction(
        id: 'e1',
        date: DateTime(now.year, now.month, 1, 9),
        amount: 7500000,
        note: 'beras 5kg',
        walletId: 'bca',
        budgetItemId: 'beras',
      ),
    );
  }

  testWidgets('tanpa dompet aktif, layar Anggaran menjelaskan perlunya dompet dan tidak menawarkan tombol buat', (
    tester,
  ) async {
    await openBudgetTab(tester);

    expect(find.text(t.budget.noWalletTitle), findsOneWidget);
    expect(find.widgetWithText(AppButton, t.budget.addAction), findsNothing);
  });

  testWidgets('kartu anggaran menampilkan nama, dompet, terpakai, dan sisa (T-4.5)', (tester) async {
    tallViewport(tester);
    await seedWalletAndBudget();
    await openBudgetTab(tester);

    final card = find.byType(BudgetCard);
    expect(card, findsOneWidget);
    expect(find.descendant(of: card, matching: find.text('Rumah tangga')), findsOneWidget);
    expect(find.descendant(of: card, matching: find.textContaining('BCA · ')), findsOneWidget);
    // Rencana = pos Beras 2 × Rp75.000 = Rp150.000 (ADR-017); terpakai
    // Rp75.000, sisa Rp75.000.
    expect(
      find.descendant(of: card, matching: find.text(t.home.budgetSpentOf(spent: 'Rp75.000', planned: 'Rp150.000'))),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text('${t.budget.remainingLabel} Rp75.000', findRichText: true)),
      findsOneWidget,
    );
  });

  testWidgets('rincian anggaran menampilkan pos dan transaksi tertaut, lalu pintasan pos membuka CATAT terisi dompet, pos, dan sisa nominal (T-4.10)', (
    tester,
  ) async {
    tallViewport(tester);
    await seedWalletAndBudget();
    await openBudgetTab(tester);

    await tester.tap(find.byType(BudgetCard));
    await tester.pumpAndSettle();
    expect(find.byType(BudgetDetailPage), findsOneWidget);
    expect(find.text('Beras'), findsOneWidget);
    // Status pos Beras di barisnya; kartu ringkasan memakai badge Aman.
    expect(find.text(t.budget.itemStatusPartiallySpent), findsOneWidget);
    expect(find.text(t.home.budgetSafe), findsOneWidget);
    expect(find.textContaining('beras 5kg'), findsOneWidget);

    // Pintasan di kartu pos: pengeluaran, dompet BCA dan pos Beras terpilih.
    await tester.tap(find.widgetWithText(AppButton, t.budget.detailRecordExpenseAction));
    await tester.pumpAndSettle();
    expect(find.byType(ExpenseFormSheet), findsOneWidget);
    expect(find.text('Beras · Rumah tangga'), findsOneWidget);
    // Nominal terisi SISA pos: rencana 2 × Rp75.000 − terpakai Rp75.000.
    expect(find.descendant(of: find.byType(ExpenseFormSheet), matching: find.text('Rp75.000', findRichText: true)), findsOneWidget);
  });

  testWidgets('rincian transaksi tertaut menampilkan baris Anggaran beserta jalan ke anggarannya (T-4.11)', (
    tester,
  ) async {
    tallViewport(tester);
    await seedWalletAndBudget();
    await openBudgetTab(tester);
    await tester.tap(find.byType(BudgetCard));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('beras 5kg'));
    await tester.pumpAndSettle();

    expect(find.text(t.transaction.budgetLabel.toUpperCase()), findsOneWidget);
    expect(find.text('Beras · Rumah tangga'), findsOneWidget);
    expect(find.text(t.transaction.openBudgetAction.toUpperCase()), findsOneWidget);

    await tester.tap(find.text(t.transaction.openBudgetAction.toUpperCase()));
    await tester.pumpAndSettle();
    // Layar teratas kini rincian anggaran (rute lain tertutup/offstage).
    expect(find.byType(TransactionDetailPage), findsNothing);
    expect(find.byType(BudgetDetailPage), findsOneWidget);
    expect(find.byType(BudgetDetailPage, skipOffstage: false), findsNWidgets(2));
  });

  testWidgets('pos transfer: satu tombol, membuka transfer dengan dompet tujuan dan pos terisi (ADR-018)', (tester) async {
    tallViewport(tester);
    await walletRepository.saveWallet(
      const Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 0, currentBalance: 500000000),
    );
    await walletRepository.saveWallet(
      const Wallet(id: 'tabungan', name: 'Tabungan', iconKey: 'walletSavings', initialBalance: 0, currentBalance: 0),
    );
    await budgetRepository.saveBudget(
      Budget(
        id: 'rumah',
        name: 'Rumah tangga',
        walletId: 'bca',
        period: BudgetPeriod.monthly,
        startDate: DateTime(now.year, now.month),
        items: const [
          BudgetItem(
            id: 'setoran',
            name: 'Setoran',
            enteredAmount: 50000000,
            kind: BudgetItemKind.transfer,
            targetWalletId: 'tabungan',
          ),
        ],
      ),
    );
    await openBudgetTab(tester);
    await tester.tap(find.byType(BudgetCard));
    await tester.pumpAndSettle();

    // Tidak ada pintasan di tingkat anggaran; pos transfer hanya punya tombol transfer.
    expect(find.widgetWithText(AppButton, t.budget.detailRecordExpenseAction), findsNothing);
    expect(find.widgetWithText(AppButton, t.budget.detailRecordExpenseAction), findsNothing);
    expect(find.textContaining(t.budget.itemTransferTo(wallet: 'Tabungan')), findsOneWidget);

    await tester.tap(find.widgetWithText(AppButton, t.budget.detailRecordTransferAction));
    await tester.pumpAndSettle();
    expect(find.byType(TransferFormSheet), findsOneWidget);
    // Pos transfer hanya ditawarkan kalau asal BCA DAN tujuan Tabungan — jadi
    // label terpilih ini membuktikan dompet tujuan sudah terisi.
    expect(find.text('Setoran · Rumah tangga'), findsOneWidget);
  });

  testWidgets('rincian anggaran (T-14.8): ketuk pos membuka sheet tindakan; catat dari sheet membuka CATAT terisi pos', (
    tester,
  ) async {
    tallViewport(tester);
    await seedWalletAndBudget();
    await openBudgetTab(tester);
    await tester.tap(find.byType(BudgetCard));
    await tester.pumpAndSettle();

    // Tanpa tombol catat tingkat anggaran (ADR-018), tanpa kartu penjelasan.
    expect(find.text(t.budget.detailHowTitle), findsNothing);
    await tester.tap(find.text('Beras'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppListRow, t.budget.detailRecordExpenseAction), findsOneWidget);
    expect(find.widgetWithText(AppListRow, t.budget.detailEditAction), findsOneWidget);

    await tester.tap(find.widgetWithText(AppListRow, t.budget.detailRecordExpenseAction));
    await tester.pumpAndSettle();
    expect(find.byType(ExpenseFormSheet), findsOneWidget);
    expect(find.text('Beras · Rumah tangga'), findsOneWidget);
  });
}
