import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/record/presentation/bloc/record_bloc.dart';
import 'package:saldough/features/record/presentation/widgets/expense_form_sheet.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

void main() {
  const wallets = [
    Wallet(
      id: 'bca',
      name: 'BCA',
      iconKey: 'walletBank',
      initialBalance: 0,
      currentBalance: 500000000,
    ),
  ];

  testWidgets(
    'mengembalikan ExpenseRecorded dengan nominal dikonversi ke sen',
    (tester) async {
      ExpenseRecorded? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showModalBottomSheet<ExpenseRecorded>(
                    context: context,
                    builder: (_) => const ExpenseFormSheet(wallets: wallets),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '75000');
      await tester.pump();
      // Daftar dompet terbuka (bukan lembar pemilih): ketuk barisnya langsung.
      // Dropdown dompet: buka lewat tombol "belum dipilih", ketuk itemnya.
      await tester.ensureVisible(find.text(t.record.walletNotSelectedPrompt));
      await tester.tap(find.text(t.record.walletNotSelectedPrompt));
      await tester.pumpAndSettle();
      await tester.tap(find.text(wallets.first.name).last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(AppButton));
      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.walletId, 'bca');
      expect(result!.amount, 7500000);
    },
  );

  testWidgets(
    'initialWalletId mengisi dompet asal awal tanpa perlu memilih (FR-REC-002)',
    (tester) async {
      ExpenseRecorded? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showModalBottomSheet<ExpenseRecorded>(
                    context: context,
                    builder: (_) => const ExpenseFormSheet(
                      wallets: wallets,
                      initialWalletId: 'bca',
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(
        find.text('BCA'),
        findsWidgets,
        reason: 'dompet sudah terisi tanpa disentuh',
      );
      expect(find.text(t.record.walletNotSelectedPrompt), findsNothing);

      await tester.enterText(find.byType(TextField).first, '75000');
      await tester.pump();
      await tester.ensureVisible(find.byType(AppButton));
      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();

      expect(result?.walletId, 'bca');
    },
  );

  Future<void> pumpForm(
    WidgetTester tester, {
    List<Wallet> wallets = wallets,
    ExpenseTransaction? initial,
  }) {
    tester.view.physicalSize = const Size(360, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExpenseFormSheet(wallets: wallets, initial: initial),
        ),
      ),
    );
  }

  group('ExpenseFormSheet -- tata letak rujukan visual', () {
    testWidgets(
      'semua bagian rujukan tampil: aturan kas, nominal, kategori, dompet, waktu, catatan',
      (tester) async {
        await pumpForm(tester);

        expect(find.text(t.record.expenseRuleTitle), findsOneWidget);
        expect(
          find.text(t.record.amountLabelExpense.toUpperCase()),
          findsOneWidget,
        );
        expect(
          find.text(t.record.categorySectionLabel.toUpperCase()),
          findsOneWidget,
        );
        expect(
          find.text(t.record.expenseWalletSectionLabel.toUpperCase()),
          findsOneWidget,
        );
        expect(
          find.text(t.record.dateFieldLabel.toUpperCase()),
          findsOneWidget,
        );
        expect(
          find.text(t.record.noteSectionLabel.toUpperCase()),
          findsOneWidget,
        );
        expect(find.text(t.record.footnote), findsOneWidget);
      },
    );

    testWidgets(
      'dropdown dompet menawarkan SEMUA dompet, sama seperti penyaring di layar Transaksi',
      (tester) async {
        await pumpForm(
          tester,
          wallets: const [
            Wallet(
              id: 'bca',
              name: 'BCA',
              iconKey: 'walletBank',
              initialBalance: 0,
              currentBalance: 500000000,
            ),
            Wallet(
              id: 'gopay',
              name: 'GoPay',
              iconKey: 'walletEwallet',
              initialBalance: 0,
              currentBalance: 100000,
            ),
          ],
        );

        expect(find.byType(AppMenuSelectButton<String>), findsWidgets);
        expect(
          find.text('BCA'),
          findsNothing,
          reason: 'menu tertutup sampai tombolnya diketuk',
        );

        await tester.tap(find.text(t.record.walletNotSelectedPrompt));
        await tester.pumpAndSettle();

        expect(find.text('BCA'), findsOneWidget);
        expect(find.text('GoPay'), findsOneWidget);
      },
    );

    testWidgets(
      'ringkasan + pratinjau saldo muncul setelah nominal dan dompet terisi',
      (tester) async {
        await pumpForm(tester);
        expect(find.textContaining('akan berkurang'), findsNothing);

        await tester.enterText(find.byType(TextField).first, '75000');
        await tester.pump();
        await tester.tap(find.text(t.record.walletNotSelectedPrompt));
        await tester.pumpAndSettle();
        await tester.tap(find.text('BCA').last);
        await tester.pumpAndSettle();
        await tester.pump();

        expect(
          find.text('Rp5.000.000'),
          findsOneWidget,
          reason: 'saldo lama (dicoret)',
        );
        expect(find.text('Rp4.925.000'), findsOneWidget, reason: 'saldo baru');
        expect(
          find.text(t.record.expenseSummary(wallet: 'BCA', amount: 'Rp75.000')),
          findsOneWidget,
        );
      },
    );

    testWidgets('mode sunting: judul, label langkah, tombol, dan isian awal', (
      tester,
    ) async {
      await pumpForm(
        tester,
        initial: ExpenseTransaction(
          id: 'e1',
          date: DateTime(2026, 9, 1, 8, 30),
          amount: 7500000,
          note: 'nasi padang',
          walletId: 'bca',
          categoryKey: 'Makan',
        ),
      );

      expect(find.text(t.transaction.editSheetTitle), findsOneWidget);
      expect(find.text(t.record.editStepLabel.toUpperCase()), findsOneWidget);
      expect(
        find.widgetWithText(AppButton, t.transaction.saveChangesAction),
        findsOneWidget,
      );
      expect(find.text('75.000'), findsOneWidget);
      expect(find.text('nasi padang'), findsOneWidget);
      expect(find.textContaining('08:30'), findsOneWidget);
    });

    testWidgets(
      'nama dompet sangat panjang + saldo besar + teks 2x + layar 360px: tidak overflow, nama tidak dielipsis',
      (
        tester,
      ) async {
        const longName = 'Rekening Bank Central Asia Utama Pribadi Nomor Satu';
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pumpForm(
          tester,
          wallets: const [
            Wallet(
              id: 'w',
              name: longName,
              iconKey: 'walletBank',
              initialBalance: 0,
              currentBalance: 123456789000,
            ),
          ],
        );

        await tester.enterText(find.byType(TextField).first, '99999999999');
        await tester.pump();
        await tester.tap(find.text(t.record.walletNotSelectedPrompt));
        await tester.pumpAndSettle();
        await tester.tap(find.text(longName).last);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        final name = tester.widgetList<Text>(find.text(longName)).first;
        expect(name.overflow, isNot(TextOverflow.ellipsis));
      },
    );
  });
}
