import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/record/presentation/bloc/record_bloc.dart';
import 'package:saldough/features/record/presentation/widgets/transfer_form_sheet.dart';
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
    Wallet(
      id: 'gopay',
      name: 'GoPay',
      iconKey: 'walletEwallet',
      initialBalance: 0,
      currentBalance: 0,
    ),
  ];

  Future<Widget> openSheet(
    WidgetTester tester,
    void Function(TransferRecorded?) onResult,
  ) async {
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
    testWidgets(
      'tombol Catat nonaktif kalau dompet asal dan tujuan sama (FR-TXN-003)',
      (tester) async {
        TransferRecorded? result;
        await openSheet(tester, (r) => result = r);

        await tester.enterText(find.byType(TextField).first, '100000');
        await tester.pump();
        // Kedua `WalletPickerField` (asal/tujuan) sama-sama menampilkan
        // "belum dipilih" mula-mula -- ketuk yang pertama (asal), pilih BCA di
        // lembar pemilihnya, lalu ketuk sisanya (satu-satunya yang belum
        // dipilih sekarang, yaitu tujuan) dan pilih BCA lagi supaya sama
        // dengan asal.
        await tester.ensureVisible(
          find.text(t.record.walletNotSelectedPrompt).first,
        );
        await tester.tap(find.text(t.record.walletNotSelectedPrompt).first);
        await tester.pumpAndSettle();
        // `.last` -- di dalam lembar pemilih adalah kemunculan TERBARU nama
        // dompet ini di pohon widget (lembar sebelumnya masih ada di baliknya).
        await tester.tap(find.text('BCA').last);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text(t.record.walletNotSelectedPrompt));
        await tester.tap(find.text(t.record.walletNotSelectedPrompt));
        await tester.pumpAndSettle();
        await tester.tap(find.text('BCA').last);
        await tester.pumpAndSettle();

        expect(find.byType(AppButton), findsOneWidget);
        final button = tester.widget<AppButton>(find.byType(AppButton));
        expect(button.onPressed, isNull);

        await tester.ensureVisible(find.byType(AppButton));
        await tester.tap(find.byType(AppButton));
        await tester.pumpAndSettle();
        expect(result, isNull);
      },
    );

    testWidgets(
      'mengembalikan TransferRecorded saat dompet asal dan tujuan berbeda',
      (tester) async {
        TransferRecorded? result;
        await openSheet(tester, (r) => result = r);

        await tester.enterText(find.byType(TextField).first, '100000');
        await tester.pump();
        // Field pertama (asal) -> BCA, field kedua (tujuan) -> GoPay.
        await tester.ensureVisible(
          find.text(t.record.walletNotSelectedPrompt).first,
        );
        await tester.tap(find.text(t.record.walletNotSelectedPrompt).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('BCA').last);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text(t.record.walletNotSelectedPrompt));
        await tester.tap(find.text(t.record.walletNotSelectedPrompt));
        await tester.pumpAndSettle();
        await tester.tap(find.text('GoPay').last);
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.byType(AppButton));
        await tester.tap(find.byType(AppButton));
        await tester.pumpAndSettle();

        expect(result, isNotNull);
        expect(result!.fromWalletId, 'bca');
        expect(result!.toWalletId, 'gopay');
        expect(result!.amount, 10000000);
      },
    );

    testWidgets(
      'initialWalletId mengisi dompet ASAL awal, tujuan masih perlu dipilih (FR-REC-002)',
      (tester) async {
        TransferRecorded? result;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    result = await showModalBottomSheet<TransferRecorded>(
                      context: context,
                      builder: (_) => const TransferFormSheet(
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
          reason: 'dompet ASAL sudah terisi tanpa disentuh',
        );
        expect(
          find.text(t.record.walletNotSelectedPrompt),
          findsOneWidget,
          reason: 'dompet TUJUAN masih kosong',
        );

        await tester.enterText(find.byType(TextField).first, '100000');
        await tester.pump();
        await tester.ensureVisible(find.text(t.record.walletNotSelectedPrompt));
        await tester.tap(find.text(t.record.walletNotSelectedPrompt));
        await tester.pumpAndSettle();
        await tester.tap(find.text('GoPay').last);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byType(AppButton));
        await tester.tap(find.byType(AppButton));
        await tester.pumpAndSettle();

        expect(result?.fromWalletId, 'bca');
        expect(result?.toWalletId, 'gopay');
      },
    );
  });
}
