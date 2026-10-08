import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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
import 'package:saldough/features/budget/data/repositories/budget_repository_impl.dart';
import 'package:saldough/features/budget/data/repositories/budget_template_repository_impl.dart';
import 'package:saldough/features/budget/domain/repositories/budget_repository.dart';
import 'package:saldough/features/budget/domain/repositories/budget_template_repository.dart';
import 'package:saldough/features/home/domain/budget_overview_source.dart';
import 'package:saldough/features/home/domain/freelance_overview_source.dart';
import 'package:saldough/features/plan/domain/plan_sources.dart';
import 'package:saldough/features/record/presentation/widgets/record_form_host.dart';
import 'package:saldough/features/transaction/presentation/pages/transaction_list_page.dart';
import 'package:saldough/features/wallet/presentation/widgets/wallet_form_sheet.dart';
import 'package:saldough/shared/auth/auth.dart';
import 'package:saldough/shared/budget_catalog/budget_catalog.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/keypad.dart';
import '../../helpers/mocks.dart';
import '../../helpers/plan_sources.dart';
import '../../helpers/routes.dart';

void main() {
  late InMemoryKeyValueStorage storage;
  late WalletRepositoryImpl walletRepository;
  late GetIt container;

  setUpAll(registerEffectHandlers);

  setUp(() {
    storage = InMemoryKeyValueStorage();
    walletRepository = WalletRepositoryImpl(storage: storage);
    container = GetIt.asNewInstance()
      ..registerLazySingleton<AuthRepository>(FakeAuthRepository.new)
      ..registerLazySingleton<BudgetOverviewSource>(stubBudgetOverviewSource)
      ..registerLazySingleton<FreelanceOverviewSource>(stubFreelanceOverviewSource)
      ..registerLazySingleton<BudgetRepository>(() => BudgetRepositoryImpl(storage: InMemoryKeyValueStorage()))
      ..registerLazySingleton<BudgetTemplateRepository>(() => BudgetTemplateRepositoryImpl(storage: InMemoryKeyValueStorage()))
      ..registerLazySingleton<BudgetItemCatalog>(stubBudgetItemCatalog)
      ..registerLazySingleton<CategoryRepository>(() => CategoryRepositoryImpl(storage: InMemoryKeyValueStorage()))
      ..registerLazySingleton<WalletRepository>(() => walletRepository)
      ..registerLazySingleton<LedgerChanges>(LedgerChanges.new)
      ..registerLazySingleton<RecurringChanges>(RecurringChanges.new)
      ..registerLazySingleton<RecurringRuleRepository>(
        () => RecurringRuleRepositoryImpl(storage: InMemoryKeyValueStorage()),
      )
      ..registerLazySingleton<PlanBudgetSource>(EmptyPlanBudgetSource.new)
      ..registerLazySingleton<PlanFreelanceSource>(EmptyPlanFreelanceSource.new)
      ..registerSingleton<RouteRegistry>(appRouteRegistry())
      ..registerLazySingleton<TransactionRepository>(() => TransactionRepositoryImpl(storage: storage));
  });

  Widget pumpableShell() {
    return ScopeProvider(
      container: container,
      child: MaterialApp(theme: PixelTheme.light, home: const AppShellPage()),
    );
  }

  group('AppShellPage', () {
    testWidgets('empat tab navigasi, CATAT dan suara jadi tombol mengambang (T-11.5)', (tester) async {
      await tester.pumpWidget(pumpableShell());
      await tester.pump();
      // Dua `pump()` -- ScopeWidget<TransactionScope> (T-2.5) bersarang setelah
      // ScopeWidget<RecordScope>, jadi initialisasi async-nya baru mulai satu
      // frame setelah RecordScope selesai; satu `pump()` saja belum cukup.
      await tester.pump();
      // Tiga `pump()` -- ScopeWidget<WalletScope> (T-2.7) bersarang setelah
      // TransactionScope, jadi initialisasinya baru mulai satu frame lagi.
      await tester.pump();
      await tester.pump(); // + ScopeWidget<BudgetScope> (T-4.5)
      await tester.pump(); // + ScopeWidget<HomeScope> (Fase 6)

      // Urutan design system: Beranda, Riwayat, [Catat], Rencana, Dompet
      // (ADR-034 §3.3); tanpa tombol mengambang.
      final labels = tester.widget<AppNavBar>(find.byType(AppNavBar)).destinations.map((d) => d.label);
      expect(
        labels,
        [
          t.appShell.homeTabLabel,
          t.appShell.transactionsTabLabel,
          t.appShell.planTabLabel,
          t.appShell.walletsTabLabel,
        ],
      );
      expect(find.byKey(const ValueKey('nav-catat')), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
      // Tombol Catat di tengah, di antara Riwayat dan Rencana.
      final catat = tester.getCenter(find.byKey(const ValueKey('nav-catat'))).dx;
      final history = find.descendant(of: find.byType(AppNavBar), matching: find.text(t.appShell.transactionsTabLabel));
      final plan = find.descendant(of: find.byType(AppNavBar), matching: find.text(t.appShell.planTabLabel));
      expect(catat, greaterThan(tester.getCenter(history).dx));
      expect(catat, lessThan(tester.getCenter(plan).dx));
    });

    testWidgets('Beranda tampil sebagai tab awal', (tester) async {
      await tester.pumpWidget(pumpableShell());
      await tester.pump();
      // Dua `pump()` -- ScopeWidget<TransactionScope> (T-2.5) bersarang setelah
      // ScopeWidget<RecordScope>, jadi initialisasi async-nya baru mulai satu
      // frame setelah RecordScope selesai; satu `pump()` saja belum cukup.
      await tester.pump();
      // Tiga `pump()` -- ScopeWidget<WalletScope> (T-2.7) bersarang setelah
      // TransactionScope, jadi initialisasinya baru mulai satu frame lagi.
      await tester.pump();
      await tester.pump(); // + ScopeWidget<BudgetScope> (T-4.5)
      await tester.pump(); // + ScopeWidget<HomeScope> (Fase 6)

      expect(find.widgetWithText(AppBar, t.appShell.homeTabLabel), findsOneWidget);
      final nav = tester.widget<AppNavBar>(find.byType(AppNavBar));
      expect(nav.selectedIndex, 0);
    });

    testWidgets('menekan tujuan Dompet berpindah ke tab Dompet', (tester) async {
      await tester.pumpWidget(pumpableShell());
      await tester.pump();
      // Dua `pump()` -- ScopeWidget<TransactionScope> (T-2.5) bersarang setelah
      // ScopeWidget<RecordScope>, jadi initialisasi async-nya baru mulai satu
      // frame setelah RecordScope selesai; satu `pump()` saja belum cukup.
      await tester.pump();
      // Tiga `pump()` -- ScopeWidget<WalletScope> (T-2.7) bersarang setelah
      // TransactionScope, jadi initialisasinya baru mulai satu frame lagi.
      await tester.pump();
      await tester.pump(); // + ScopeWidget<BudgetScope> (T-4.5)
      await tester.pump(); // + ScopeWidget<HomeScope> (Fase 6)

      await tester.tap(find.descendant(of: find.byType(AppNavBar), matching: find.text(t.appShell.walletsTabLabel)));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, t.appShell.walletsTabLabel), findsOneWidget);
      final nav = tester.widget<AppNavBar>(find.byType(AppNavBar));
      expect(nav.selectedIndex, 3);
    });

    testWidgets('menekan tujuan Transaksi berpindah ke tab Transaksi', (tester) async {
      await tester.pumpWidget(pumpableShell());
      await tester.pump();
      // Dua `pump()` -- ScopeWidget<TransactionScope> (T-2.5) bersarang setelah
      // ScopeWidget<RecordScope>, jadi initialisasi async-nya baru mulai satu
      // frame setelah RecordScope selesai; satu `pump()` saja belum cukup.
      await tester.pump();
      // Tiga `pump()` -- ScopeWidget<WalletScope> (T-2.7) bersarang setelah
      // TransactionScope, jadi initialisasinya baru mulai satu frame lagi.
      await tester.pump();
      await tester.pump(); // + ScopeWidget<BudgetScope> (T-4.5)
      await tester.pump(); // + ScopeWidget<HomeScope> (Fase 6)

      await tester.tap(find.descendant(of: find.byType(AppNavBar), matching: find.text(t.appShell.transactionsTabLabel)));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, t.appShell.transactionsTabLabel), findsOneWidget);
    });

    testWidgets('transaksi tersimpan di luar tab Riwayat tampil lewat LedgerChanges, tanpa muat ulang manual (ADR-030)', (
      tester,
    ) async {
      await walletRepository.saveWallet(
        const Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 0, currentBalance: 0),
      );
      await tester.pumpWidget(pumpableShell());
      for (var i = 0; i < 5; i++) {
        await tester.pump();
      }
      await tester.tap(find.descendant(of: find.byType(AppNavBar), matching: find.text(t.appShell.transactionsTabLabel)));
      await tester.pumpAndSettle();
      final inHistory = find.descendant(of: find.byType(TransactionListPage), matching: find.text('Kopi sore'));
      expect(inHistory, findsNothing);

      final transactionRepository = container<TransactionRepository>();
      await RecordTransaction(
        transactionRepository: transactionRepository,
        recomputeWalletBalances: RecomputeWalletBalances(
          walletRepository: walletRepository,
          transactionRepository: transactionRepository,
        ),
        ledgerChanges: container<LedgerChanges>(),
      )(ExpenseTransaction(id: 'kopi', date: DateTime.now(), amount: 2500000, note: 'Kopi sore', walletId: 'bca'));
      await tester.pumpAndSettle();

      expect(inHistory, findsOneWidget);
    });

    testWidgets('menekan CATAT membuka lembar CATAT dengan tiga jenis (FR-REC-001, UX-1), TIDAK mengganti tab aktif', (tester) async {
      await tester.pumpWidget(pumpableShell());
      await tester.pump();
      // Dua `pump()` -- ScopeWidget<TransactionScope> (T-2.5) bersarang setelah
      // ScopeWidget<RecordScope>, jadi initialisasi async-nya baru mulai satu
      // frame setelah RecordScope selesai; satu `pump()` saja belum cukup.
      await tester.pump();
      // Tiga `pump()` -- ScopeWidget<WalletScope> (T-2.7) bersarang setelah
      // TransactionScope, jadi initialisasinya baru mulai satu frame lagi.
      await tester.pump();
      await tester.pump(); // + ScopeWidget<BudgetScope> (T-4.5)
      await tester.pump(); // + ScopeWidget<HomeScope> (Fase 6)

      await tester.tap(find.byKey(const ValueKey('nav-catat')));
      await tester.pumpAndSettle();

      expect(find.text(t.record.kindExpense), findsOneWidget);
      expect(find.text(t.record.kindIncome), findsOneWidget);
      expect(find.text(t.record.kindTransfer), findsOneWidget);

      // Tab yang aktif di baliknya tetap Beranda (tab awal), bukan CATAT --
      // CATAT tidak pernah jadi tab "terpilih" yang persisten.
      final nav = tester.widget<AppNavBar>(find.byType(AppNavBar));
      expect(nav.selectedIndex, 0);
    });

    testWidgets('memilih Masuk di pengalih CATAT membuka formulir pemasukan', (tester) async {
      await walletRepository.saveWallet(
        const Wallet(id: 'w1', name: 'BCA', iconKey: 'walletBank', initialBalance: 0, currentBalance: 0),
      );

      await tester.pumpWidget(pumpableShell());
      await tester.pump();
      // Dua `pump()` -- ScopeWidget<TransactionScope> (T-2.5) bersarang setelah
      // ScopeWidget<RecordScope>, jadi initialisasi async-nya baru mulai satu
      // frame setelah RecordScope selesai; satu `pump()` saja belum cukup.
      await tester.pump();
      // Tiga `pump()` -- ScopeWidget<WalletScope> (T-2.7) bersarang setelah
      // TransactionScope, jadi initialisasinya baru mulai satu frame lagi.
      await tester.pump();
      await tester.pump(); // + ScopeWidget<BudgetScope> (T-4.5)
      await tester.pump(); // + ScopeWidget<HomeScope> (Fase 6)

      await tester.tap(find.byKey(const ValueKey('nav-catat')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.record.kindIncome));
      await tester.pumpAndSettle();

      expect(find.text(t.record.toWalletFieldLabel), findsOneWidget);
      expect(find.text(t.record.amountLabelIncome.toUpperCase()), findsOneWidget);
    });

    testWidgets('Beranda menampilkan kartu Menunggu dicatat bila ada kemunculan menunggu (T-15.6)', (tester) async {
      final now = DateTime.now();
      await container<RecurringRuleRepository>().saveRule(
        RecurringRule(
          id: 'netflix',
          kind: RecurringKind.expense,
          amount: 6500000,
          walletId: 'w1',
          note: 'Netflix',
          schedule: RecurringSchedule(frequency: RecurringFrequency.monthly, anchorDate: DateTime(now.year, now.month)),
        ),
      );
      await tester.pumpWidget(pumpableShell());
      for (var i = 0; i < 5; i++) {
        await tester.pump();
      }
      await tester.pumpAndSettle();

      expect(find.text('${t.recurring.pendingCardTitle} (1)'), findsOneWidget);
      expect(find.text('Netflix ●'), findsOneWidget);
    });

    testWidgets('tab Rencana: sub-tab Anggaran lalu Rutin, tanpa app bar Anggaran ganda (T-15.4)', (tester) async {
      await tester.pumpWidget(pumpableShell());
      for (var i = 0; i < 5; i++) {
        await tester.pump();
      }
      await tester.tap(find.descendant(of: find.byType(AppNavBar), matching: find.text(t.appShell.planTabLabel)));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, t.appShell.planTabLabel), findsOneWidget);
      expect(find.widgetWithText(AppBar, t.appShell.budgetTabLabel), findsNothing);
      expect(find.text(t.appShell.budgetTabLabel.toUpperCase()), findsOneWidget);

      await tester.tap(find.text(t.plan.recurringSegmentLabel.toUpperCase()));
      await tester.pumpAndSettle();
      expect(find.text(t.recurring.starters.salary), findsOneWidget);
    });

    testWidgets('menutup lembar pilihan CATAT tanpa memilih kembali ke tab sebelumnya', (tester) async {
      await tester.pumpWidget(pumpableShell());
      await tester.pump();
      // Dua `pump()` -- ScopeWidget<TransactionScope> (T-2.5) bersarang setelah
      // ScopeWidget<RecordScope>, jadi initialisasi async-nya baru mulai satu
      // frame setelah RecordScope selesai; satu `pump()` saja belum cukup.
      await tester.pump();
      // Tiga `pump()` -- ScopeWidget<WalletScope> (T-2.7) bersarang setelah
      // TransactionScope, jadi initialisasinya baru mulai satu frame lagi.
      await tester.pump();
      await tester.pump(); // + ScopeWidget<BudgetScope> (T-4.5)
      await tester.pump(); // + ScopeWidget<HomeScope> (Fase 6)

      await tester.tap(find.descendant(of: find.byType(AppNavBar), matching: find.text(t.appShell.planTabLabel)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('nav-catat')));
      await tester.pumpAndSettle();

      // Tutup lembar dengan tap di luar (barrier).
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, t.appShell.planTabLabel), findsOneWidget);
    });

    testWidgets(
      'mencatat pemasukan lewat CATAT sungguhan menambah saldo dompet tersimpan (uji pengawatan penuh)',
      (tester) async {
        await walletRepository.saveWallet(
          const Wallet(id: 'w1', name: 'BCA', iconKey: 'walletBank', initialBalance: 0, currentBalance: 0),
        );

        await tester.pumpWidget(pumpableShell());
        await tester.pump();
        // Dua `pump()` -- ScopeWidget<TransactionScope> (T-2.5) bersarang setelah
        // ScopeWidget<RecordScope>, jadi initialisasi async-nya baru mulai satu
        // frame setelah RecordScope selesai; satu `pump()` saja belum cukup.
        await tester.pump();
        // Tiga `pump()` -- ScopeWidget<WalletScope> (T-2.7) bersarang setelah
        // TransactionScope, jadi initialisasinya baru mulai satu frame lagi.
        await tester.pump();
        await tester.pump(); // + ScopeWidget<BudgetScope> (T-4.5)
        await tester.pump(); // + ScopeWidget<HomeScope> (Fase 6)

        await tester.tap(find.byKey(const ValueKey('nav-catat')));
        await tester.pumpAndSettle();
        await tester.tap(find.text(t.record.kindIncome));
        await tester.pumpAndSettle();

        await enterAmount(tester, '75000');
        await tester.pump();
        // Satu-satunya dompet aktif sudah terpilih tanpa membuka menu (UX-2).
        expect(find.text(t.record.walletNotSelectedPrompt), findsNothing);
        expect(find.text('BCA'), findsWidgets);
        await tester.ensureVisible(find.widgetWithText(AppButton, t.record.incomeAction));
        await tester.tap(find.widgetWithText(AppButton, t.record.incomeAction));
        await tester.pumpAndSettle();

        final wallets = (await walletRepository.listWallets()).getOrElse((_) => throw StateError('expected Right'));
        expect(wallets.single.currentBalance, 7500000);

        // Transaksi yang baru dicatat langsung tampil di tab Transaksi tanpa
        // memulai ulang aplikasi.
        await tester.tap(find.descendant(of: find.byType(AppNavBar), matching: find.text(t.appShell.transactionsTabLabel)));
        await tester.pumpAndSettle();
        expect(find.text('+Rp75.000'), findsWidgets);
      },
    );

    testWidgets('CATAT langsung ke Pengeluaran, pengalih mengganti formulir, kembali menutup alur (UX-1)', (
      tester,
    ) async {
      await walletRepository.saveWallet(
        const Wallet(id: 'w1', name: 'BCA', iconKey: 'walletBank', initialBalance: 0, currentBalance: 0),
      );

      await tester.pumpWidget(pumpableShell());
      for (var i = 0; i < 5; i++) {
        await tester.pump();
      }

      await tester.tap(find.byKey(const ValueKey('nav-catat')));
      await tester.pumpAndSettle();

      // Satu ketukan: formulir Pengeluaran, bukan lembar pilihan.
      expect(find.byType(RecordFormHost), findsOneWidget);
      expect(find.text(t.record.amountLabelExpense.toUpperCase()), findsOneWidget);

      await tester.tap(find.text(t.record.kindIncome));
      await tester.pumpAndSettle();
      expect(find.text(t.record.amountLabelIncome.toUpperCase()), findsOneWidget);

      await tester.tap(find.text(t.record.kindTransfer));
      await tester.pumpAndSettle();
      expect(find.text(t.record.amountLabelIncome.toUpperCase()), findsNothing);
      expect(find.text(t.record.transferAction), findsWidgets);

      await tester.tap(find.byWidgetPredicate((w) => w is AppIcon && w.iconKey == IconKey.chevronLeft));
      await tester.pumpAndSettle();

      expect(find.byType(RecordFormHost), findsNothing);
    });

    testWidgets('kegagalan pemuatan dompet tidak pernah membuka lembar CATAT (hanya snackbar galat)', (
      tester,
    ) async {
      final failingContainer = GetIt.asNewInstance()
        ..registerLazySingleton<AuthRepository>(FakeAuthRepository.new)
        ..registerLazySingleton<BudgetOverviewSource>(stubBudgetOverviewSource)
        ..registerLazySingleton<FreelanceOverviewSource>(stubFreelanceOverviewSource)
        ..registerLazySingleton<BudgetRepository>(() => BudgetRepositoryImpl(storage: InMemoryKeyValueStorage()))
        ..registerLazySingleton<BudgetTemplateRepository>(() => BudgetTemplateRepositoryImpl(storage: InMemoryKeyValueStorage()))
        ..registerLazySingleton<BudgetItemCatalog>(stubBudgetItemCatalog)
        ..registerLazySingleton<CategoryRepository>(() => CategoryRepositoryImpl(storage: InMemoryKeyValueStorage()))
        ..registerLazySingleton<WalletRepository>(failingWalletRepository)
        ..registerLazySingleton<LedgerChanges>(LedgerChanges.new)
        ..registerLazySingleton<RecurringChanges>(RecurringChanges.new)
        ..registerLazySingleton<RecurringRuleRepository>(
          () => RecurringRuleRepositoryImpl(storage: InMemoryKeyValueStorage()),
        )
        ..registerLazySingleton<PlanBudgetSource>(EmptyPlanBudgetSource.new)
        ..registerLazySingleton<PlanFreelanceSource>(EmptyPlanFreelanceSource.new)
      ..registerSingleton<RouteRegistry>(appRouteRegistry())
        ..registerLazySingleton<TransactionRepository>(() => TransactionRepositoryImpl(storage: storage));

      await tester.pumpWidget(
        ScopeProvider(
          container: failingContainer,
          child: MaterialApp(theme: PixelTheme.light, home: const AppShellPage()),
        ),
      );
      await tester.pump();
      // Dua `pump()` -- ScopeWidget<TransactionScope> (T-2.5) bersarang setelah
      // ScopeWidget<RecordScope>, jadi initialisasi async-nya baru mulai satu
      // frame setelah RecordScope selesai; satu `pump()` saja belum cukup.
      await tester.pump();
      // Tiga `pump()` -- ScopeWidget<WalletScope> (T-2.7) bersarang setelah
      // TransactionScope, jadi initialisasinya baru mulai satu frame lagi.
      await tester.pump();
      await tester.pump(); // + ScopeWidget<BudgetScope> (T-4.5)
      await tester.pump(); // + ScopeWidget<HomeScope> (Fase 6)

      await tester.tap(find.byKey(const ValueKey('nav-catat')));
      await tester.pumpAndSettle();

      expect(find.byType(RecordFormHost), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('aksi awal createWallet membuka formulir dompet sekali (ADR-021 §3.2)', (tester) async {
      await tester.pumpWidget(
        ScopeProvider(
          container: container,
          child: MaterialApp(theme: PixelTheme.light, home: const AppShellPage(startAction: ShellStartAction.createWallet)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(WalletFormSheet), findsOneWidget);
      // Tetap di Beranda -- tur Beranda menyusul sesudah dompet dibuat.
      final nav = tester.widget<AppNavBar>(find.byType(AppNavBar));
      expect(nav.selectedIndex, 0);
    });
  });

  group('TR-CATAT (ADR-021, T-9.6)', () {
    late TutorialProgressRepositoryImpl tutorials;

    setUp(() async {
      tutorials = TutorialProgressRepositoryImpl(storage: InMemoryKeyValueStorage());
      // Tur Beranda sudah dilihat, supaya yang diuji hanya tur CATAT.
      await tutorials.markStepsSeen(tourSteps[TourId.home]!);
      await walletRepository.saveWallet(
        const Wallet(id: 'w1', name: 'BCA', iconKey: 'walletBank', initialBalance: 0, currentBalance: 0),
      );
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

    Finder step(int current, int total, String title, String body) =>
        find.bySemanticsLabel(t.tour.stepSemantics(current: current, total: total, title: title, body: body));

    testWidgets('pembukaan CATAT pertama menyorot pengalih, nominal, dompet, dan Ulangi; berikutnya tidak', (tester) async {
      await openShellWithTours(tester);

      await tester.tap(find.byKey(const ValueKey('nav-catat')));
      await tester.pumpAndSettle();

      // Tanpa pos anggaran yang ditawarkan, langkah pos dilewati.
      expect(step(1, 4, t.tour.recordKindTitle, t.tour.recordKindBody), findsOneWidget);
      await tester.tap(find.text(t.tour.nextAction));
      await tester.pumpAndSettle();
      expect(step(2, 4, t.tour.recordAmountTitle, t.tour.recordAmountBody), findsOneWidget);
      await tester.tap(find.text(t.tour.nextAction));
      await tester.pumpAndSettle();
      expect(step(3, 4, t.tour.recordWalletTitle, t.tour.recordWalletBody), findsOneWidget);
      await tester.tap(find.text(t.tour.nextAction));
      await tester.pumpAndSettle();
      expect(step(4, 4, t.tour.recordRepeatTitle, t.tour.recordRepeatBody), findsOneWidget);
      await tester.tap(find.text(t.tour.doneAction));
      await tester.pumpAndSettle();

      // Tur tidak menutup lembar CATAT di baliknya.
      expect(find.byType(RecordFormHost), findsOneWidget);
      final back = find.byWidgetPredicate((w) => w is AppIcon && w.iconKey == IconKey.chevronLeft);
      await tester.ensureVisible(back);
      await tester.pumpAndSettle();
      await tester.tap(back);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('nav-catat')));
      await tester.pumpAndSettle();
      expect(find.text(t.tour.recordKindTitle), findsNothing);
      expect(find.byType(RecordFormHost), findsOneWidget);
    });

    testWidgets('memilih Masuk pertama kali menyorot jalur Freelance di atas nominal', (tester) async {
      await tutorials.markStepsSeen([
        SpotlightKey.recordKind,
        SpotlightKey.recordAmount,
        SpotlightKey.recordWallet,
        SpotlightKey.recordRepeat,
      ]);
      await openShellWithTours(tester);
      await tester.tap(find.byKey(const ValueKey('nav-catat')));
      await tester.pumpAndSettle();
      // Pengeluaran sudah dikenal: tidak ada tur.
      expect(find.text(t.tour.recordKindTitle), findsNothing);

      await tester.tap(find.text(t.record.kindIncome));
      await tester.pumpAndSettle();

      expect(step(1, 1, t.tour.recordFreelanceTitle, t.tour.recordFreelanceBody), findsOneWidget);
      // Kartu Freelance ada di atas bidang nominal.
      final callout = tester.getRect(find.textContaining(t.record.freelanceCalloutTitle));
      final amount = tester.getRect(find.text(t.record.amountLabelIncome.toUpperCase()));
      expect(callout.bottom, lessThan(amount.top));
    });

    testWidgets('tombol kembali saat tur menutup tur, bukan lembar CATAT', (tester) async {
      await openShellWithTours(tester);
      await tester.tap(find.byKey(const ValueKey('nav-catat')));
      await tester.pumpAndSettle();
      expect(find.text(t.tour.recordKindTitle), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text(t.tour.recordKindTitle), findsNothing);
      expect(find.byType(RecordFormHost), findsOneWidget);
    });
  });

  group('AppShellPage -- label navigasi di layar sempit', () {
    // Font asli dimuat supaya lebar label terukur seperti di perangkat (bawaan
    // uji memakai Ahem, yang tiap glifnya selebar ukuran font).
    setUpAll(() async {
      final loader = FontLoader('PlusJakartaSans')..addFont(rootBundle.load('assets/fonts/PlusJakartaSans-Variable.ttf'));
      await loader.load();
    });

    for (final locale in [AppLocale.id, AppLocale.en]) {
      testWidgets('lebar 360dp, locale ${locale.languageCode}: tiap label sebaris, tanpa overflow', (tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(locale));
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.id));
        tester.view
          ..physicalSize = const Size(360, 720)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(pumpableShell());
        for (var i = 0; i < 5; i++) {
          await tester.pump(); // Lima ScopeWidget bersarang, lihat uji di atas.
        }

        expect(tester.takeException(), isNull);
        final labels = [
          ...tester.widget<AppNavBar>(find.byType(AppNavBar)).destinations.map((d) => d.label),
          t.appShell.recordAction,
        ];
        for (final label in labels) {
          final texts = find.descendant(of: find.byType(AppNavBar), matching: find.text(label));
          expect(texts, findsWidgets);
          for (final element in texts.evaluate()) {
            final paragraph = element.renderObject! as RenderParagraph;
            // Lebar tanpa pembungkusan harus muat di lebar yang tersedia.
            expect(
              paragraph.getMaxIntrinsicWidth(double.infinity),
              lessThanOrEqualTo(paragraph.size.width),
              reason: '"$label" terbungkus ke baris kedua',
            );
          }
        }
      });
    }
  });
}
