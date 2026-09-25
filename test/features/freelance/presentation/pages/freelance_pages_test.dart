import 'package:dependencies/dependencies.dart';
import 'package:di/di.dart';
import 'package:failures/failures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/core/foundation/effect_handler/app_effect_registry.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/shell/app_shell_page.dart';
import 'package:saldough/features/budget/data/adapters/budget_item_catalog_impl.dart';
import 'package:saldough/features/budget/data/repositories/budget_repository_impl.dart';
import 'package:saldough/features/budget/domain/repositories/budget_repository.dart';
import 'package:saldough/features/freelance/data/repositories/freelance_repository_impl.dart';
import 'package:saldough/features/freelance/domain/entities/deduction_kind.dart';
import 'package:saldough/features/freelance/domain/entities/deduction_rule.dart';
import 'package:saldough/features/freelance/domain/entities/freelance_payment.dart';
import 'package:saldough/features/freelance/domain/entities/freelance_project.dart';
import 'package:saldough/features/freelance/domain/entities/worklog_entry.dart';
import 'package:saldough/features/freelance/domain/repositories/freelance_repository.dart';
import 'package:saldough/features/freelance/presentation/pages/freelance_overview_page.dart';
import 'package:saldough/features/freelance/presentation/pages/freelance_project_page.dart';
import 'package:saldough/features/freelance/presentation/widgets/freelance_cards.dart';
import 'package:saldough/features/freelance/presentation/widgets/project_widgets.dart';
import 'package:saldough/features/record/domain/budget_item_catalog.dart';
import 'package:saldough/features/transaction/presentation/pages/transaction_detail_page.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

T _right<T>(Either<Failure, T> result) => result.getOrElse((_) => throw StateError('expected Right'));

