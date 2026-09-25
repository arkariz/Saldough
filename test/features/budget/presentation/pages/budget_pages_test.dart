import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/core/foundation/effect_handler/app_effect_registry.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/shell/app_shell_page.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/budget/data/adapters/budget_item_catalog_impl.dart';
import 'package:saldough/features/budget/data/repositories/budget_repository_impl.dart';
import 'package:saldough/features/budget/domain/entities/budget.dart';
import 'package:saldough/features/budget/domain/entities/budget_item.dart';
import 'package:saldough/features/budget/domain/entities/budget_item_kind.dart';
import 'package:saldough/features/budget/domain/entities/budget_period.dart';
import 'package:saldough/features/budget/domain/repositories/budget_repository.dart';
import 'package:saldough/features/budget/presentation/pages/budget_detail_page.dart';
import 'package:saldough/features/budget/presentation/widgets/budget_card.dart';
import 'package:saldough/features/record/domain/budget_item_catalog.dart';
import 'package:saldough/features/record/presentation/widgets/expense_form_sheet.dart';
import 'package:saldough/features/record/presentation/widgets/transfer_form_sheet.dart';
import 'package:saldough/features/transaction/presentation/pages/transaction_detail_page.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

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
      ..registerLazySingleton<WalletRepository>(() => walletRepository)
      ..registerLazySingleton<TransactionRepository>(() => transactionRepository)
      ..registerLazySingleton<BudgetRepository>(() => budgetRepository)
      ..registerLazySingleton<BudgetItemCatalog>(() => BudgetItemCatalogImpl(repository: budgetRepository));
  });

  void tallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<void> openBudgetTab(WidgetTester tester) async {
    await tester.pumpWidget(ScopeProvider(container: container, child: const MaterialApp(home: AppShellPage())));
    // Empat ScopeWidget bersarang (Record, Transaction, Wallet, Budget).
    for (var i = 0; i < 4; i++) {
      await tester.pump();
    }
    await tester.tap(find.widgetWithText(NavigationDestination, t.appShell.budgetTabLabel));
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
    expect(find.descendant(of: card, matching: find.text('BCA')), findsOneWidget);
    // Rencana = pos Beras 2 × Rp75.000 = Rp150.000 (ADR-017); terpakai
    // Rp75.000, sisa Rp75.000.
    expect(find.descendant(of: card, matching: find.text('Rp75.000')), findsOneWidget);
    expect(find.descendant(of: card, matching: find.textContaining('Rp75.000 / Rp150.000')), findsOneWidget);
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
    // Dua kali: status tingkat anggaran di kartu utama, dan lencana pos Beras.
    expect(find.text(t.budget.itemStatusPartiallySpent.toUpperCase()), findsNWidgets(2));
    expect(find.textContaining('beras 5kg'), findsOneWidget);

    // Pintasan di kartu pos: pengeluaran, dompet BCA dan pos Beras terpilih.
    await tester.tap(find.widgetWithText(AppQuickChip, t.budget.detailRecordExpenseAction));
    await tester.pumpAndSettle();
    expect(find.byType(ExpenseFormSheet), findsOneWidget);
    expect(find.text('Beras · Rumah tangga'), findsOneWidget);
    // Nominal terisi SISA pos: rencana 2 × Rp75.000 − terpakai Rp75.000.
    final amountField = find.descendant(of: find.byType(ExpenseFormSheet), matching: find.byType(TextField)).first;
    expect(tester.widget<TextField>(amountField).controller!.text, '75.000');
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
    expect(find.widgetWithText(AppQuickChip, t.budget.detailRecordExpenseAction), findsNothing);
    expect(find.textContaining(t.budget.itemTransferTo(wallet: 'Tabungan').toUpperCase()), findsOneWidget);

    await tester.tap(find.widgetWithText(AppQuickChip, t.budget.detailRecordTransferAction));
    await tester.pumpAndSettle();
    expect(find.byType(TransferFormSheet), findsOneWidget);
    // Pos transfer hanya ditawarkan kalau asal BCA DAN tujuan Tabungan — jadi
    // label terpilih ini membuktikan dompet tujuan sudah terisi.
    expect(find.text('Setoran · Rumah tangga'), findsOneWidget);
  });
}
