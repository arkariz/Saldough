import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/core/foundation/effect_handler/app_effect_registry.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/shell/app_shell_page.dart';
import 'package:saldough/core/presentation/spotlight/spotlight.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/tutorial/tutorial.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/features/budget/data/adapters/budget_item_catalog_impl.dart';
import 'package:saldough/features/budget/data/adapters/budget_overview_source_impl.dart';
import 'package:saldough/features/budget/data/repositories/budget_repository_impl.dart';
import 'package:saldough/features/budget/domain/entities/budget.dart';
import 'package:saldough/features/budget/domain/entities/budget_item.dart';
import 'package:saldough/features/budget/domain/entities/budget_period.dart';
import 'package:saldough/features/budget/domain/repositories/budget_repository.dart';
import 'package:saldough/features/freelance/data/adapters/freelance_overview_source_impl.dart';
import 'package:saldough/features/freelance/data/repositories/freelance_repository_impl.dart';
import 'package:saldough/features/freelance/domain/entities/freelance_payment.dart';
import 'package:saldough/features/freelance/domain/entities/freelance_project.dart';
import 'package:saldough/features/freelance/domain/entities/worklog_entry.dart';
import 'package:saldough/features/freelance/domain/repositories/freelance_repository.dart';
import 'package:saldough/features/home/domain/budget_overview_source.dart';
import 'package:saldough/features/home/domain/freelance_overview_source.dart';
import 'package:saldough/features/home/presentation/pages/home_page.dart';
import 'package:saldough/features/home/presentation/widgets/home_cards.dart';
import 'package:saldough/features/record/domain/budget_item_catalog.dart';
import 'package:saldough/features/record/presentation/widgets/record_choice_sheet.dart';
import 'package:saldough/features/transaction/presentation/widgets/transaction_date_group_card.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Uji Beranda (Fase 6, FR-HOME-001..005) lewat shell sungguhan dengan
/// penyimpanan di memori dan implementasi port yang asli.
void main() {
  late WalletRepositoryImpl walletRepository;
  late TransactionRepositoryImpl transactionRepository;
  late BudgetRepositoryImpl budgetRepository;
  late FreelanceRepositoryImpl freelanceRepository;
  late GetIt container;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day, 9);

  setUpAll(registerEffectHandlers);

  setUp(() {
    final storage = InMemoryKeyValueStorage();
    walletRepository = WalletRepositoryImpl(storage: storage);
    transactionRepository = TransactionRepositoryImpl(storage: storage);
    budgetRepository = BudgetRepositoryImpl(storage: storage);
    freelanceRepository = FreelanceRepositoryImpl(storage: storage);
    container = GetIt.asNewInstance()
      ..registerLazySingleton<WalletRepository>(() => walletRepository)
      ..registerLazySingleton<TransactionRepository>(() => transactionRepository)
      ..registerLazySingleton<BudgetRepository>(() => budgetRepository)
      ..registerLazySingleton<BudgetItemCatalog>(() => BudgetItemCatalogImpl(repository: budgetRepository))
      ..registerLazySingleton<FreelanceRepository>(() => freelanceRepository)
      ..registerLazySingleton<BudgetOverviewSource>(
        () =>
            BudgetOverviewSourceImpl(budgetRepository: budgetRepository, transactionRepository: transactionRepository),
      )
      ..registerLazySingleton<FreelanceOverviewSource>(
        () => FreelanceOverviewSourceImpl(repository: freelanceRepository),
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
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  Future<void> seedWallet() => walletRepository.saveWallet(
    const Wallet(
      id: 'bca',
      name: 'BCA',
      iconKey: 'walletBank',
      initialBalance: 100000000,
      currentBalance: 525000000,
    ),
  );

  /// Pemasukan Rp5.000.000, pengeluaran Rp750.000, dan transfer
  /// Rp1.000.000 bulan ini, plus satu pengeluaran lama.
  Future<void> seedFull() async {
    await seedWallet();
    await walletRepository.saveWallet(
      const Wallet(id: 'gopay', name: 'GoPay', iconKey: 'walletEwallet', initialBalance: 0, currentBalance: 0),
    );
    for (final transaction in <Transaction>[
      IncomeTransaction(id: 'gaji', date: today, amount: 500000000, note: 'Gaji', walletId: 'bca'),
      ExpenseTransaction(
        id: 'makan',
        date: today.add(const Duration(minutes: 5)),
        amount: 75000000,
        note: 'Makan',
        walletId: 'bca',
      ),
      TransferTransaction(
        id: 'topup',
        date: today.add(const Duration(minutes: 10)),
        amount: 100000000,
        note: 'Top-up',
        fromWalletId: 'bca',
        toWalletId: 'gopay',
      ),
      ExpenseTransaction(
        id: 'lama',
        date: DateTime(now.year - 1, now.month, 3),
        amount: 1000000,
        note: 'Lama',
        walletId: 'bca',
      ),
    ]) {
      await transactionRepository.saveTransaction(transaction);
    }
    await budgetRepository.saveBudget(
      Budget(
        id: 'rumah',
        name: 'Rumah tangga',
        walletId: 'bca',
        period: BudgetPeriod.monthly,
        startDate: DateTime(now.year, now.month),
        items: const [BudgetItem(id: 'beras', name: 'Beras', quantity: 2, unitPrice: 7500000)],
      ),
    );
    await freelanceRepository.saveProject(
      const FreelanceProject(id: 'studio', name: 'Studio Koding', hourlyRate: 7250000),
    );
    await freelanceRepository.saveEntries([
      WorklogEntry(
        id: 'w1',
        projectId: 'studio',
        date: DateTime(now.year, now.month),
        hours: 10,
        hourlyRate: 7250000,
        paymentId: 'pay',
      ),
    ]);
    await freelanceRepository.savePayment(
      FreelancePayment(
        id: 'pay',
        projectId: 'studio',
        entryIds: const ['w1'],
        expectedDate: DateTime(now.year, now.month, 28),
      ),
    );
  }

  int navIndex(WidgetTester tester) => tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

  testWidgets('tanpa dompet: ajakan membuat dompet pertama, panduan, dan tanpa kartu berangka nol (FR-HOME-005)', (
    tester,
  ) async {
    tallViewport(tester);
    await openShell(tester);

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text(t.home.createWalletAction), findsOneWidget);
    expect(find.text(t.home.recordAction), findsNothing);
    expect(find.byType(HomeGuide), findsOneWidget);
    // Kartu tanpa isi disembunyikan, bukan diisi Rp0 berderet.
    expect(find.byType(HomeCashFlowRow), findsNothing);
    expect(find.byType(HomeBudgetCard), findsNothing);
    expect(find.byType(HomeFreelanceCard), findsNothing);

    // Satu ajakan membuat dompet, dan tanpa tautan anggaran yang buntu (UX-7).
    expect(find.text(t.home.budgetLink), findsNothing);
    await tester.tap(find.text(t.home.createWalletAction));
    await tester.pumpAndSettle();
    expect(navIndex(tester), 4);
  });

  testWidgets('sudah ada dompet tanpa transaksi: Catat Transaksi membuka alur CATAT yang sama (aturan 8)', (
    tester,
  ) async {
    tallViewport(tester);
    await seedWallet();
    await openShell(tester);

    expect(find.text(t.home.emptyTitle), findsOneWidget);
    await tester.tap(find.text(t.home.recordAction));
    await tester.pumpAndSettle();
    expect(find.byType(RecordChoiceSheet), findsOneWidget);
  });

  testWidgets('saldo, arus bulan ini tanpa transfer, anggaran, freelance, dan transaksi terbaru (FR-HOME-001..004)', (
    tester,
  ) async {
    tallViewport(tester);
    await seedFull();
    await openShell(tester);

    // Total saldo dompet aktif: Rp5.250.000 + Rp0.
    expect(find.descendant(of: find.byType(HeroAmount), matching: find.text('Rp5.250.000')), findsOneWidget);
    // Transfer Rp1.000.000 tidak dihitung; pengeluaran tahun lalu juga tidak.
    final month = CycleMonthFormatter.formatMonthShort(now);
    final flow = find.byType(HomeCashFlowRow);
    expect(
      find.descendant(
        of: flow,
        matching: find.text(t.home.incomeLabel(month: month).toUpperCase()),
      ),
      findsOne,
    );
    expect(find.descendant(of: flow, matching: find.text('+Rp5.000.000')), findsOneWidget);
    expect(find.descendant(of: flow, matching: find.text('−Rp750.000')), findsOneWidget);
    // Anggaran aktif: rencana 2 × Rp75.000.
    expect(find.byType(HomeBudgetCard), findsOneWidget);
    expect(find.text(t.home.budgetSpentOf(spent: 'Rp0', planned: 'Rp150.000')), findsOneWidget);
    // Freelance sebagai tagihan: belum diterima (kotor) 10 jam × Rp72.500,
    // satu tagihan tertunda.
    expect(find.byType(HomeFreelanceCard), findsOneWidget);
    expect(find.text(t.home.freelancePendingInvoices(count: 1)), findsOneWidget);
    expect(find.text('Rp725.000'), findsOneWidget);
    // Terbaru di atas, termasuk transfer (tetap tercatat, hanya tidak dihitung arus).
    final rows = tester.widgetList<TransactionRow>(find.byType(TransactionRow)).map((r) => r.transaction.id);
    expect(rows, ['topup', 'makan', 'gaji', 'lama']);

    await tester.tap(find.text(t.home.seeAll));
    await tester.pumpAndSettle();
    expect(navIndex(tester), 3);
  });

  testWidgets('seluruh kartu anggaran bisa diketuk dan membuka tab Anggaran', (tester) async {
    tallViewport(tester);
    await seedFull();
    await openShell(tester);

    await tester.tap(find.byType(HomeBudgetCard));
    await tester.pumpAndSettle();
    expect(navIndex(tester), 1);
  });

  testWidgets('Beranda di layar 360px + teks 2x tidak overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 3200);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(() {
      tester.view.reset();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    await seedFull();
    await openShell(tester);

    expect(find.byType(HomeBalanceCard), findsOneWidget);
    expect(find.byType(HomeFreelanceCard), findsOneWidget);
  });

  group('TR-HOME (ADR-021)', () {
    late TutorialProgressRepositoryImpl tutorials;

    setUp(() => tutorials = TutorialProgressRepositoryImpl(storage: InMemoryKeyValueStorage()));

    Future<void> openShellWithTours(WidgetTester tester) async {
      await tester.pumpWidget(
        ScopeProvider(
          container: container,
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: SpotlightHost(repository: tutorials, child: child!),
            ),
            home: const AppShellPage(),
          ),
        ),
      );
      for (var i = 0; i < 5; i++) {
        await tester.pump();
      }
      await tester.pumpAndSettle();
    }

    Finder step(int current, int total, String title, String body) =>
        find.bySemanticsLabel(t.tour.stepSemantics(current: current, total: total, title: title, body: body));

    testWidgets('tidak tampil sebelum ada dompet', (tester) async {
      await openShellWithTours(tester);

      expect(find.text(t.tour.homeBalanceTitle), findsNothing);
    });

    testWidgets('dompet tanpa transaksi: kartu arus dan anggaran dilewati', (tester) async {
      tallViewport(tester);
      await seedWallet();
      await openShellWithTours(tester);

      expect(step(1, 2, t.tour.homeBalanceTitle, t.tour.homeBalanceBody), findsOneWidget);
      await tester.tap(find.text(t.tour.nextAction));
      await tester.pumpAndSettle();
      expect(step(2, 2, t.tour.homeRecordTitle, t.tour.homeRecordBody), findsOneWidget);
      await tester.tap(find.text(t.tour.doneAction));
      await tester.pumpAndSettle();

      expect(find.text(t.tour.homeRecordTitle), findsNothing);
      final progress = (await tutorials.load()).getOrElse((_) => TutorialProgress.empty);
      expect(progress.seenSteps, {SpotlightKey.homeBalance, SpotlightKey.homeRecord});
    });

    testWidgets('data lengkap: enam langkah termasuk arus, anggaran, Freelance, dan transaksi terbaru', (tester) async {
      tallViewport(tester);
      await seedFull();
      await openShellWithTours(tester);

      expect(step(1, 6, t.tour.homeBalanceTitle, t.tour.homeBalanceBody), findsOneWidget);
      final rest = [
        (t.tour.homeRecordTitle, t.tour.homeRecordBody),
        (t.tour.homeCashFlowTitle, t.tour.homeCashFlowBody),
        (t.tour.homeBudgetTitle, t.tour.homeBudgetBody),
        (t.tour.homeFreelanceTitle, t.tour.homeFreelanceBody),
        (t.tour.homeRecentTitle, t.tour.homeRecentBody),
      ];
      for (final (i, (title, body)) in rest.indexed) {
        await tester.tap(find.text(t.tour.nextAction));
        await tester.pumpAndSettle();
        expect(step(i + 2, 6, title, body), findsOneWidget);
      }
    });

    testWidgets('kartu yang muncul belakangan disorot sendiri saat pertama tampil', (tester) async {
      tallViewport(tester);
      await seedWallet();
      await tutorials.markStepsSeen([SpotlightKey.homeBalance, SpotlightKey.homeRecord]);
      await seedFull();
      await openShellWithTours(tester);

      // Saldo dan CATAT sudah dilihat; tinggal empat kartu yang baru muncul.
      expect(step(1, 4, t.tour.homeCashFlowTitle, t.tour.homeCashFlowBody), findsOneWidget);
      expect(find.text(t.tour.homeBalanceTitle), findsNothing);
    });

    testWidgets('tidak tampil lagi sesudah selesai', (tester) async {
      await seedWallet();
      await tutorials.markStepsSeen(tourSteps[TourId.home]!);
      await openShellWithTours(tester);

      expect(find.text(t.tour.homeBalanceTitle), findsNothing);
    });
  });
}
