import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/record/presentation/bloc/record_bloc.dart';
import 'package:saldough/features/record/presentation/widgets/expense_form_sheet.dart';
import 'package:saldough/features/record/presentation/widgets/transfer_form_sheet.dart';
import 'package:saldough/shared/capture/capture.dart';
import 'package:saldough/shared/wallet/wallet.dart';

import '../../../../helpers/categories.dart';

/// Formulir CATAT yang terisi draf Catat Cerdas (ADR-027 §3.4).
void main() {
  setUp(() => useCategories(['Makan']));

  const wallets = [
    Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 0, currentBalance: 500000000),
    Wallet(id: 'gopay', name: 'GoPay', iconKey: 'walletEwallet', initialBalance: 0, currentBalance: 100000000),
  ];

  Future<void> pumpSheet<T>(WidgetTester tester, Widget sheet, void Function(T?) onResult) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async => onResult(
                await showModalBottomSheet<T>(context: context, isScrollControlled: true, builder: (_) => sheet),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('draf pengeluaran mengisi nominal, dompet, kategori, catatan; Catat mengembalikan transaksi', (
    tester,
  ) async {
    ExpenseRecorded? result;
    await pumpSheet<ExpenseRecorded>(
      tester,
      const ExpenseFormSheet(
        wallets: wallets,
        draft: RecordDraft(
          kind: DraftKind.expense,
          amountSen: 3500000,
          walletId: 'bca',
          categoryId: 'Makan',
          note: 'makan siang',
          sourceText: 'Tadi makan siang 35 ribu pakai BCA',
        ),
      ),
      (r) => result = r,
    );

    // Draf tanpa masalah: kartu tidak tampil sama sekali (transkrip juga tidak).
    expect(find.text('“Tadi makan siang 35 ribu pakai BCA”'), findsNothing);
    expect(find.text(t.record.draftCheckTitle), findsNothing);
    expect(find.text('Rp35.000', findRichText: true), findsOneWidget);
    expect(find.text('makan siang'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('record-submit')));
    await tester.tap(find.byKey(const ValueKey('record-submit')));
    await tester.pumpAndSettle();

    expect(result?.amount, 3500000);
    expect(result?.walletId, 'bca');
    expect(result?.categoryId, 'Makan');
    expect(result?.note, 'makan siang');
  });

  testWidgets('dompet tidak dikenal: dompet dibiarkan kosong walau ada dompet bawaan, masalah ditampilkan', (
    tester,
  ) async {
    await pumpSheet<ExpenseRecorded>(
      tester,
      const ExpenseFormSheet(
        wallets: wallets,
        initialWalletId: 'bca',
        draft: RecordDraft(kind: DraftKind.expense, amountSen: 2000000, issues: {DraftIssue.walletUnknown}),
      ),
      (_) {},
    );

    expect(find.text(t.record.draftCheckTitle), findsOneWidget);
    expect(find.text(t.record.draftIssue.walletUnknown), findsOneWidget);
    expect(find.text(t.record.walletNotSelectedPrompt), findsOneWidget);
  });

  testWidgets('transfer "top up" tanpa dompet asal: asal kosong, tujuan terisi, tombol Catat mati', (tester) async {
    await pumpSheet<TransferRecorded>(
      tester,
      const TransferFormSheet(
        wallets: wallets,
        initialWalletId: 'bca',
        draft: RecordDraft(
          kind: DraftKind.transfer,
          amountSen: 10000000,
          toWalletId: 'gopay',
          issues: {DraftIssue.transferSourceMissing},
        ),
      ),
      (_) {},
    );

    expect(find.text(t.record.draftIssue.transferSourceMissing), findsOneWidget);
    expect(find.text('GoPay'), findsWidgets);
    final button = tester.widget<AppButton>(find.byType(AppButton));
    expect(button.onPressed, isNull);
  });
}
