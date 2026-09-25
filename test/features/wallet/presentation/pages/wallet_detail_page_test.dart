import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/core/foundation/effect_handler/app_effect_registry.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/shell/app_shell_page.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/budget/data/repositories/budget_repository_impl.dart';
import 'package:saldough/features/budget/domain/repositories/budget_repository.dart';
import 'package:saldough/features/record/presentation/widgets/record_choice_sheet.dart';
import 'package:saldough/features/transaction/presentation/pages/transaction_detail_page.dart';
import 'package:saldough/features/transaction/presentation/pages/transaction_list_page.dart';
import 'package:saldough/features/wallet/presentation/pages/wallet_detail_page.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Uji T-2.8 (FR-WAL-004, FR-REC-002): layar rincian dompet -- info dompet,
/// riwayat bulan berjalan yang tersaring ke dompet ini, jalan ke daftar
/// transaksi lengkap tersaring, dan pintasan CATAT dengan dompet ini sudah
/// terpilih.
void main() {
  late InMemoryKeyValueStorage storage;
  late WalletRepositoryImpl walletRepository;
  late TransactionRepositoryImpl transactionRepository;
  late GetIt container;

  setUpAll(registerEffectHandlers);

  setUp(() {
    storage = InMemoryKeyValueStorage();
    walletRepository = WalletRepositoryImpl(storage: storage);
    transactionRepository = TransactionRepositoryImpl(storage: storage);
    container = GetIt.asNewInstance()
      ..registerLazySingleton<BudgetRepository>(() => BudgetRepositoryImpl(storage: InMemoryKeyValueStorage()))
      ..registerLazySingleton<WalletRepository>(() => walletRepository)
      ..registerLazySingleton<TransactionRepository>(
        () => transactionRepository,
      );
  });

  Future<void> seedWallet(
    String id,
    String name, {
    int current = 0,
    String icon = 'walletBank',
  }) {
    return walletRepository.saveWallet(
      Wallet(
        id: id,
        name: name,
        iconKey: icon,
        initialBalance: current,
        currentBalance: current,
      ),
    );
  }

  /// Membuka shell, lalu tab Dompet, lalu kartu [walletName] -- ujung ke
  /// ujung sama seperti pengguna, bukan mem-push [WalletDetailPage] langsung.
  Future<void> openDetail(WidgetTester tester, String walletName) async {
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ScopeProvider(
        container: container,
        child: const MaterialApp(home: AppShellPage()),
      ),
    );
    // Tiga `pump()`: tiga ScopeWidget bersarang (Record, Transaction, Wallet).
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump(); // + ScopeWidget<BudgetScope> (T-4.5)
    await tester.tap(
      find.widgetWithText(NavigationDestination, t.appShell.walletsTabLabel),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(walletName));
    await tester.pumpAndSettle();
  }

  group('WalletDetailPage', () {
    testWidgets('menampilkan nama, ikon jenis, dan saldo tercatat dompet', (
      tester,
    ) async {
      await seedWallet('a', 'BCA', current: 130000000);
      await openDetail(tester, 'BCA');

      expect(find.byType(WalletDetailPage), findsOneWidget);
      expect(find.text('BCA'), findsWidgets);
      expect(find.text(t.wallet.typeBank.toUpperCase()), findsOneWidget);
      expect(find.text('Rp1.300.000'), findsWidgets);
    });

    testWidgets(
      'riwayat hanya transaksi bulan ini yang menyentuh dompet ini, bukan dompet lain',
      (tester) async {
        await seedWallet('a', 'BCA', current: 100000000);
        await seedWallet(
          'b',
          'GoPay',
          current: 50000000,
          icon: 'walletEwallet',
        );
        final now = DateTime.now();
        await transactionRepository.saveTransaction(
          ExpenseTransaction(
            id: 'e1',
            date: now,
            amount: 25000,
            note: 'kopi',
            walletId: 'a',
          ),
        );
        await transactionRepository.saveTransaction(
          ExpenseTransaction(
            id: 'e2',
            date: now,
            amount: 15000,
            note: 'parkir gopay',
            walletId: 'b',
          ),
        );
        await openDetail(tester, 'BCA');

        expect(find.text('kopi'), findsOneWidget);
        expect(
          find.text('parkir gopay'),
          findsNothing,
          reason: 'transaksi dompet lain tidak ikut tampil',
        );
      },
    );

    testWidgets(
      'belum ada transaksi bulan ini untuk dompet ini: ikon, judul, dan deskripsi',
      (tester) async {
        await seedWallet('a', 'BCA');
        await openDetail(tester, 'BCA');

        expect(find.text(t.wallet.detailRecentEmptyTitle), findsOneWidget);
        expect(find.text(t.wallet.detailRecentEmpty), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(WalletDetailPage),
            matching: find.byWidgetPredicate(
              (w) => w is AppIcon && w.iconKey == IconKey.transactions,
            ),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'ringkasan masuk/keluar/neto bulan ini -- transfer tidak ikut dihitung (aturan 7)',
      (tester) async {
        await seedWallet('a', 'BCA', current: 100000000);
        await seedWallet('b', 'GoPay', icon: 'walletEwallet');
        final now = DateTime.now();
        await transactionRepository.saveTransaction(
          IncomeTransaction(
            id: 'i1',
            date: now,
            amount: 500000000,
            note: '',
            walletId: 'a',
          ),
        );
        await transactionRepository.saveTransaction(
          ExpenseTransaction(
            id: 'e1',
            date: now,
            amount: 7500000,
            note: '',
            walletId: 'a',
          ),
        );
        await transactionRepository.saveTransaction(
          TransferTransaction(
            id: 't1',
            date: now,
            amount: 20000000,
            note: '',
            fromWalletId: 'a',
            toWalletId: 'b',
          ),
        );
        await openDetail(tester, 'BCA');

        expect(
          find.text(t.wallet.detailIncomeLabel.toUpperCase()),
          findsOneWidget,
        );
        expect(
          find.text(t.wallet.detailExpenseLabel.toUpperCase()),
          findsOneWidget,
        );
        expect(
          find.text(t.wallet.detailNetLabel.toUpperCase()),
          findsOneWidget,
        );
        expect(
          find.text('Rp5.000.000'),
          findsOneWidget,
          reason: 'masuk: hanya pemasukan',
        );
        expect(
          find.text('Rp75.000'),
          findsOneWidget,
          reason: 'keluar: hanya pengeluaran',
        );
        expect(
          find.text('+Rp4.925.000'),
          findsOneWidget,
          reason: 'neto = masuk - keluar, transfer Rp200.000 tidak ikut dihitung',
        );
      },
    );

    testWidgets('mengetuk transaksi terbaru membuka rincian transaksi', (
      tester,
    ) async {
      await seedWallet('a', 'BCA', current: 100000000);
      await transactionRepository.saveTransaction(
        ExpenseTransaction(
          id: 'e1',
          date: DateTime.now(),
          amount: 25000,
          note: 'kopi',
          walletId: 'a',
        ),
      );
      await openDetail(tester, 'BCA');

      await tester.tap(find.text('kopi'));
      await tester.pumpAndSettle();

      expect(find.byType(TransactionDetailPage), findsOneWidget);
    });

    testWidgets(
      'Lihat Semua Transaksi membuka daftar transaksi tersaring ke dompet ini',
      (tester) async {
        await seedWallet('a', 'BCA', current: 100000000);
        await seedWallet(
          'b',
          'GoPay',
          current: 50000000,
          icon: 'walletEwallet',
        );
        final now = DateTime.now();
        await transactionRepository.saveTransaction(
          ExpenseTransaction(
            id: 'e1',
            date: now,
            amount: 25000,
            note: 'kopi',
            walletId: 'a',
          ),
        );
        await transactionRepository.saveTransaction(
          ExpenseTransaction(
            id: 'e2',
            date: now,
            amount: 15000,
            note: 'parkir gopay',
            walletId: 'b',
          ),
        );
        await openDetail(tester, 'BCA');

        final cta = find.widgetWithText(
          AppButton,
          t.wallet.detailViewAllAction,
        );
        await tester.ensureVisible(cta);
        await tester.tap(cta);
        await tester.pumpAndSettle();

        expect(find.byType(TransactionListPage), findsOneWidget);
        expect(
          find.text('BCA'),
          findsWidgets,
          reason: 'label penyaring dompet menampilkan dompet terpilih',
        );
        expect(find.text('kopi'), findsOneWidget);
        expect(
          find.text('parkir gopay'),
          findsNothing,
          reason: 'daftar sudah tersaring ke BCA',
        );
      },
    );

    testWidgets('pintasan CATAT mengisi dompet ini sebagai awal (FR-REC-002)', (
      tester,
    ) async {
      await seedWallet('a', 'BCA', current: 100000000);
      await openDetail(tester, 'BCA');

      final cta = find.widgetWithText(AppButton, t.wallet.detailRecordAction);
      await tester.ensureVisible(cta);
      await tester.tap(cta);
      await tester.pumpAndSettle();

      expect(find.byType(RecordChoiceSheet), findsOneWidget);
      await tester.tap(find.text(t.record.expenseAction).first);
      await tester.pumpAndSettle();

      // Dompet sudah terisi tanpa disentuh -- prompt "belum dipilih" tidak
      // tampil, dan nama dompetnya sudah ada di formulir.
      expect(find.text(t.record.walletNotSelectedPrompt), findsNothing);
      expect(find.text('BCA'), findsWidgets);

      await tester.enterText(find.byType(TextField).first, '25000');
      await tester.pump();
      await tester.ensureVisible(
        find.widgetWithText(AppButton, t.record.expenseAction).last,
      );
      await tester.tap(
        find.widgetWithText(AppButton, t.record.expenseAction).last,
      );
      await tester.pumpAndSettle();

      final transactions = (await transactionRepository.listAllTransactions()).getOrElse(
        (_) => throw StateError('expected Right'),
      );
      expect(transactions.single, isA<ExpenseTransaction>());
      expect((transactions.single as ExpenseTransaction).walletId, 'a');
    });
  });
}
