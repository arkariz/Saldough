import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/app/shell/app_shell_page.dart';
import 'package:saldough/core/foundation/effect_handler/app_effect_registry.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/spotlight/spotlight.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
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
import 'package:saldough/features/record/presentation/widgets/record_form_host.dart';
import 'package:saldough/shared/auth/auth.dart';
import 'package:saldough/shared/budget_catalog/budget_catalog.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/transaction/transaction_presentation.dart';
import 'package:saldough/shared/wallet/wallet.dart';

import '../../../../helpers/fake_auth_repository.dart';
import '../../../../helpers/routes.dart';

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
      ..registerLazySingleton<AuthRepository>(FakeAuthRepository.new)
      ..registerLazySingleton<WalletRepository>(() => walletRepository)
      ..registerLazySingleton<LedgerChanges>(LedgerChanges.new)
      ..registerLazySingleton<RecurringChanges>(RecurringChanges.new)
      ..registerLazySingleton<RecurringRuleRepository>(
        () => RecurringRuleRepositoryImpl(storage: InMemoryKeyValueStorage()),
      )
      ..registerSingleton<RouteRegistry>(appRouteRegistry())
      ..registerLazySingleton<TransactionRepository>(() => transactionRepository)
      ..registerLazySingleton<BudgetRepository>(() => budgetRepository)
      ..registerLazySingleton<BudgetItemCatalog>(() => BudgetItemCatalogImpl(repository: budgetRepository))
      ..registerLazySingleton<CategoryRepository>(() => CategoryRepositoryImpl(storage: InMemoryKeyValueStorage()))
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
        child: MaterialApp(theme: PixelTheme.light, home: const AppShellPage()),
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
    expect(navIndex(tester), 3);
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
    expect(find.byType(RecordFormHost), findsOneWidget);
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
    expect(navIndex(tester), 2);
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
            theme: PixelTheme.light,
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

      expect(step(1, 3, t.tour.homeBalanceTitle, t.tour.homeBalanceBody), findsOneWidget);
      await tester.tap(find.text(t.tour.nextAction));
      await tester.pumpAndSettle();
      expect(step(2, 3, t.tour.homeRecordTitle, t.tour.homeRecordBody), findsOneWidget);
      await tester.tap(find.text(t.tour.nextAction));
      await tester.pumpAndSettle();
      expect(step(3, 3, t.tour.homeVoiceTitle, t.tour.homeVoiceBody), findsOneWidget);
      await tester.tap(find.text(t.tour.doneAction));
      await tester.pumpAndSettle();

      expect(find.text(t.tour.homeVoiceTitle), findsNothing);
      final progress = (await tutorials.load()).getOrElse((_) => TutorialProgress.empty);
      expect(progress.seenSteps, {SpotlightKey.homeBalance, SpotlightKey.homeRecord, SpotlightKey.homeVoice});
    });

    testWidgets('data lengkap: tujuh langkah termasuk suara, arus, anggaran, Freelance, dan transaksi terbaru', (tester) async {
      tallViewport(tester);
      await seedFull();
      await openShellWithTours(tester);

      expect(step(1, 7, t.tour.homeBalanceTitle, t.tour.homeBalanceBody), findsOneWidget);
      final rest = [
        (t.tour.homeRecordTitle, t.tour.homeRecordBody),
        (t.tour.homeVoiceTitle, t.tour.homeVoiceBody),
        (t.tour.homeCashFlowTitle, t.tour.homeCashFlowBody),
        (t.tour.homeBudgetTitle, t.tour.homeBudgetBody),
        (t.tour.homeFreelanceTitle, t.tour.homeFreelanceBody),
        (t.tour.homeRecentTitle, t.tour.homeRecentBody),
      ];
      for (final (i, (title, body)) in rest.indexed) {
        await tester.tap(find.text(t.tour.nextAction));
        await tester.pumpAndSettle();
        expect(step(i + 2, 7, title, body), findsOneWidget);
      }
    });

    testWidgets('kartu yang muncul belakangan disorot sendiri saat pertama tampil', (tester) async {
      tallViewport(tester);
      await seedWallet();
      await tutorials.markStepsSeen([SpotlightKey.homeBalance, SpotlightKey.homeRecord, SpotlightKey.homeVoice]);
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

  group('TR-WALLET, TR-TXN, TR-BUDGET (ADR-021, T-9.7)', () {
    late TutorialProgressRepositoryImpl tutorials;

    setUp(() async {
      tutorials = TutorialProgressRepositoryImpl(storage: InMemoryKeyValueStorage());
      // Tur Beranda sudah dilihat, supaya yang diuji hanya tur tab.
      await tutorials.markStepsSeen(tourSteps[TourId.home]!);
    });

    Future<void> openShellWithTours(WidgetTester tester) async {
      await tester.pumpWidget(
        ScopeProvider(
          container: container,
          child: MaterialApp(
            theme: PixelTheme.light,
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

    Future<void> openTab(WidgetTester tester, String label) async {
      await tester.tap(find.widgetWithText(NavigationDestination, label));
      await tester.pumpAndSettle();
    }

    Finder step(int current, int total, String title, String body) =>
        find.bySemanticsLabel(t.tour.stepSemantics(current: current, total: total, title: title, body: body));

    Future<void> walkThrough(WidgetTester tester, List<(String, String)> steps) async {
      for (final (i, (title, body)) in steps.indexed) {
        expect(step(i + 1, steps.length, title, body), findsOneWidget);
        await tester.tap(find.text(i == steps.length - 1 ? t.tour.doneAction : t.tour.nextAction));
        await tester.pumpAndSettle();
      }
    }

    testWidgets('Dompet: ringkasan, dompet pertama, lalu tambah — hanya saat tab Dompet dibuka', (tester) async {
      tallViewport(tester);
      await seedFull();
      await openShellWithTours(tester);
      expect(find.text(t.tour.walletSummaryTitle), findsNothing);

      await openTab(tester, t.appShell.walletsTabLabel);
      await walkThrough(tester, [
        (t.tour.walletSummaryTitle, t.tour.walletSummaryBody),
        (t.tour.walletCardTitle, t.tour.walletCardBody),
        (t.tour.walletAddTitle, t.tour.walletAddBody),
      ]);

      await openTab(tester, t.appShell.homeTabLabel);
      await openTab(tester, t.appShell.walletsTabLabel);
      expect(find.text(t.tour.walletSummaryTitle), findsNothing);
    });

    testWidgets('Transaksi: tidak tampil saat bulan ini kosong', (tester) async {
      tallViewport(tester);
      await seedWallet();
      await openShellWithTours(tester);
      await openTab(tester, t.appShell.transactionsTabLabel);
      expect(find.text(t.tour.txnMonthTitle), findsNothing);
    });

    testWidgets('Transaksi: bulan berisi menyorot bulan, cari/Filter, dan baris pertama', (tester) async {
      tallViewport(tester);
      await seedFull();
      await openShellWithTours(tester);
      await openTab(tester, t.appShell.transactionsTabLabel);

      await walkThrough(tester, [
        (t.tour.txnMonthTitle, t.tour.txnMonthBody),
        (t.tour.txnFilterTitle, t.tour.txnFilterBody),
        (t.tour.txnRowTitle, t.tour.txnRowBody),
      ]);
      final progress = (await tutorials.load()).getOrElse((_) => TutorialProgress.empty);
      expect(progress.hasCompleted(TourId.transaction), isTrue);
    });

    testWidgets('Anggaran kosong: hanya Template; ringkasan dan penyaring menyusul saat ada anggaran', (tester) async {
      tallViewport(tester);
      await seedWallet();
      await openShellWithTours(tester);
      await openTab(tester, t.appShell.planTabLabel);
      await walkThrough(tester, [
        (t.tour.planTabsTitle, t.tour.planTabsBody),
        (t.tour.budgetTemplatesTitle, t.tour.budgetTemplatesBody),
      ]);

      await tester.pumpWidget(const SizedBox());
      await seedFull();
      await openShellWithTours(tester);
      await openTab(tester, t.appShell.planTabLabel);
      await walkThrough(tester, [
        (t.tour.budgetSummaryTitle, t.tour.budgetSummaryBody),
        (t.tour.budgetFilterTitle, t.tour.budgetFilterBody),
      ]);
    });

    testWidgets('Rincian anggaran: pos pertama lalu tombol catatnya (TR-BUDGET-DETAIL, T-9.8)', (tester) async {
      tallViewport(tester);
      await seedFull();
      await tutorials.markStepsSeen(tourSteps[TourId.budget]!);
      await openShellWithTours(tester);
      await openTab(tester, t.appShell.planTabLabel);
      await tester.tap(find.text('Rumah tangga').first);
      await tester.pumpAndSettle();

      await walkThrough(tester, [
        (t.tour.budgetDetailItemTitle, t.tour.budgetDetailItemBody),
        (t.tour.budgetDetailRecordTitle, t.tour.budgetDetailRecordBody),
      ]);
    });

    testWidgets('Menu info: "Tur layar ini" memutar ulang tur yang sudah dilihat (T-9.9)', (tester) async {
      tallViewport(tester);
      await seedWallet();
      await openShellWithTours(tester);
      expect(find.text(t.tour.homeBalanceTitle), findsNothing);

      await tester.tap(find.byTooltip(t.info.menuTooltip).first);
      await tester.pumpAndSettle();
      expect(find.text(t.info.showIntroAction), findsOneWidget);
      expect(find.text(t.info.resetAllAction), findsOneWidget);
      await tester.tap(find.text(t.info.replayTourAction));
      await tester.pumpAndSettle();

      expect(step(1, 3, t.tour.homeBalanceTitle, t.tour.homeBalanceBody), findsOneWidget);
    });

    testWidgets('Menu info: setel ulang semua tutorial meminta konfirmasi lalu mengosongkan progres', (tester) async {
      tallViewport(tester);
      await seedWallet();
      await tutorials.markOnboardingDone();
      await openShellWithTours(tester);

      await tester.tap(find.byTooltip(t.info.menuTooltip).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.info.resetAllAction));
      await tester.pumpAndSettle();
      expect(find.text(t.info.resetConfirmMessage), findsOneWidget);
      await tester.tap(find.text(t.info.resetConfirmAction));
      await tester.pumpAndSettle();

      expect(find.text(t.info.resetDoneMessage), findsOneWidget);
      expect((await tutorials.load()).getOrElse((_) => TutorialProgress.empty), TutorialProgress.empty);
    });
  });
}
