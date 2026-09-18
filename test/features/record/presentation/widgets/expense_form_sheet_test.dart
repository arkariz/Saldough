import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/record/presentation/bloc/record_bloc.dart';
import 'package:saldough/features/record/presentation/widgets/expense_form_sheet.dart';
import 'package:saldough/shared/wallet/wallet.dart';

void main() {
  const wallets = [
    Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 0, currentBalance: 500000000),
  ];

  testWidgets('mengembalikan ExpenseRecorded dengan nominal dikonversi ke sen', (tester) async {
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
    await tester.ensureVisible(find.text(t.record.walletNotSelectedPrompt));
    await tester.tap(find.text(t.record.walletNotSelectedPrompt));
    await tester.pumpAndSettle();
    await tester.tap(find.text(wallets.first.name));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(AppButton));
    await tester.tap(find.byType(AppButton));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.walletId, 'bca');
    expect(result!.amount, 7500000);
  });
}
