import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/record/presentation/bloc/record_bloc.dart';
import 'package:saldough/features/record/presentation/widgets/income_form_sheet.dart';
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

  Future<IncomeRecorded?> pumpAndSubmit(
    WidgetTester tester, {
    required String amount,
    bool selectWallet = true,
  }) async {
    IncomeRecorded? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showModalBottomSheet<IncomeRecorded>(
                  context: context,
                  builder: (_) => const IncomeFormSheet(wallets: wallets),
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

    await tester.enterText(find.byType(TextField).first, amount);
    await tester.pump();
    if (selectWallet) {
      // Daftar dompet terbuka (bukan lembar pemilih): ketuk barisnya langsung.
      await tester.ensureVisible(find.text(t.record.walletNotSelectedPrompt));
      await tester.tap(find.text(t.record.walletNotSelectedPrompt));
      await tester.pumpAndSettle();
      await tester.tap(find.text(wallets.first.name).last);
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.byType(AppButton));
    await tester.tap(find.byType(AppButton));
    await tester.pumpAndSettle();
    return result;
  }

  group('IncomeFormSheet', () {
    testWidgets('tombol Catat nonaktif sebelum dompet dipilih', (tester) async {
      final result = await pumpAndSubmit(
        tester,
        amount: '50000',
        selectWallet: false,
      );
      expect(result, isNull);
    });

    testWidgets('tombol Catat nonaktif untuk nominal nol', (tester) async {
      final result = await pumpAndSubmit(tester, amount: '0');
      expect(result, isNull);
    });

    testWidgets(
      'mengembalikan IncomeRecorded dengan nominal dikonversi ke sen',
      (tester) async {
        final result = await pumpAndSubmit(tester, amount: '50000');
        expect(result, isNotNull);
        expect(result!.walletId, 'bca');
        expect(result.amount, 5000000);
      },
    );

    testWidgets(
      'initialWalletId mengisi dompet tujuan awal tanpa perlu memilih (FR-REC-002)',
      (tester) async {
        IncomeRecorded? result;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    result = await showModalBottomSheet<IncomeRecorded>(
                      context: context,
                      builder: (_) => const IncomeFormSheet(
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

        await tester.enterText(find.byType(TextField).first, '50000');
        await tester.pump();
        await tester.ensureVisible(find.byType(AppButton));
        await tester.tap(find.byType(AppButton));
        await tester.pumpAndSettle();

        expect(result?.walletId, 'bca');
      },
    );
  });
}
