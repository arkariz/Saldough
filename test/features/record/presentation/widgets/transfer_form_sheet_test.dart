import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/record/presentation/bloc/record_bloc.dart';
import 'package:saldough/features/record/presentation/widgets/transfer_form_sheet.dart';
import 'package:saldough/shared/wallet/wallet.dart';

void main() {
  const wallets = [
    Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 0, currentBalance: 500000000),
    Wallet(id: 'gopay', name: 'GoPay', iconKey: 'walletEwallet', initialBalance: 0, currentBalance: 0),
  ];

  Future<Widget> openSheet(WidgetTester tester, void Function(TransferRecorded?) onResult) async {
    final widget = MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              final result = await showModalBottomSheet<TransferRecorded>(
                context: context,
                builder: (_) => const TransferFormSheet(wallets: wallets),
              );
              onResult(result);
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.pumpWidget(widget);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return widget;
  }

  group('TransferFormSheet', () {
    testWidgets('tombol Catat nonaktif kalau dompet asal dan tujuan sama (FR-TXN-003)', (tester) async {
      TransferRecorded? result;
      await openSheet(tester, (r) => result = r);

      await tester.enterText(find.byType(TextField).first, '100000');
      // Kedua `WalletChipPicker` memiliki chip 'BCA · ...' -- pilih BCA untuk
      // asal (chip pertama) MAUPUN tujuan (chip pertama picker kedua).
      final bcaChips = find.widgetWithText(AppChip, 'BCA · Rp5.000.000');
      await tester.ensureVisible(bcaChips.at(0));
      await tester.tap(bcaChips.at(0));
      await tester.pump();
      await tester.ensureVisible(bcaChips.at(1));
      await tester.tap(bcaChips.at(1));
      await tester.pump();

      expect(find.byType(AppButton), findsOneWidget);
      final button = tester.widget<AppButton>(find.byType(AppButton));
      expect(button.onPressed, isNull);

      await tester.ensureVisible(find.byType(AppButton));
      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();
      expect(result, isNull);
    });

    testWidgets('mengembalikan TransferRecorded saat dompet asal dan tujuan berbeda', (tester) async {
      TransferRecorded? result;
      await openSheet(tester, (r) => result = r);

      await tester.enterText(find.byType(TextField).first, '100000');
      // Kedua WalletChipPicker (asal/tujuan) menampilkan wallets yang sama,
      // jadi 'BCA'/'GoPay' masing-masing muncul dua kali -- pilih lewat
      // indeks urutan render, bukan teks (yang ambigu di sini): [0]=BCA
      // (asal), [1]=GoPay (asal), [2]=BCA (tujuan), [3]=GoPay (tujuan).
      await tester.ensureVisible(find.byType(AppChip).at(0));
      await tester.tap(find.byType(AppChip).at(0));
      await tester.pump();
      await tester.ensureVisible(find.byType(AppChip).at(3));
      await tester.tap(find.byType(AppChip).at(3));
      await tester.pump();
      await tester.ensureVisible(find.byType(AppButton));
      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.fromWalletId, 'bca');
      expect(result!.toWalletId, 'gopay');
      expect(result!.amount, 10000000);
    });
  });
}
