import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/transaction/transaction_presentation.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Baris dan kelompok harian Riwayat (T-14.7, pola Daftar design system).
void main() {
  const wallets = {
    'bca': Wallet(
      id: 'bca',
      name: 'BCA',
      iconKey: 'walletBank',
      initialBalance: 0,
      currentBalance: 0,
    ),
    'cash': Wallet(
      id: 'cash',
      name: 'Tunai',
      iconKey: 'walletCash',
      initialBalance: 0,
      currentBalance: 0,
    ),
  };
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  setUp(
    () => ActiveCategories.notifier.value = const [
      Category(
        id: 'food',
        kind: CategoryKind.expense,
        name: 'Makan & Minum',
        builtInKey: 'food',
      ),
    ],
  );
  tearDown(() => ActiveCategories.notifier.value = const []);

  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      theme: PixelTheme.light,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );

  testWidgets(
    'judul = catatan (kategori bila kosong), subjudul "Dompet · jam", nominal bertanda',
    (tester) async {
      final group = TransactionDateGroup(
        date: today,
        netSen: -9500000,
        transactions: [
          ExpenseTransaction(
            id: 'a',
            date: today.add(const Duration(hours: 8)),
            amount: 4500000,
            note: 'Kopi susu',
            walletId: 'cash',
            categoryId: 'food',
          ),
          ExpenseTransaction(
            id: 'b',
            date: today.add(const Duration(hours: 12)),
            amount: 5000000,
            note: '',
            walletId: 'bca',
            categoryId: 'food',
          ),
          TransferTransaction(
            id: 'c',
            date: today.add(const Duration(hours: 17, minutes: 30)),
            amount: 30000000,
            note: 'Tarik tunai',
            fromWalletId: 'bca',
            toWalletId: 'cash',
          ),
        ],
      );
      await pump(
        tester,
        TransactionDateGroupCard(group: group, walletsById: wallets),
      );

      expect(find.text('Kopi susu'), findsOneWidget);
      expect(find.text('Makan & Minum'), findsOneWidget);
      expect(find.text('Tunai · 08.00'), findsOneWidget);
      expect(find.text('BCA → Tunai · 17.30'), findsOneWidget);
      expect(find.text('−Rp45.000'), findsOneWidget);
      expect(find.text('Rp300.000'), findsOneWidget);
      // Kepala: hari ini + selisih tanpa transfer.
      expect(
        find.textContaining('${t.transaction.todayLabel} · '),
        findsOneWidget,
      );
      expect(find.text('−Rp95.000'), findsOneWidget);
      // Satu kartu daftar, pemisah menjorok.
      expect(find.byType(AppListCard), findsOneWidget);
      expect(find.byType(Divider), findsNWidgets(2));
      // Kopi memakai ikon kopi (varian judul).
      expect(
        find.byWidgetPredicate(
          (w) => w is AppIconTile && w.icon == IconKey.categoryCoffee,
        ),
        findsOneWidget,
      );
    },
  );

  test('label hari: Kemarin dan hari lain bernama hari', () {
    final yesterday = today.subtract(const Duration(days: 1));
    expect(
      TransactionDateGroupCard.dayLabel(yesterday),
      startsWith('${t.transaction.yesterdayLabel} · '),
    );
    final older = today.subtract(const Duration(days: 5));
    expect(TransactionDateGroupCard.dayLabel(older), isNot(contains('·')));
  });
}
