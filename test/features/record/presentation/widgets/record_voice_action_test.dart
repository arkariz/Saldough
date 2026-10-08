import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/record/presentation/widgets/expense_form_sheet.dart';
import 'package:saldough/features/record/presentation/widgets/record_choice.dart';
import 'package:saldough/features/record/presentation/widgets/record_form_host.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Mikrofon di bar atas lembar CATAT (T-14.4, ADR-034 §3.3): suara pindah ke
/// dalam Catat, FAB suara dihapus.
void main() {
  const wallets = [
    Wallet(
      id: 'w',
      name: 'BCA',
      iconKey: 'walletBank',
      initialBalance: 0,
      currentBalance: 500000000,
    ),
  ];

  testWidgets(
    'mikrofon tampil di bar atas CATAT dan menutup lembar dengan OpenVoiceCapture',
    (tester) async {
      Object? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: PixelTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await showModalBottomSheet<Object>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => RecordFormHost(
                      initialChoice: RecordChoice.expense,
                      formFor: (_, switcher) => ExpenseFormSheet(
                        wallets: wallets,
                        kindSwitcher: switcher,
                      ),
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

      expect(find.byKey(const ValueKey('record-voice')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('record-voice')));
      await tester.pumpAndSettle();
      expect(result, isA<OpenVoiceCapture>());
    },
  );

  testWidgets('tanpa RecordFormHost (sunting transaksi) tidak ada mikrofon', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ExpenseFormSheet(wallets: wallets)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('record-voice')), findsNothing);
  });
}
