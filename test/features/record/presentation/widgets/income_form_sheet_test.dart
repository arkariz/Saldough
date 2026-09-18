import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/record/presentation/bloc/record_bloc.dart';
import 'package:saldough/features/record/presentation/widgets/income_form_sheet.dart';
import 'package:saldough/shared/wallet/wallet.dart';

void main() {
  const wallets = [
    Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 0, currentBalance: 500000000),
  ];

  Future<IncomeRecorded?> pumpAndSubmit(WidgetTester tester, {required String amount, bool selectWallet = true}) async {
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
    if (selectWallet) {
      await tester.tap(find.byType(AppChip).first);
    }
    await tester.pump();
    await tester.ensureVisible(find.byType(AppButton));
    await tester.tap(find.byType(AppButton));
    await tester.pumpAndSettle();
    return result;
  }

  group('IncomeFormSheet', () {
    testWidgets('tombol Catat nonaktif sebelum dompet dipilih', (tester) async {
      final result = await pumpAndSubmit(tester, amount: '50000', selectWallet: false);
      expect(result, isNull);
    });

    testWidgets('tombol Catat nonaktif untuk nominal nol', (tester) async {
      final result = await pumpAndSubmit(tester, amount: '0');
      expect(result, isNull);
    });

    testWidgets('mengembalikan IncomeRecorded dengan nominal dikonversi ke sen', (tester) async {
      final result = await pumpAndSubmit(tester, amount: '50000');
      expect(result, isNotNull);
      expect(result!.walletId, 'bca');
      expect(result.amount, 5000000);
    });
  });
}
