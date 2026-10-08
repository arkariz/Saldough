import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:saldough/shared/wallet/wallet_presentation.dart';

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
        body: SingleChildScrollView(
          child: WalletSelectField(
            label: 'Dari Dompet',
            wallets: wallets,
            selectedId: selectedId,
            onSelected: onSelected ?? (_) {},
            previewAmountSen: previewAmountSen,
            previewIsCredit: previewIsCredit,
          ),
        ),
      ),
    );
  }

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(find.byType(AppMenuSelectButton<String>));
    await tester.pumpAndSettle();
  }

  group('WalletSelectField', () {
    testWidgets('menu menampilkan saldo tiap dompet sebelum dipilih (UX-11)', (tester) async {
      await tester.pumpWidget(pumpable());
      await openMenu(tester);

      expect(find.text(AppMoneyFormatter.format(500000000)), findsOneWidget);
      expect(find.text(AppMoneyFormatter.format(100000)), findsOneWidget);
    });

    testWidgets('menampilkan ajakan "belum dipilih" kalau selectedId null, tanpa saldo', (tester) async {
      await tester.pumpWidget(pumpable());

      expect(find.text(t.record.walletNotSelectedPrompt), findsOneWidget);
      expect(find.text('BCA'), findsNothing);
      expect(find.byKey(const ValueKey('wallet-balance-after')), findsNothing);
    });

    testWidgets('menampilkan nama dompet terpilih di tombol beserta saldonya', (tester) async {
      await tester.pumpWidget(pumpable(selectedId: 'bca'));

      expect(find.text('BCA'), findsOneWidget);
      expect(find.text(AppMoneyFormatter.format(500000000)), findsOneWidget);
      expect(find.text(t.record.walletNotSelectedPrompt), findsNothing);
    });

    testWidgets('mengetuk tombol membuka menu berisi seluruh dompet (dropdown yang sama dengan penyaring)', (
      tester,
    ) async {
      await tester.pumpWidget(pumpable());
      await openMenu(tester);

      expect(find.text('BCA'), findsOneWidget);
      expect(find.text('GoPay'), findsOneWidget);
      // Dompet wajib dipilih: tidak ada item "Semua".
      expect(find.text(t.transaction.walletFilterAllLabel), findsNothing);
    });

    testWidgets('memilih dompet di menu memanggil onSelected dengan id-nya', (tester) async {
      String? selected;
      await tester.pumpWidget(pumpable(onSelected: (id) => selected = id));

      await openMenu(tester);
      await tester.tap(find.text('GoPay'));
      await tester.pumpAndSettle();

      expect(selected, 'gopay');
    });

    testWidgets('akibat ke saldo ditulis sekali: "Saldo jadi" bertambah untuk previewIsCredit true', (tester) async {
      await tester.pumpWidget(pumpable(selectedId: 'bca', previewAmountSen: 10000000));

      expect(find.text(t.record.balanceAfter(amount: AppMoneyFormatter.format(510000000))), findsOneWidget);
    });

    testWidgets('"Saldo jadi" berkurang untuk previewIsCredit false; negatif ditulis danger', (tester) async {
      await tester.pumpWidget(pumpable(selectedId: 'bca', previewAmountSen: 10000000, previewIsCredit: false));
      expect(find.text(t.record.balanceAfter(amount: AppMoneyFormatter.format(490000000))), findsOneWidget);

      await tester.pumpWidget(pumpable(selectedId: 'gopay', previewAmountSen: 200000, previewIsCredit: false));
      final after = tester.widget<Text>(find.byKey(const ValueKey('wallet-balance-after')));
      expect(after.data, t.record.balanceAfter(amount: AppMoneyFormatter.format(-100000)));
      expect(after.style!.color, AppColors.light.danger);
    });

    testWidgets('tanpa nominal valid: saldo saat ini, tanpa "Saldo jadi"', (tester) async {
      await tester.pumpWidget(pumpable(selectedId: 'bca'));

      expect(find.text(AppMoneyFormatter.format(500000000)), findsOneWidget);
    });

    testWidgets('menampilkan noWalletsMessage kalau daftar dompet kosong', (tester) async {
      await tester.pumpWidget(pumpable(wallets: const []));

      expect(find.text(t.record.noWalletsMessage), findsOneWidget);
    });

  });

  group('WalletSelectField layout ekstrem (nama panjang, layar sempit, teks 2x)', () {
    void narrowAndBig(WidgetTester tester) {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(() {
        tester.view.reset();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });
    }

    testWidgets('nama panjang + saldo miliaran + pratinjau: tidak overflow, nama tidak dielipsis', (tester) async {
      narrowAndBig(tester);
      await tester.pumpWidget(
        pumpable(
          wallets: const [_bank, _ewallet],
          selectedId: 'bca',
          previewAmountSen: 99999999999,
          previewIsCredit: false,
        ),
      );

      expect(tester.takeException(), isNull);
      final name = tester.widget<Text>(find.text(_longName));
      expect(name.overflow, isNot(TextOverflow.ellipsis));
      expect(name.maxLines, isNull);
    });

    testWidgets('belum ada dompet terpilih menampilkan ajakan memilih tanpa overflow', (tester) async {
      narrowAndBig(tester);
      await tester.pumpWidget(pumpable(wallets: const [_bank, _ewallet]));

      expect(tester.takeException(), isNull);
      expect(find.text(t.record.walletNotSelectedPrompt), findsOneWidget);
    });

    testWidgets('baris memakai ikon dompet umum; menu memakai ikon jenis dompet', (tester) async {
      bool hasIcon(IconKey key) => find
          .descendant(
            of: find.byType(AppMenuSelectButton<String>),
            matching: find.byWidgetPredicate((w) => w is AppIcon && w.iconKey == key),
          )
          .evaluate()
          .isNotEmpty;

      await tester.pumpWidget(pumpable(wallets: const [_bank, _ewallet], selectedId: 'bca'));
      expect(hasIcon(IconKey.wallets), isTrue);

      await openMenu(tester);
      expect(find.byWidgetPredicate((w) => w is AppIcon && w.iconKey == IconKey.walletEwallet), findsOneWidget);
    });

    testWidgets('menu: nama panjang utuh, memilih memanggil onSelected, tidak overflow', (tester) async {
      narrowAndBig(tester);
      String? selected;
      await tester.pumpWidget(pumpable(wallets: const [_bank, _ewallet], onSelected: (id) => selected = id));

      await openMenu(tester);
      expect(find.text(_otherLongName), findsOneWidget);
      await tester.tap(find.text(_otherLongName));
      await tester.pumpAndSettle();

      expect(selected, 'gopay');
      expect(tester.takeException(), isNull);
    });
  });
}
