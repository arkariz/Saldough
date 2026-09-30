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
import 'package:saldough/core/tutorial/tutorial.dart';
import 'package:saldough/features/budget/data/repositories/budget_repository_impl.dart';
import 'package:saldough/features/budget/domain/repositories/budget_repository.dart';
import 'package:saldough/features/home/domain/budget_overview_source.dart';
import 'package:saldough/features/home/domain/freelance_overview_source.dart';
import 'package:saldough/features/record/presentation/widgets/record_form_host.dart';
import 'package:saldough/features/transaction/presentation/pages/transaction_list_page.dart';
import 'package:saldough/features/wallet/presentation/widgets/wallet_form_sheet.dart';
import 'package:saldough/shared/auth/auth.dart';
import 'package:saldough/shared/budget_catalog/budget_catalog.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/mocks.dart';
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
      ..registerLazySingleton<BudgetItemCatalog>(stubBudgetItemCatalog)
      ..registerLazySingleton<CategoryRepository>(() => CategoryRepositoryImpl(storage: InMemoryKeyValueStorage()))
      ..registerLazySingleton<WalletRepository>(() => walletRepository)
      ..registerLazySingleton<LedgerChanges>(LedgerChanges.new)
      ..registerSingleton<RouteRegistry>(appRouteRegistry())
      ..registerLazySingleton<TransactionRepository>(() => TransactionRepositoryImpl(storage: storage));
  });

  Widget pumpableShell() {
    return ScopeProvider(
      container: container,
      child: const MaterialApp(home: AppShellPage()),
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

      expect(find.byType(NavigationDestination), findsNWidgets(4));
      final labels = tester.widgetList<NavigationDestination>(find.byType(NavigationDestination)).map((d) => d.label);
      expect(
        labels,
        [
          t.appShell.homeTabLabel,
          t.appShell.budgetTabLabel,
          t.appShell.transactionsTabLabel,
          t.appShell.walletsTabLabel,
        ],
      );
      expect(find.byKey(const ValueKey('shell-record-fab')), findsOneWidget);
      expect(find.byKey(const ValueKey('shell-voice-fab')), findsOneWidget);
      // Tombol suara di atas tombol CATAT.
      expect(
        tester.getCenter(find.byKey(const ValueKey('shell-voice-fab'))).dy,
        lessThan(tester.getCenter(find.byKey(const ValueKey('shell-record-fab'))).dy),
      );
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
      final nav = tester.widget<NavigationBar>(find.byType(NavigationBar));
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

      await tester.tap(find.widgetWithText(NavigationDestination, t.appShell.walletsTabLabel));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, t.appShell.walletsTabLabel), findsOneWidget);
      final nav = tester.widget<NavigationBar>(find.byType(NavigationBar));
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

      await tester.tap(find.widgetWithText(NavigationDestination, t.appShell.transactionsTabLabel));
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
      await tester.tap(find.widgetWithText(NavigationDestination, t.appShell.transactionsTabLabel));
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

      await tester.tap(find.byKey(const ValueKey('shell-record-fab')));
      await tester.pumpAndSettle();

      expect(find.text(t.record.kindExpense.toUpperCase()), findsOneWidget);
      expect(find.text(t.record.kindIncome.toUpperCase()), findsOneWidget);
      expect(find.text(t.record.kindTransfer.toUpperCase()), findsOneWidget);

      // Tab yang aktif di baliknya tetap Beranda (tab awal), bukan CATAT --
      // CATAT tidak pernah jadi tab "terpilih" yang persisten.
      final nav = tester.widget<NavigationBar>(find.byType(NavigationBar));
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

      await tester.tap(find.byKey(const ValueKey('shell-record-fab')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.record.kindIncome.toUpperCase()));
      await tester.pumpAndSettle();

      expect(find.text(t.record.toWalletFieldLabel.toUpperCase()), findsOneWidget);
      expect(find.text(t.record.amountLabelIncome.toUpperCase()), findsOneWidget);
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

      await tester.tap(find.widgetWithText(NavigationDestination, t.appShell.budgetTabLabel));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('shell-record-fab')));
      await tester.pumpAndSettle();

      // Tutup lembar dengan tap di luar (barrier).
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, t.appShell.budgetTabLabel), findsOneWidget);
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

        await tester.tap(find.byKey(const ValueKey('shell-record-fab')));
        await tester.pumpAndSettle();
        await tester.tap(find.text(t.record.kindIncome.toUpperCase()));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).first, '75000');
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
        await tester.tap(find.widgetWithText(NavigationDestination, t.appShell.transactionsTabLabel));
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

      await tester.tap(find.byKey(const ValueKey('shell-record-fab')));
      await tester.pumpAndSettle();

      // Satu ketukan: formulir Pengeluaran, bukan lembar pilihan.
      expect(find.byType(RecordFormHost), findsOneWidget);
      expect(find.text(t.record.amountLabelExpense.toUpperCase()), findsOneWidget);

      await tester.tap(find.text(t.record.kindIncome.toUpperCase()));
      await tester.pumpAndSettle();
      expect(find.text(t.record.amountLabelIncome.toUpperCase()), findsOneWidget);

      await tester.tap(find.text(t.record.kindTransfer.toUpperCase()));
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
        ..registerLazySingleton<BudgetItemCatalog>(stubBudgetItemCatalog)
        ..registerLazySingleton<CategoryRepository>(() => CategoryRepositoryImpl(storage: InMemoryKeyValueStorage()))
        ..registerLazySingleton<WalletRepository>(failingWalletRepository)
        ..registerLazySingleton<LedgerChanges>(LedgerChanges.new)
      ..registerSingleton<RouteRegistry>(appRouteRegistry())
        ..registerLazySingleton<TransactionRepository>(() => TransactionRepositoryImpl(storage: storage));

      await tester.pumpWidget(
        ScopeProvider(
          container: failingContainer,
          child: const MaterialApp(home: AppShellPage()),
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

      await tester.tap(find.byKey(const ValueKey('shell-record-fab')));
      await tester.pumpAndSettle();

      expect(find.byType(RecordFormHost), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('aksi awal createWallet membuka formulir dompet sekali (ADR-021 §3.2)', (tester) async {
      await tester.pumpWidget(
        ScopeProvider(
          container: container,
          child: const MaterialApp(home: AppShellPage(startAction: ShellStartAction.createWallet)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(WalletFormSheet), findsOneWidget);
      // Tetap di Beranda -- tur Beranda menyusul sesudah dompet dibuat.
      final nav = tester.widget<NavigationBar>(find.byType(NavigationBar));
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

    testWidgets('pembukaan CATAT pertama menyorot pengalih, nominal, dan dompet; berikutnya tidak', (tester) async {
      await openShellWithTours(tester);

      await tester.tap(find.byKey(const ValueKey('shell-record-fab')));
      await tester.pumpAndSettle();

      // Tanpa pos anggaran yang ditawarkan, langkah pos dilewati.
      expect(step(1, 3, t.tour.recordKindTitle, t.tour.recordKindBody), findsOneWidget);
      await tester.tap(find.text(t.tour.nextAction));
      await tester.pumpAndSettle();
      expect(step(2, 3, t.tour.recordAmountTitle, t.tour.recordAmountBody), findsOneWidget);
      await tester.tap(find.text(t.tour.nextAction));
      await tester.pumpAndSettle();
      expect(step(3, 3, t.tour.recordWalletTitle, t.tour.recordWalletBody), findsOneWidget);
      await tester.tap(find.text(t.tour.doneAction));
      await tester.pumpAndSettle();

      // Tur tidak menutup lembar CATAT di baliknya.
      expect(find.byType(RecordFormHost), findsOneWidget);
      final back = find.byWidgetPredicate((w) => w is AppIcon && w.iconKey == IconKey.chevronLeft);
      await tester.ensureVisible(back);
      await tester.pumpAndSettle();
      await tester.tap(back);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('shell-record-fab')));
      await tester.pumpAndSettle();
      expect(find.text(t.tour.recordKindTitle), findsNothing);
      expect(find.byType(RecordFormHost), findsOneWidget);
    });

    testWidgets('memilih Masuk pertama kali menyorot jalur Freelance di atas nominal', (tester) async {
      await tutorials.markStepsSeen([SpotlightKey.recordKind, SpotlightKey.recordAmount, SpotlightKey.recordWallet]);
      await openShellWithTours(tester);
      await tester.tap(find.byKey(const ValueKey('shell-record-fab')));
      await tester.pumpAndSettle();
      // Pengeluaran sudah dikenal: tidak ada tur.
      expect(find.text(t.tour.recordKindTitle), findsNothing);

      await tester.tap(find.text(t.record.kindIncome.toUpperCase()));
      await tester.pumpAndSettle();

      expect(step(1, 1, t.tour.recordFreelanceTitle, t.tour.recordFreelanceBody), findsOneWidget);
      // Kartu Freelance ada di atas bidang nominal.
      final callout = tester.getRect(find.textContaining(t.record.freelanceCalloutTitle));
      final amount = tester.getRect(find.text(t.record.amountLabelIncome.toUpperCase()));
      expect(callout.bottom, lessThan(amount.top));
    });

    testWidgets('tombol kembali saat tur menutup tur, bukan lembar CATAT', (tester) async {
      await openShellWithTours(tester);
      await tester.tap(find.byKey(const ValueKey('shell-record-fab')));
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
      final loader = FontLoader('SpaceMono')..addFont(rootBundle.load('assets/fonts/SpaceMono-Bold.ttf'));
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
        final labels = tester.widgetList<NavigationDestination>(find.byType(NavigationDestination)).map((d) => d.label);
        for (final label in labels) {
          final texts = find.descendant(of: find.byType(NavigationBar), matching: find.text(label));
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
