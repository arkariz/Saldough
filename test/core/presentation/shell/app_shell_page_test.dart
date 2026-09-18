import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/core/foundation/effect_handler/app_effect_registry.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/shell/app_shell_page.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

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
    return ScopeProvider(container: container, child: const MaterialApp(home: AppShellPage()));
  }

  group('AppShellPage', () {
    testWidgets('menampilkan lima tujuan navigasi dengan CATAT di tengah', (tester) async {
      await tester.pumpWidget(pumpableShell());
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

      expect(find.widgetWithText(AppBar, t.appShell.homeTabLabel), findsOneWidget);
      final nav = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(nav.selectedIndex, 0);
    });

    testWidgets('menekan tujuan Dompet berpindah ke tab Dompet, melompati CATAT', (tester) async {
      await tester.pumpWidget(pumpableShell());
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

      await tester.tap(find.widgetWithText(NavigationDestination, t.appShell.transactionsTabLabel));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, t.appShell.transactionsTabLabel), findsOneWidget);
    });

    testWidgets('menekan CATAT membuka lembar tiga pilihan (FR-REC-001), TIDAK mengganti tab aktif', (tester) async {
      await tester.pumpWidget(pumpableShell());
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

      await tester.tap(find.widgetWithText(NavigationDestination, t.appShell.recordAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.record.incomeAction).first);
      await tester.pumpAndSettle();

      expect(find.text(t.record.toWalletFieldLabel), findsOneWidget);
      expect(find.text(t.record.amountFieldHint), findsOneWidget);
    });

    testWidgets('menutup lembar pilihan CATAT tanpa memilih kembali ke tab sebelumnya', (tester) async {
      await tester.pumpWidget(pumpableShell());
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

        await tester.tap(find.widgetWithText(NavigationDestination, t.appShell.recordAction));
        await tester.pumpAndSettle();
        await tester.tap(find.text(t.record.incomeAction).first);
        await tester.pumpAndSettle();

        await tester.enterText(find.widgetWithText(TextField, t.record.amountFieldHint), '75000');
        await tester.tap(find.widgetWithText(AppChip, 'BCA · Rp0'));
        await tester.pump();
        await tester.tap(find.widgetWithText(AppButton, t.record.incomeAction));
        await tester.pumpAndSettle();

        final wallets = (await walletRepository.listWallets()).getOrElse((_) => throw StateError('expected Right'));
        expect(wallets.single.currentBalance, 7500000);
      },
    );
  });
}
