import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/core/foundation/effect_handler/app_effect_registry.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/shell/app_shell_page.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/wallet/presentation/pages/wallet_list_page.dart';
import 'package:saldough/features/wallet/presentation/widgets/wallet_card.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

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
      ..registerLazySingleton<WalletRepository>(() => walletRepository)
      ..registerLazySingleton<TransactionRepository>(() => transactionRepository);
  });

  Future<void> seed(
    String id,
    String name, {
    int initial = 0,
    int? current,
    bool active = true,
    String icon = 'walletBank',
  }) {
    return walletRepository.saveWallet(
      Wallet(
        id: id,
        name: name,
        iconKey: icon,
        initialBalance: initial,
        currentBalance: current ?? initial,
        isActive: active,
      ),
    );
  }

  Future<List<Wallet>> stored() async =>
      (await walletRepository.listWallets()).getOrElse((_) => throw StateError('expected Right'));

  void tallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<void> openWalletsTab(WidgetTester tester) async {
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
    await tester.tap(find.widgetWithText(NavigationDestination, t.appShell.walletsTabLabel));
    await tester.pumpAndSettle();
  }

  Future<void> openForm(WidgetTester tester, {String? editing}) async {
    final target = editing == null
        ? find.widgetWithText(AppButton, t.wallet.addAction)
        : find.ancestor(of: find.text(editing), matching: find.byType(WalletCard));
    await tester.ensureVisible(target.first);
    await tester.tap(target.first);
    await tester.pumpAndSettle();
  }

  group('WalletListPage', () {
    testWidgets('belum ada dompet: keadaan kosong dengan ajakan menambah dompet pertama', (tester) async {
      await openWalletsTab(tester);

      expect(find.text(t.wallet.emptyTitle), findsOneWidget);
      expect(find.widgetWithText(AppButton, t.wallet.addAction), findsOneWidget);
    });

    testWidgets('menampilkan total saldo dompet AKTIF dan tiap dompet dengan saldonya', (tester) async {
      tallViewport(tester);
      await seed('a', 'BCA', current: 850000000);
      await seed('b', 'GoPay', current: 245000000, icon: 'walletEwallet');
      await seed('c', 'Lama', current: 999900000, active: false);
      await openWalletsTab(tester);

      expect(
        find.text('Rp10.950.000'),
        findsWidgets,
        reason: 'total = 8.500.000 + 2.450.000, dompet nonaktif tidak ikut',
      );
      expect(find.text(t.wallet.activeBadge(count: 2).toUpperCase()), findsOneWidget);
      expect(find.text('BCA'), findsOneWidget);
      expect(find.text('GoPay'), findsOneWidget);
      expect(find.text(t.wallet.typeBank.toUpperCase()), findsNWidgets(2), reason: 'BCA dan Lama sama-sama bank');
      expect(find.text(t.wallet.typeEwallet.toUpperCase()), findsOneWidget);
      expect(find.text(t.wallet.inactiveHeading.toUpperCase()), findsOneWidget);
      expect(find.text('Lama'), findsOneWidget);
    });

    testWidgets('saldo negatif tampil dengan tanda minus dan warna expense, bukan sebagai kesalahan (FR-WAL-003)', (
      tester,
    ) async {
      tallViewport(tester);
      await seed('a', 'Kartu', current: -12300000, icon: 'walletCard');
      await openWalletsTab(tester);

      final texts = tester.widgetList<Text>(find.text('−Rp123.000'));
      expect(texts, isNotEmpty);
      for (final text in texts) {
        expect(text.style?.color, AppColorsExtension.pixelLight.expense);
      }
    });

    testWidgets('menambah dompet: tersimpan dengan saldo awal, tampil di daftar, dan TANPA transaksi', (tester) async {
      tallViewport(tester);
      await openWalletsTab(tester);

      await openForm(tester);
      await tester.enterText(find.byType(TextField).first, 'Dompet Saku');
      await tester.tap(find.text(t.wallet.typeCash.toUpperCase()));
      await tester.tap(find.text('+500rb'));
      await tester.pump();
      await tester.tap(find.widgetWithText(AppButton, t.wallet.saveAddAction));
      await tester.pumpAndSettle();

      final wallets = await stored();
      expect(wallets.single.name, 'Dompet Saku');
      expect(wallets.single.iconKey, 'walletCash');
      expect(wallets.single.initialBalance, 50000000);
      expect(wallets.single.currentBalance, 50000000);
      expect(find.text('Dompet Saku'), findsOneWidget);
      expect(find.text(t.wallet.savedMessage), findsOneWidget);
      final transactions = (await transactionRepository.listAllTransactions()).getOrElse((_) => throw StateError('x'));
      expect(transactions, isEmpty, reason: 'saldo awal bukan transaksi setoran');
    });

    testWidgets('menyunting nama tidak mengubah saldo; daftar ikut berubah', (tester) async {
      tallViewport(tester);
      await seed('a', 'BCA', initial: 100000000, current: 130000000);
      await openWalletsTab(tester);

      await openForm(tester, editing: 'BCA');
      await tester.enterText(find.byType(TextField).first, 'BCA Utama');
      await tester.pump();
      await tester.tap(find.widgetWithText(AppButton, t.transaction.saveChangesAction));
      await tester.pumpAndSettle();

      final wallet = (await stored()).single;
      expect(wallet.name, 'BCA Utama');
      expect(wallet.initialBalance, 100000000);
      expect(wallet.currentBalance, 130000000);
      expect(find.text('BCA Utama'), findsOneWidget);
      expect(find.text(t.wallet.updatedMessage), findsOneWidget);
    });

    testWidgets('mengganti saldo awal menghitung ulang saldo tercatat dari transaksi yang ada', (tester) async {
      tallViewport(tester);
      await seed('a', 'BCA', current: 10000000);
      await transactionRepository.saveTransaction(
        IncomeTransaction(id: 'i1', date: DateTime(2026, 9, 5), amount: 10000000, note: '', walletId: 'a'),
      );
      await openWalletsTab(tester);

      await openForm(tester, editing: 'BCA');
      await tester.tap(find.text('+1jt'));
      await tester.pump();
      await tester.tap(find.widgetWithText(AppButton, t.transaction.saveChangesAction));
      await tester.pumpAndSettle();

      final wallet = (await stored()).single;
      expect(wallet.initialBalance, 100000000);
      expect(wallet.currentBalance, 110000000);
      expect(find.text('Rp1.100.000'), findsWidgets);
    });

    testWidgets('menonaktifkan dompet memindahkannya ke bagian nonaktif dan mengeluarkannya dari total', (
      tester,
    ) async {
      tallViewport(tester);
      await seed('a', 'BCA', current: 100000000);
      await seed('b', 'GoPay', current: 50000000, icon: 'walletEwallet');
      await openWalletsTab(tester);
      expect(find.text('Rp1.500.000'), findsWidgets);

      await openForm(tester, editing: 'GoPay');
      await tester.ensureVisible(find.byType(Switch));
      await tester.tap(find.byType(Switch));
      await tester.pump();
      await tester.tap(find.widgetWithText(AppButton, t.transaction.saveChangesAction));
      await tester.pumpAndSettle();

      expect(find.text(t.wallet.inactiveHeading.toUpperCase()), findsOneWidget);
      expect(find.text(t.wallet.activeBadge(count: 1).toUpperCase()), findsOneWidget);
      expect(find.text('Rp1.000.000'), findsWidgets, reason: 'total kini hanya BCA');
    });

    testWidgets('menghapus dompet kosong lewat konfirmasi: hilang, dan kembali ke keadaan kosong', (tester) async {
      tallViewport(tester);
      await seed('a', 'Salah Buat');
      await openWalletsTab(tester);

      await openForm(tester, editing: 'Salah Buat');
      await tester.ensureVisible(find.widgetWithText(AppButton, t.wallet.deleteAction));
      await tester.tap(find.widgetWithText(AppButton, t.wallet.deleteAction));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, t.common.delete));
      await tester.pumpAndSettle();

      expect(await stored(), isEmpty);
      expect(find.text(t.wallet.emptyTitle), findsOneWidget);
      expect(find.text(t.wallet.deletedMessage), findsOneWidget);
    });

    testWidgets('dompet yang sudah punya transaksi TIDAK terhapus: ada pesan, dompet tetap', (tester) async {
      tallViewport(tester);
      await seed('a', 'BCA', current: 10000000);
      await transactionRepository.saveTransaction(
        IncomeTransaction(id: 'i1', date: DateTime(2026, 9, 5), amount: 10000000, note: '', walletId: 'a'),
      );
      await openWalletsTab(tester);

      await openForm(tester, editing: 'BCA');
      await tester.ensureVisible(find.widgetWithText(AppButton, t.wallet.deleteAction));
      await tester.tap(find.widgetWithText(AppButton, t.wallet.deleteAction));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, t.common.delete));
      await tester.pumpAndSettle();

      expect((await stored()).map((w) => w.id), ['a']);
      expect(find.text(t.wallet.deleteBlockedMessage), findsOneWidget);
    });

    testWidgets('membuka tab Dompet lagi menyegarkan saldo yang berubah di tempat lain', (tester) async {
      tallViewport(tester);
      await seed('a', 'BCA', current: 100000000);
      await openWalletsTab(tester);
      expect(find.text('Rp1.000.000'), findsWidgets);

      // Saldo berubah di luar layar ini (mis. transaksi disunting di tab Transaksi).
      await walletRepository.saveWallet(
        const Wallet(id: 'a', name: 'BCA', iconKey: 'walletBank', initialBalance: 0, currentBalance: 250000000),
      );
      await tester.tap(find.widgetWithText(NavigationDestination, t.appShell.transactionsTabLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(NavigationDestination, t.appShell.walletsTabLabel));
      await tester.pumpAndSettle();

      expect(find.text('Rp2.500.000'), findsWidgets);
    });

    testWidgets('layar 360px + teks 2x + nama panjang + saldo besar: tidak overflow, nama tidak dielipsis', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 3200);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(() {
        tester.view.reset();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });
      const longName = 'Rekening Bank Central Asia';
      await seed('a', longName, current: 123456789000);
      await seed('b', 'Kartu', current: -99999999900, icon: 'walletCard');
      await openWalletsTab(tester);

      expect(tester.takeException(), isNull);
      final name = tester.widget<Text>(find.text(longName));
      expect(name.overflow, isNot(TextOverflow.ellipsis));
    });

    testWidgets('halaman memakai bahasa pencatatan: tidak ada kosakata yang menyiratkan memindahkan uang', (
      tester,
    ) async {
      tallViewport(tester);
      await seed('a', 'BCA', current: 100);
      await openWalletsTab(tester);

      const forbidden = ['kirim uang', 'transfer sekarang', 'sinkron otomatis', 'hubungkan bank'];
      final texts = tester
          .widgetList<Text>(find.descendant(of: find.byType(WalletListPage), matching: find.byType(Text)))
          .map((w) => (w.data ?? w.textSpan?.toPlainText() ?? '').toLowerCase());
      for (final text in texts) {
        for (final word in forbidden) {
          expect(text.contains(word), isFalse, reason: '"$text" memuat "$word"');
        }
      }
    });
  });
}
