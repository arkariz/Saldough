import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/record/presentation/widgets/wallet_picker_field.dart';
import 'package:saldough/shared/wallet/wallet.dart';

const _longName = 'Rekening Bank Central Asia Utama Pribadi Nomor Satu';
const _otherLongName = 'Dompet Digital Belanja Online Bulanan Keluarga Besar';

const _bank = Wallet(
  id: 'bca',
  name: _longName,
  iconKey: 'walletBank',
  initialBalance: 123456789000,
  currentBalance: 123456789000,
);
const _ewallet = Wallet(
  id: 'gopay',
  name: _otherLongName,
  iconKey: 'walletEwallet',
  initialBalance: 5000000,
  currentBalance: 5000000,
);

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
      expect(find.text('→'), findsNothing);
    });

    testWidgets('menampilkan noWalletsMessage kalau daftar dompet kosong', (tester) async {
      await tester.pumpWidget(pumpable(wallets: const []));

      expect(find.text(t.record.noWalletsMessage), findsOneWidget);
    });
  });

  /// Layar sempit + teks 2x -- kondisi terburuk yang wajar (ponsel kecil dengan
  /// pengaturan aksesibilitas ukuran huruf terbesar).
  void useWorstCase(WidgetTester tester) {
    tester.view.physicalSize = const Size(360, 1600);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  Future<void> pumpStressField(
    WidgetTester tester, {
    String? selectedId,
    int? previewAmountSen,
    bool previewIsCredit = false,
    ValueChanged<String>? onSelected,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: PixelTheme(
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: WalletPickerField(
                label: 'Dari Dompet',
                wallets: const [_bank, _ewallet],
                selectedId: selectedId,
                onSelected: onSelected ?? (_) {},
                previewAmountSen: previewAmountSen,
                previewIsCredit: previewIsCredit,
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('WalletPickerField layout ekstrem (nama panjang, layar sempit, teks 2x)', () {
    testWidgets('nama dompet sangat panjang + saldo miliaran + pratinjau: tidak overflow, nama tidak dielipsis', (
      tester,
    ) async {
      useWorstCase(tester);
      await pumpStressField(tester, selectedId: 'bca', previewAmountSen: 98765432100);

      expect(tester.takeException(), isNull, reason: 'tidak boleh ada RenderFlex overflow');
      final name = tester.widget<Text>(find.text(_longName));
      expect(name.overflow, isNot(TextOverflow.ellipsis));
      expect(name.maxLines, isNull);
      // Saldo sebelum (dicoret) dan sesudah keduanya tetap ada.
      expect(find.text('Rp1.234.567.890'), findsOneWidget);
      expect(find.text('Rp246.913.569'), findsOneWidget);
    });

    testWidgets('belum ada dompet terpilih menampilkan ajakan memilih tanpa overflow', (tester) async {
      useWorstCase(tester);
      await pumpStressField(tester);

      expect(tester.takeException(), isNull);
      expect(find.text(t.record.walletNotSelectedPrompt), findsOneWidget);
      // Belum terpilih: tanpa tombol "Ganti" (seluruh kartu sudah bisa diketuk).
      expect(find.text(t.record.changeWalletAction), findsNothing);
    });

    testWidgets('kartu memakai ikon sesuai jenis dompet, bukan ikon generik', (tester) async {
      await pumpStressField(tester, selectedId: 'bca');
      bool hasIcon(IconKey key) =>
          find.byWidgetPredicate((w) => w is AppIcon && w.iconKey == key).evaluate().isNotEmpty;
      expect(hasIcon(IconKey.walletBank), isTrue);
      expect(hasIcon(IconKey.wallets), isFalse);

      await pumpStressField(tester, selectedId: 'gopay');
      expect(hasIcon(IconKey.walletEwallet), isTrue);
    });

    testWidgets('lembar pemilih: nama panjang utuh dan tidak overflow; memilih memanggil onSelected', (tester) async {
      useWorstCase(tester);
      String? picked;
      await pumpStressField(tester, selectedId: 'bca', onSelected: (id) => picked = id);

      await tester.tap(find.text(t.record.changeWalletAction));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'lembar pemilih tidak boleh overflow');
      // Nama muncul di kartu terpilih DAN di daftar lembar pemilih.
      expect(find.text(_otherLongName), findsOneWidget);
      await tester.tap(find.text(_otherLongName));
      await tester.pumpAndSettle();
      expect(picked, 'gopay');
    });
  });
}