/// Uji layar Freelance lewat shell sungguhan dengan penyimpanan di memori:
/// titik masuk CATAT → Pemasukan → Freelance (FR-FRL-005), pencatatan
/// pembayaran diterima (FR-FRL-004), dan penguncian transaksinya di rincian
/// transaksi (ADR-019).
void main() {
  late WalletRepositoryImpl walletRepository;
  late TransactionRepositoryImpl transactionRepository;
  late FreelanceRepositoryImpl freelanceRepository;
  late GetIt container;

  final now = DateTime.now();
  const project = FreelanceProject(
    id: 'studio',
    name: 'Studio Koding',
    hourlyRate: 7250000,
    deductionRules: [DeductionRule(id: 'pajak', label: 'Pajak', kind: DeductionKind.percentage, value: 25)],
  );
  final entry = WorklogEntry(
    id: 'w1',
    projectId: 'studio',
    date: DateTime(now.year, now.month),
    hours: 37,
    hourlyRate: 7250000,
    paymentId: 'pay',
  );
  final payment = FreelancePayment(
    id: 'pay',
    projectId: 'studio',
    entryIds: const ['w1'],
    expectedDate: DateTime(now.year, now.month, 2),
    deductionRules: project.deductionRules,
  );

  setUpAll(registerEffectHandlers);

  setUp(() async {
    final storage = InMemoryKeyValueStorage();
    walletRepository = WalletRepositoryImpl(storage: storage);
    transactionRepository = TransactionRepositoryImpl(storage: storage);
    freelanceRepository = FreelanceRepositoryImpl(storage: storage);
    final budgetRepository = BudgetRepositoryImpl(storage: storage);
    container = GetIt.asNewInstance()
      ..registerLazySingleton<WalletRepository>(() => walletRepository)
      ..registerLazySingleton<TransactionRepository>(() => transactionRepository)
      ..registerLazySingleton<BudgetRepository>(() => budgetRepository)
      ..registerLazySingleton<BudgetItemCatalog>(() => BudgetItemCatalogImpl(repository: budgetRepository))
      ..registerLazySingleton<FreelanceRepository>(() => freelanceRepository);
    await walletRepository.saveWallet(
      const Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 0, currentBalance: 0),
    );
  });

  void tallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<void> openShell(WidgetTester tester) async {
    await tester.pumpWidget(
      ScopeProvider(
        container: container,
        child: const MaterialApp(home: AppShellPage()),
      ),
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump();
    }
  }

  Future<void> openFreelanceThroughRecord(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(NavigationDestination, t.appShell.recordAction));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.record.pickIncomeAction));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(t.record.freelanceCalloutTitle));
    await tester.tap(find.text(t.record.freelanceCalloutTitle));
    await tester.pumpAndSettle();
  }

  Future<void> seedPendingPayment() async {
    await freelanceRepository.saveProject(project);
    await freelanceRepository.saveEntries([entry]);
    await freelanceRepository.savePayment(payment);
  }

  testWidgets('CATAT → Catat Pemasukan → kartu Freelance membuka Ikhtisar Freelance dengan tab Worklog', (
    tester,
  ) async {
    tallViewport(tester);
    await openShell(tester);
    await openFreelanceThroughRecord(tester);

    expect(find.byType(FreelanceOverviewPage), findsOneWidget);
    expect(find.text(t.freelance.worklogTab(count: 0)), findsOneWidget);
    expect(find.text(t.freelance.paymentsTab(count: 0)), findsOneWidget);
    expect(find.text(t.freelance.projectsEmpty), findsOneWidget);
    expect(find.text(t.freelance.ruleBody), findsOneWidget);
  });

  testWidgets('Catat Diterima menambah saldo sebesar gaji bersih tepat satu kali (FR-FRL-004)', (tester) async {
    tallViewport(tester);
    await seedPendingPayment();
    await openShell(tester);
    await openFreelanceThroughRecord(tester);

    // Tab Worklog berisi kartu proyek; entrinya ada di rincian proyek.
    expect(find.byType(ProjectCard), findsOneWidget);
    await tester.tap(find.byType(ProjectCard));
    await tester.pumpAndSettle();
    expect(find.byType(FreelanceProjectPage), findsOneWidget);
    // Tak ada entri belum ditagih, jadi penyaring bawaan jatuh ke "Semua";
    // entri yang sudah masuk pembayaran tampil tertunda dan terkunci.
    expect(
      find.descendant(of: find.byType(WorklogEntryCard), matching: find.text(t.freelance.statusPending.toUpperCase())),
      findsOneWidget,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text(t.freelance.paymentsTab(count: 1)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.freelance.receiveAction));
    await tester.pumpAndSettle();
    // Lembar pencatatan: gaji bersih Rp2.615.438, dompet tunggal terpilih.
    expect(find.text(t.freelance.receiveTitle), findsOneWidget);
    await tester.ensureVisible(find.text(t.freelance.receiveAction).last);
    await tester.tap(find.text(t.freelance.receiveAction).last);
    await tester.pumpAndSettle();

    final wallet = _right(await walletRepository.listWallets()).single;
    expect(wallet.currentBalance, 261543750);
    final income = _right(await transactionRepository.listAllTransactions()).single as IncomeTransaction;
    expect(income.amount, 261543750);
    expect(income.freelancePaymentId, 'pay');
    expect(find.text(t.freelance.receiptCancelAction), findsOneWidget);
    expect(find.text(t.freelance.receiveAction), findsNothing);
  });

  testWidgets('rincian pemasukan milik pembayaran freelance tanpa sunting dan hapus (ADR-019)', (tester) async {
    tallViewport(tester);
    await seedPendingPayment();
    final receivedOn = DateTime(now.year, now.month, 3);
    await freelanceRepository.savePayment(payment.markPaid(walletId: 'bca', date: receivedOn));
    await transactionRepository.saveTransaction(
      IncomeTransaction(
        id: payment.transactionId,
        date: receivedOn,
        amount: 261543750,
        note: 'Honor Studio Koding',
        walletId: 'bca',
        freelancePaymentId: 'pay',
      ),
    );
    await openShell(tester);
    await tester.tap(find.widgetWithText(NavigationDestination, t.appShell.transactionsTabLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Honor Studio Koding'));
    await tester.pumpAndSettle();

    expect(find.byType(TransactionDetailPage), findsOneWidget);
    expect(find.text(t.transaction.detailFreelanceNote), findsOneWidget);
    expect(find.text(t.transaction.editAction), findsNothing);
    expect(find.bySemanticsLabel(t.transaction.deleteAction), findsNothing);
  });

  testWidgets('rincian proyek: penyaring bawaan belum ditagih, dikelompokkan per bulan, Tagih membuka pembayaran', (
    tester,
  ) async {
    tallViewport(tester);
    await freelanceRepository.saveProject(project);
    await freelanceRepository.saveEntries([
      WorklogEntry(id: 'a', projectId: 'studio', date: DateTime(2026, 9, 3), hours: 4, hourlyRate: 7250000),
      WorklogEntry(id: 'b', projectId: 'studio', date: DateTime(2026, 9, 10), hours: 2, hourlyRate: 7250000),
      WorklogEntry(id: 'c', projectId: 'studio', date: DateTime(2026, 8, 20), hours: 8, hourlyRate: 7250000),
      entry,
    ]);
    await freelanceRepository.savePayment(payment);
    await openShell(tester);
    await openFreelanceThroughRecord(tester);

    await tester.tap(find.byType(ProjectCard));
    await tester.pumpAndSettle();

    // Bawaan: hanya 3 entri belum ditagih, dalam dua kelompok bulan.
    expect(find.byType(WorklogEntryCard), findsNWidgets(3));
    expect(find.byType(WorklogMonthHeader), findsNWidgets(2));
    expect(find.text('${t.freelance.statusUnbilled} (3)'), findsOneWidget);

    await tester.tap(find.text('${t.freelance.filterAll} (4)'));
    await tester.pumpAndSettle();
    expect(find.byType(WorklogEntryCard), findsNWidgets(4));

    await tester.tap(find.text(t.freelance.billAction(count: 3)));
    await tester.pumpAndSettle();
    expect(find.text(t.freelance.paymentAddTitle), findsWidgets);
    expect(find.text(t.freelance.paymentEntriesLabel(count: 3, hours: 14).toUpperCase()), findsOneWidget);
  });
}
