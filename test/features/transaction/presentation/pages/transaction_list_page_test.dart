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
import 'package:saldough/features/budget/data/repositories/budget_repository_impl.dart';
import 'package:saldough/features/budget/domain/repositories/budget_repository.dart';
import 'package:saldough/features/record/domain/budget_item_catalog.dart';
import 'package:saldough/features/record/presentation/widgets/record_choice_sheet.dart';
import 'package:saldough/features/transaction/presentation/pages/transaction_detail_page.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

import '../../../../helpers/mocks.dart';

/// Dobel gagal untuk [WalletRepository] -- lihat `app_shell_page_test.dart`.
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
  late TransactionRepositoryImpl transactionRepository;
  late GetIt container;

  setUpAll(registerEffectHandlers);

  setUp(() {
    storage = InMemoryKeyValueStorage();
    walletRepository = WalletRepositoryImpl(storage: storage);
    transactionRepository = TransactionRepositoryImpl(storage: storage);
    container = GetIt.asNewInstance()
      ..registerLazySingleton<BudgetRepository>(() => BudgetRepositoryImpl(storage: InMemoryKeyValueStorage()))
      ..registerLazySingleton<BudgetItemCatalog>(FakeBudgetItemCatalog.new)
      ..registerLazySingleton<WalletRepository>(() => walletRepository)
      ..registerLazySingleton<TransactionRepository>(() => transactionRepository);
  });

  Widget pumpableShell() {
    return ScopeProvider(
      container: container,
      child: const MaterialApp(home: AppShellPage()),
    );
  }

  Future<void> openTransactionsTab(WidgetTester tester) async {
    await tester.pumpWidget(pumpableShell());
    await tester.pump();
    // Dua `pump()` -- ScopeWidget<TransactionScope> bersarang setelah
    // ScopeWidget<RecordScope>, jadi initialisasi async-nya baru mulai satu
    // frame setelah RecordScope selesai; satu `pump()` saja belum cukup.
    await tester.pump();
    // Tiga `pump()` -- ScopeWidget<WalletScope> (T-2.7) bersarang setelah
    // TransactionScope, jadi initialisasinya baru mulai satu frame lagi.
    await tester.pump();
    await tester.pump(); // + ScopeWidget<BudgetScope> (T-4.5)
    await tester.tap(find.widgetWithText(NavigationDestination, t.appShell.transactionsTabLabel));
    await tester.pumpAndSettle();
  }

  group('TransactionListPage', () {
    testWidgets('bulan berjalan genuinely belum ada transaksi menampilkan keadaan kosong bulan', (tester) async {
      await openTransactionsTab(tester);

      expect(find.text(t.transaction.emptyMonthTitle), findsOneWidget);
      expect(find.text(t.transaction.emptyFilterTitle), findsNothing);
      // Rujukan visual `pixel_kas_riwayat_transaksi_kosong`: baris filter
      // jenis tetap tampil (dengan angka nol) di keadaan kosong, dan kartu
      // "Panduan Catatan Kas" muncul di bawah kartu CATAT -- keduanya
      // sempat hilang total di versi sebelumnya.
      expect(find.text(t.transaction.allFilterLabel(count: 0)), findsOneWidget);
      expect(find.text(t.transaction.emptyGuideTitle), findsOneWidget);
      expect(find.text(t.transaction.emptyGuideIncomeTitle.toUpperCase()), findsOneWidget);
      expect(find.text(t.transaction.emptyGuideExpenseTitle.toUpperCase()), findsOneWidget);
      expect(find.text(t.transaction.emptyGuideTransferTitle.toUpperCase()), findsOneWidget);
      expect(find.text(t.transaction.trustFooterMessage), findsOneWidget);
    });

    testWidgets('filter yang menyisakan nol hasil menampilkan keadaan kosong filter, BUKAN keadaan kosong bulan', (
      tester,
    ) async {
      await walletRepository.saveWallet(
        const Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 0, currentBalance: 0),
      );
      final now = DateTime.now();
      await transactionRepository.saveTransaction(
        ExpenseTransaction(id: 'e1', date: now, amount: 30000, note: 'kopi', walletId: 'bca'),
      );

      await openTransactionsTab(tester);
      expect(find.text(t.transaction.emptyMonthTitle), findsNothing);

      await tester.tap(find.text(t.transaction.incomeFilterLabel(count: 0)));
      await tester.pumpAndSettle();

      expect(find.text(t.transaction.emptyFilterTitle), findsOneWidget);
      expect(find.text(t.transaction.emptyMonthTitle), findsNothing);
    });

    testWidgets('kegagalan pembacaan menampilkan keadaan galat, bukan keadaan kosong', (tester) async {
      final failingContainer = GetIt.asNewInstance()
        ..registerLazySingleton<BudgetRepository>(() => BudgetRepositoryImpl(storage: InMemoryKeyValueStorage()))
        ..registerLazySingleton<BudgetItemCatalog>(FakeBudgetItemCatalog.new)
        ..registerLazySingleton<WalletRepository>(_FailingWalletRepository.new)
        ..registerLazySingleton<TransactionRepository>(() => transactionRepository);

      await tester.pumpWidget(
        ScopeProvider(
          container: failingContainer,
          child: const MaterialApp(home: AppShellPage()),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(); // + ScopeWidget<BudgetScope> (T-4.5)
      await tester.pump(); // WalletScope (T-2.7), bersarang setelah TransactionScope.
      await tester.tap(find.widgetWithText(NavigationDestination, t.appShell.transactionsTabLabel));
      await tester.pumpAndSettle();

      expect(find.text(t.transaction.loadErrorTitle), findsOneWidget);
      expect(find.text(t.transaction.emptyMonthTitle), findsNothing);
    });

    testWidgets(
      'CTA keadaan kosong bulan membuka alur CATAT sungguhan (uji pengawatan penuh)',
      (tester) async {
        await openTransactionsTab(tester);
        expect(find.text(t.transaction.emptyMonthTitle), findsOneWidget);

        // Header ikut menggulir bersama isi, jadi CTA bisa berada di bawah
        // layar pada viewport pendek -- gulir dulu seperti pengguna.
        final cta = find.widgetWithText(AppButton, t.transaction.emptyMonthCta);
        await tester.ensureVisible(cta);
        await tester.pumpAndSettle();
        await tester.tap(cta);
        await tester.pumpAndSettle();

        expect(find.byType(RecordChoiceSheet), findsOneWidget);
        expect(find.text(t.record.incomeAction), findsWidgets);
      },
    );
  });

  group('TransactionDetailPage (T-2.11) dan sunting/hapus (T-2.6)', () {
    // Viewport tinggi supaya seluruh layar rincian terbangun tanpa menggulir.
    void useTallViewport(WidgetTester tester) {
      tester.view.physicalSize = const Size(800, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    Future<void> seedWallet(String id, String name, {int initial = 100000000}) async {
      await walletRepository.saveWallet(
        Wallet(id: id, name: name, iconKey: 'walletBank', initialBalance: initial, currentBalance: initial),
      );
    }

    Future<void> recompute(Set<String> ids) => RecomputeWalletBalances(
      walletRepository: walletRepository,
      transactionRepository: transactionRepository,
    ).forWallets(ids);

    Future<int> balanceOf(String id) async {
      final wallets = (await walletRepository.listWallets()).fold<List<Wallet>>((_) => [], (r) => r);
      return wallets.firstWhere((w) => w.id == id).currentBalance;
    }

    Future<void> seedExpense() async {
      await seedWallet('bca', 'BCA');
      await transactionRepository.saveTransaction(
        ExpenseTransaction(
          id: 'e1',
          date: DateTime.now(),
          amount: 7500000,
          note: 'nasi padang',
          walletId: 'bca',
          categoryKey: 'Makan Siang',
        ),
      );
      await recompute({'bca'});
    }

    testWidgets('mengetuk baris membuka rincian: jenis, nominal, kategori, dompet + saldo, tanggal, catatan', (
      tester,
    ) async {
      useTallViewport(tester);
      await seedExpense();
      await openTransactionsTab(tester);

      await tester.tap(find.text('Makan Siang'));
      await tester.pumpAndSettle();

      expect(find.byType(TransactionDetailPage), findsOneWidget);
      expect(find.text(t.transaction.detailExpenseTitle.toUpperCase()), findsOneWidget);
      expect(find.text('−Rp75.000'), findsWidgets);
      expect(find.text(t.transaction.detailExpenseWalletLabel), findsOneWidget);
      expect(find.text('BCA'), findsOneWidget);
      expect(find.text('${t.transaction.detailCurrentBalance}: Rp925.000'), findsOneWidget);
      expect(find.text('“nasi padang”'), findsOneWidget);
      // Baris anggaran belum ada sebelum Fase 4: bagiannya tidak ditampilkan.
      expect(find.textContaining('Anggaran'), findsNothing);
    });

    testWidgets('transfer memakai judul "Transfer tercatat" dan Dari / Ke / Jumlah, tanpa kosakata terlarang', (
      tester,
    ) async {
      useTallViewport(tester);
      await seedWallet('bca', 'BCA');
      await seedWallet('gopay', 'GoPay', initial: 0);
      await transactionRepository.saveTransaction(
        TransferTransaction(
          id: 't1',
          date: DateTime.now(),
          amount: 5000000,
          note: 'top-up',
          fromWalletId: 'bca',
          toWalletId: 'gopay',
        ),
      );
      await recompute({'bca', 'gopay'});
      await openTransactionsTab(tester);

      await tester.tap(find.text('top-up'));
      await tester.pumpAndSettle();

      expect(find.text(t.transaction.detailTransferTitle.toUpperCase()), findsOneWidget);
      expect(find.text(t.transaction.detailFromLabel.toUpperCase()), findsOneWidget);
      expect(find.text(t.transaction.detailToLabel.toUpperCase()), findsOneWidget);
      expect(find.text(t.transaction.detailAmountLabel), findsOneWidget);
      expect(find.text('−Rp50.000'), findsOneWidget);
      expect(find.text('+Rp50.000'), findsOneWidget);

      // FR-TXN-006: aplikasi hanya mencatat, tidak pernah "menjalankan".
      const forbidden = ['transfer berhasil', 'pembayaran berhasil', 'kirim uang', 'transfer successful'];
      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((w) => (w.data ?? w.textSpan?.toPlainText() ?? '').toLowerCase());
      for (final text in texts) {
        for (final word in forbidden) {
          expect(text.contains(word), isFalse, reason: '"$text" memuat kosakata terlarang "$word"');
        }
      }
    });

    testWidgets(
      'kartu Dari/Ke: nama dompet sangat panjang, layar sempit, dan teks 2x TIDAK overflow maupun terpotong',
      (
        tester,
      ) async {
        tester.view.physicalSize = const Size(360, 3200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        const fromName = 'Rekening Bank Central Asia Utama Pribadi Nomor Satu';
        const toName = 'Dompet Digital Belanja Online Bulanan Keluarga Besar';
        await seedWallet('bca', fromName);
        await seedWallet('gopay', toName, initial: 0);
        await transactionRepository.saveTransaction(
          TransferTransaction(
            id: 't1',
            date: DateTime.now(),
            amount: 123456789000,
            note: 'top-up',
            fromWalletId: 'bca',
            toWalletId: 'gopay',
          ),
        );
        await recompute({'bca', 'gopay'});
        await openTransactionsTab(tester);
        await tester.tap(find.text('top-up'));
        await tester.pumpAndSettle();

        // Teks besar diterapkan SETELAH rincian terbuka, supaya yang diuji hanya
        // layar rincian (bukan daftar di belakangnya).
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'tidak boleh ada RenderFlex overflow');
        for (final name in [fromName, toName]) {
          final finder = find.descendant(of: find.byType(TransactionDetailPage), matching: find.text(name));
          expect(finder, findsOneWidget, reason: '$name harus tampil utuh');
          final text = tester.widget<Text>(finder);
          expect(text.overflow, isNot(TextOverflow.ellipsis), reason: 'nama dompet tidak boleh dielipsis');
          expect(text.maxLines, isNull, reason: 'nama dompet boleh membungkus ke banyak baris');
        }
        // Nominal miliaran tetap tampil (diperkecil, bukan dipotong).
        expect(find.text('−Rp1.234.567.890'), findsOneWidget);
        expect(find.text('+Rp1.234.567.890'), findsOneWidget);
      },
    );

    testWidgets(
      'rincian pengeluaran: dompet, kategori, dan catatan sangat panjang pada layar sempit + teks 2x tidak overflow',
      (
        tester,
      ) async {
        tester.view.physicalSize = const Size(360, 4000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        const walletName = 'Rekening Bank Central Asia Utama Pribadi Nomor Satu';
        const category = 'Belanja Bulanan Kebutuhan Rumah Tangga dan Keluarga Besar';
        const note =
            'Belanja mingguan di supermarket dekat rumah untuk kebutuhan dapur, kamar mandi, dan acara keluarga';
        await seedWallet('bca', walletName);
        await transactionRepository.saveTransaction(
          ExpenseTransaction(
            id: 'e1',
            date: DateTime.now(),
            amount: 123456789000,
            note: note,
            walletId: 'bca',
            categoryKey: category,
          ),
        );
        await recompute({'bca'});
        await openTransactionsTab(tester);
        await tester.tap(find.text(category));
        await tester.pumpAndSettle();

        tester.platformDispatcher.textScaleFactorTestValue = 2;
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'tidak boleh ada RenderFlex overflow');
        final detail = find.byType(TransactionDetailPage);
        expect(find.descendant(of: detail, matching: find.text(walletName)), findsOneWidget);
        expect(find.descendant(of: detail, matching: find.text(category)), findsWidgets);
        expect(find.descendant(of: detail, matching: find.text('“$note”')), findsOneWidget);
      },
    );

    testWidgets('menghapus lewat konfirmasi menutup rincian, membuang baris, dan mengembalikan saldo dompet', (
      tester,
    ) async {
      useTallViewport(tester);
      await seedExpense();
      expect(await balanceOf('bca'), 92500000);
      await openTransactionsTab(tester);
      await tester.tap(find.text('Makan Siang'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(t.transaction.deleteAction.toUpperCase()));
      await tester.pumpAndSettle();
      expect(find.text(t.transaction.deleteConfirmTitle), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, t.common.delete));
      await tester.pumpAndSettle();

      expect(find.byType(TransactionDetailPage), findsNothing);
      expect(find.text('Makan Siang'), findsNothing);
      expect(find.text(t.transaction.deletedMessage), findsOneWidget);
      expect(await balanceOf('bca'), 100000000, reason: 'saldo kembali ke keadaan sebelum transaksi ada');
    });

    testWidgets('membatalkan konfirmasi hapus tidak menghapus apa pun', (tester) async {
      useTallViewport(tester);
      await seedExpense();
      await openTransactionsTab(tester);
      await tester.tap(find.text('Makan Siang'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(t.transaction.deleteAction.toUpperCase()));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, t.common.cancel));
      await tester.pumpAndSettle();

      expect(find.byType(TransactionDetailPage), findsOneWidget);
      expect(await balanceOf('bca'), 92500000);
    });

    testWidgets('sunting memakai formulir yang sama, terisi awal, dan menyimpan perubahan + saldo baru', (
      tester,
    ) async {
      useTallViewport(tester);
      await seedExpense();
      await openTransactionsTab(tester);
      await tester.tap(find.text('Makan Siang'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(AppButton, t.transaction.editAction));
      await tester.pumpAndSettle();

      expect(find.text(t.transaction.editSheetTitle), findsOneWidget);
      expect(find.text('75.000'), findsOneWidget, reason: 'nominal terisi awal, berpemisah ribuan');
      // Pratinjau saldo memakai saldo SEBELUM transaksi ini (Rp1.000.000), bukan
      // saldo sekarang yang sudah dikurangi -- kalau tidak, 75.000 dipotong dua
      // kali (925.000 -> 850.000).
      expect(find.text('Rp1.000.000'), findsOneWidget);
      expect(find.text('Rp925.000'), findsOneWidget);
      expect(find.text('Rp850.000'), findsNothing);

      await tester.enterText(find.byType(TextField).first, '90000');
      await tester.pump();
      await tester.ensureVisible(find.widgetWithText(AppButton, t.transaction.saveChangesAction));
      await tester.tap(find.widgetWithText(AppButton, t.transaction.saveChangesAction));
      await tester.pumpAndSettle();

      expect(find.byType(TransactionDetailPage), findsNothing);
      expect(find.text('−Rp90.000'), findsWidgets);
      expect(find.text(t.transaction.updatedMessage), findsOneWidget);
      expect(await balanceOf('bca'), 91000000);
      final all = (await transactionRepository.listAllTransactions()).fold<List<Transaction>>((_) => [], (r) => r);
      expect(all, hasLength(1), reason: 'menimpa transaksi lama, tidak mencatat transaksi penyeimbang');
    });
  });
}
