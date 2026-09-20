import 'package:dependencies/dependencies.dart';
import 'package:di/di.dart';
import 'package:failures/failures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/core/foundation/effect_handler/app_effect_registry.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/shell/app_shell_page.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/record/presentation/widgets/record_choice_sheet.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Dobel gagal untuk [WalletRepository] -- `listWallets()` SELALU
/// mengembalikan `Left`, mensimulasikan pembacaan yang gagal (bukan
/// genuinely kosong). Hanya `listWallets()` yang dipakai uji di berkas ini;
/// dua metode lain melempar kalau sampai terpanggil.
final class _FailingWalletRepository implements WalletRepository {
  @override
  Future<Either<Failure, List<Wallet>>> listWallets() async => const Left(
    SystemFailure(code: FailureCode('TEST_FORCED_FAILURE'), message: 'dipaksa gagal untuk uji'),
  );

  @override
  Future<Either<Failure, Unit>> saveWallet(Wallet wallet) => throw UnimplementedError();

  @override
  Future<Either<Failure, Unit>> deleteWallet(String id) => throw UnimplementedError();
}

void main() {
  late InMemoryKeyValueStorage storage;
  late WalletRepositoryImpl walletRepository;
  late GetIt container;

  setUpAll(registerEffectHandlers);

  setUp(() {
    storage = InMemoryKeyValueStorage();
    walletRepository = WalletRepositoryImpl(storage: storage);
    container = GetIt.asNewInstance()
      ..registerLazySingleton<WalletRepository>(() => walletRepository)
      ..registerLazySingleton<TransactionRepository>(() => TransactionRepositoryImpl(storage: storage));
  });

  Widget pumpableShell() {
    return ScopeProvider(
      container: container,
      child: const MaterialApp(home: AppShellPage()),
    );
  }

  group('AppShellPage', () {
    testWidgets('menampilkan lima tujuan navigasi dengan CATAT di tengah', (tester) async {
      await tester.pumpWidget(pumpableShell());
      await tester.pump();
      // Dua `pump()` -- ScopeWidget<TransactionScope> (T-2.5) bersarang setelah
      // ScopeWidget<RecordScope>, jadi initialisasi async-nya baru mulai satu
      // frame setelah RecordScope selesai; satu `pump()` saja belum cukup.
      await tester.pump();

      expect(find.byType(NavigationDestination), findsNWidgets(5));
      final labels = tester.widgetList<NavigationDestination>(find.byType(NavigationDestination)).map((d) => d.label);
      expect(
        labels,
        [
          t.appShell.homeTabLabel,
          t.appShell.budgetTabLabel,
          t.appShell.recordAction,
          t.appShell.transactionsTabLabel,
          t.appShell.walletsTabLabel,
        ],
      );
    });

    testWidgets('Beranda tampil sebagai tab awal', (tester) async {
      await tester.pumpWidget(pumpableShell());
      await tester.pump();
      // Dua `pump()` -- ScopeWidget<TransactionScope> (T-2.5) bersarang setelah
      // ScopeWidget<RecordScope>, jadi initialisasi async-nya baru mulai satu
      // frame setelah RecordScope selesai; satu `pump()` saja belum cukup.
      await tester.pump();

      expect(find.widgetWithText(AppBar, t.appShell.homeTabLabel), findsOneWidget);
      final nav = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(nav.selectedIndex, 0);
    });

    testWidgets('menekan tujuan Dompet berpindah ke tab Dompet, melompati CATAT', (tester) async {
      await tester.pumpWidget(pumpableShell());
      await tester.pump();
      // Dua `pump()` -- ScopeWidget<TransactionScope> (T-2.5) bersarang setelah
      // ScopeWidget<RecordScope>, jadi initialisasi async-nya baru mulai satu
      // frame setelah RecordScope selesai; satu `pump()` saja belum cukup.
      await tester.pump();

      await tester.tap(find.widgetWithText(NavigationDestination, t.appShell.walletsTabLabel));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, t.appShell.walletsTabLabel), findsOneWidget);
      final nav = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(nav.selectedIndex, 4);
    });

    testWidgets('menekan tujuan Transaksi berpindah ke tab Transaksi', (tester) async {
      await tester.pumpWidget(pumpableShell());
      await tester.pump();
      // Dua `pump()` -- ScopeWidget<TransactionScope> (T-2.5) bersarang setelah
      // ScopeWidget<RecordScope>, jadi initialisasi async-nya baru mulai satu
      // frame setelah RecordScope selesai; satu `pump()` saja belum cukup.
      await tester.pump();

      await tester.tap(find.widgetWithText(NavigationDestination, t.appShell.transactionsTabLabel));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, t.appShell.transactionsTabLabel), findsOneWidget);
    });

    testWidgets('menekan CATAT membuka lembar tiga pilihan (FR-REC-001), TIDAK mengganti tab aktif', (tester) async {
      await tester.pumpWidget(pumpableShell());
      await tester.pump();
      // Dua `pump()` -- ScopeWidget<TransactionScope> (T-2.5) bersarang setelah
      // ScopeWidget<RecordScope>, jadi initialisasi async-nya baru mulai satu
      // frame setelah RecordScope selesai; satu `pump()` saja belum cukup.
      await tester.pump();

      await tester.tap(find.widgetWithText(NavigationDestination, t.appShell.recordAction));
      await tester.pumpAndSettle();

      expect(find.text(t.record.incomeAction), findsWidgets);
      expect(find.text(t.record.expenseAction), findsWidgets);
      expect(find.text(t.record.transferAction), findsWidgets);

      // Tab yang aktif di baliknya tetap Beranda (tab awal), bukan CATAT --
      // CATAT tidak pernah jadi tab "terpilih" yang persisten.
      final nav = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(nav.selectedIndex, 0);
    });

    testWidgets('memilih "Catat Pemasukan" dari lembar pilihan membuka formulir pemasukan', (tester) async {
      await walletRepository.saveWallet(
        const Wallet(id: 'w1', name: 'BCA', iconKey: 'walletBank', initialBalance: 0, currentBalance: 0),
      );

      await tester.pumpWidget(pumpableShell());
      await tester.pump();
      // Dua `pump()` -- ScopeWidget<TransactionScope> (T-2.5) bersarang setelah
      // ScopeWidget<RecordScope>, jadi initialisasi async-nya baru mulai satu
      // frame setelah RecordScope selesai; satu `pump()` saja belum cukup.
      await tester.pump();

      await tester.tap(find.widgetWithText(NavigationDestination, t.appShell.recordAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.record.incomeAction).first);
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

      await tester.tap(find.widgetWithText(NavigationDestination, t.appShell.budgetTabLabel));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(NavigationDestination, t.appShell.recordAction));
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

        await tester.tap(find.widgetWithText(NavigationDestination, t.appShell.recordAction));
        await tester.pumpAndSettle();
        await tester.tap(find.text(t.record.incomeAction).first);
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).first, '75000');
        await tester.pump();
        await tester.ensureVisible(find.text(t.record.walletNotSelectedPrompt));
        await tester.tap(find.text(t.record.walletNotSelectedPrompt));
        await tester.pumpAndSettle();
        await tester.tap(find.text('BCA').last);
        await tester.pumpAndSettle();
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

    testWidgets('menutup formulir dengan BackToChoice membuka ulang RecordChoiceSheet', (tester) async {
      await walletRepository.saveWallet(
        const Wallet(id: 'w1', name: 'BCA', iconKey: 'walletBank', initialBalance: 0, currentBalance: 0),
      );

      await tester.pumpWidget(pumpableShell());
      await tester.pump();
      // Dua `pump()` -- ScopeWidget<TransactionScope> (T-2.5) bersarang setelah
      // ScopeWidget<RecordScope>, jadi initialisasi async-nya baru mulai satu
      // frame setelah RecordScope selesai; satu `pump()` saja belum cukup.
      await tester.pump();

      await tester.tap(find.widgetWithText(NavigationDestination, t.appShell.recordAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.record.incomeAction).first);
      await tester.pumpAndSettle();

      // Sekarang di formulir pemasukan -- pastikan RecordChoiceSheet sudah
      // tertutup.
      expect(find.byType(RecordChoiceSheet), findsNothing);
      expect(find.text(t.record.amountLabelIncome.toUpperCase()), findsOneWidget);

      await tester.tap(find.byWidgetPredicate((w) => w is AppIcon && w.iconKey == IconKey.chevronLeft));
      await tester.pumpAndSettle();

      // Kembali ke RecordChoiceSheet, bukan menutup seluruh alur CATAT.
      expect(find.byType(RecordChoiceSheet), findsOneWidget);
      expect(find.text(t.record.incomeAction), findsWidgets);
      expect(find.text(t.record.expenseAction), findsWidgets);
      expect(find.text(t.record.transferAction), findsWidgets);
    });

    testWidgets('kegagalan pemuatan dompet tidak pernah menampilkan RecordChoiceSheet (hanya snackbar galat)', (
      tester,
    ) async {
      final failingContainer = GetIt.asNewInstance()
        ..registerLazySingleton<WalletRepository>(_FailingWalletRepository.new)
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

      await tester.tap(find.widgetWithText(NavigationDestination, t.appShell.recordAction));
      await tester.pumpAndSettle();

      expect(find.byType(RecordChoiceSheet), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
