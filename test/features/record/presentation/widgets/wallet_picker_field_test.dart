import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/record/presentation/widgets/wallet_picker_field.dart';
import 'package:saldough/shared/wallet/wallet.dart';

void main() {
  const wallets = [
    Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 0, currentBalance: 500000000),
    Wallet(id: 'gopay', name: 'GoPay', iconKey: 'walletEwallet', initialBalance: 0, currentBalance: 100000),
  ];

  Widget pumpable({
    List<Wallet> wallets = wallets,
    String? selectedId,
    ValueChanged<String>? onSelected,
    int? previewAmountSen,
    bool previewIsCredit = true,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: WalletPickerField(
          label: 'Dari Dompet',
          wallets: wallets,
          selectedId: selectedId,
          onSelected: onSelected ?? (_) {},
          previewAmountSen: previewAmountSen,
          previewIsCredit: previewIsCredit,
        ),
      ),
    );
  }

  group('WalletPickerField', () {
    testWidgets('menampilkan prompt "belum dipilih" kalau selectedId null', (tester) async {
      await tester.pumpWidget(pumpable());

      expect(find.text(t.record.walletNotSelectedPrompt), findsOneWidget);
      expect(find.text('BCA'), findsNothing);
    });

    testWidgets('menampilkan nama dompet terpilih dan tombol Ganti', (tester) async {
      await tester.pumpWidget(pumpable(selectedId: 'bca'));

      expect(find.text('BCA'), findsOneWidget);
      expect(find.text(t.record.changeWalletAction), findsOneWidget);
      expect(find.text(t.record.walletNotSelectedPrompt), findsNothing);
    });

    testWidgets('mengetuk kartu membuka lembar pemilih berisi seluruh dompet', (tester) async {
      await tester.pumpWidget(pumpable());

      await tester.tap(find.text(t.record.walletNotSelectedPrompt));
      await tester.pumpAndSettle();

      expect(find.text('BCA'), findsOneWidget);
      expect(find.text('GoPay'), findsOneWidget);
    });

    testWidgets('memilih dompet di lembar memanggil onSelected dengan id-nya', (tester) async {
      String? selected;
      await tester.pumpWidget(pumpable(onSelected: (id) => selected = id));

      await tester.tap(find.text(t.record.walletNotSelectedPrompt));
      await tester.pumpAndSettle();
      await tester.tap(find.text('GoPay'));
      await tester.pumpAndSettle();

      expect(selected, 'gopay');
    });

    testWidgets('pratinjau sebelum->sesudah benar untuk previewIsCredit true', (tester) async {
      await tester.pumpWidget(pumpable(selectedId: 'bca', previewAmountSen: 10000000));

      expect(find.text(AppMoneyFormatter.format(500000000)), findsOneWidget);
      expect(find.text(AppMoneyFormatter.format(510000000)), findsOneWidget);
    });

    testWidgets('pratinjau sebelum->sesudah benar untuk previewIsCredit false (mengurangi saldo)', (tester) async {
      await tester.pumpWidget(
        pumpable(selectedId: 'bca', previewAmountSen: 10000000, previewIsCredit: false),
      );

      expect(find.text(AppMoneyFormatter.format(500000000)), findsOneWidget);
      expect(find.text(AppMoneyFormatter.format(490000000)), findsOneWidget);
    });

    testWidgets('tidak menampilkan pratinjau kalau nominal belum valid (null/nol)', (tester) async {
      await tester.pumpWidget(pumpable(selectedId: 'bca'));

      expect(find.text(AppMoneyFormatter.format(500000000)), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsNothing);
    });

    testWidgets('menampilkan noWalletsMessage kalau daftar dompet kosong', (tester) async {
      await tester.pumpWidget(pumpable(wallets: const []));

      expect(find.text(t.record.noWalletsMessage), findsOneWidget);
    });
  });
}
