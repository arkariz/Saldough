import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/wallet/presentation/widgets/wallet_form_sheet.dart';
import 'package:saldough/shared/wallet/wallet.dart';

void main() {
  const existing = Wallet(
    id: 'bca',
    name: 'BCA',
    iconKey: 'walletBank',
    initialBalance: 100000000,
    currentBalance: 130000000,
  );

  /// Membuka formulir lewat tombol, dan mengumpulkan hasilnya. Viewport tinggi
  /// supaya seluruh formulir terbangun tanpa menggulir.
  Future<List<WalletFormResult?>> open(WidgetTester tester, {Wallet? initial}) async {
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final results = <WalletFormResult?>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                results.add(
                  await showFullScreenSheet<WalletFormResult>(
                    context,
                    builder: (_) => WalletFormSheet(initial: initial),
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
    return results;
  }

  Finder field(int index) => find.byType(TextField).at(index);

  Future<void> save(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(AppButton, label));
    await tester.pumpAndSettle();
  }

  group('WalletFormSheet -- tambah', () {
    testWidgets('tombol simpan nonaktif sampai nama terisi', (tester) async {
      await open(tester);

      AppButton button() => tester.widget<AppButton>(find.widgetWithText(AppButton, t.wallet.saveAddAction));
      expect(button().onPressed, isNull);

      await tester.enterText(field(0), '   ');
      await tester.pump();
      expect(button().onPressed, isNull, reason: 'nama berisi spasi saja tidak sah');

      await tester.enterText(field(0), 'GoPay');
      await tester.pump();
      expect(button().onPressed, isNotNull);
    });

    testWidgets('menyimpan nama, ikon terpilih, dan saldo awal dalam SEN', (tester) async {
      final results = await open(tester);

      await tester.enterText(field(0), '  Dompet Saku  ');
      await tester.tap(find.text(t.wallet.typeCash.toUpperCase()));
      await tester.pump();
      await tester.tap(find.text('+500rb'));
      await tester.tap(find.text('+1jt'));
      await tester.pump();
      expect(find.text('1.500.000'), findsOneWidget, reason: 'pilihan cepat menambah dan memformat ulang');
      await save(tester, t.wallet.saveAddAction);

      final saved = results.single! as WalletFormSaved;
      expect(saved.name, 'Dompet Saku');
      expect(saved.iconKey, 'walletCash');
      expect(saved.initialBalance, 150000000);
      expect(saved.isActive, isTrue);
    });

    testWidgets('tanpa mengisi saldo awal, saldo awal nol (FR-WAL-002: boleh nol)', (tester) async {
      final results = await open(tester);

      await tester.enterText(field(0), 'Kosong');
      await tester.pump();
      await save(tester, t.wallet.saveAddAction);

      expect((results.single! as WalletFormSaved).initialBalance, 0);
    });

    testWidgets('tombol Bersihkan mengosongkan saldo awal', (tester) async {
      final results = await open(tester);

      await tester.enterText(field(0), 'A');
      await tester.tap(find.text('+1jt'));
      await tester.pump();
      await tester.tap(find.text(t.record.clearAmountAction));
      await tester.pump();
      await save(tester, t.wallet.saveAddAction);

      expect((results.single! as WalletFormSaved).initialBalance, 0);
    });

    testWidgets('nama dibatasi $walletNameMaxLength karakter', (tester) async {
      await open(tester);

      await tester.enterText(field(0), 'X' * 40);
      await tester.pump();

      expect(tester.widget<TextField>(field(0)).controller!.text.length, walletNameMaxLength);
    });

    testWidgets('mode tambah tidak menampilkan saldo tercatat, sakelar aktif, maupun hapus', (tester) async {
      await open(tester);

      expect(find.text(t.wallet.currentBalanceLabel.toUpperCase()), findsNothing);
      expect(find.byType(Switch), findsNothing);
      expect(find.text(t.wallet.deleteAction), findsNothing);
    });

    testWidgets('tombol kembali menutup tanpa hasil', (tester) async {
      final results = await open(tester);

      await tester.tap(find.byWidgetPredicate((w) => w is AppIcon && w.iconKey == IconKey.chevronLeft));
      await tester.pumpAndSettle();

      expect(results, [null]);
    });
  });

  group('WalletFormSheet -- sunting', () {
    testWidgets('terisi awal, menampilkan saldo tercatat, dan tombolnya "Simpan Perubahan"', (tester) async {
      await open(tester, initial: existing);

      expect(find.text('BCA'), findsWidgets);
      expect(find.text('1.000.000'), findsOneWidget, reason: 'saldo awal terisi');
      expect(find.text('Rp1.300.000'), findsOneWidget, reason: 'saldo tercatat, hanya baca');
      expect(find.widgetWithText(AppButton, t.transaction.saveChangesAction), findsOneWidget);
    });

    testWidgets('saldo awal yang tidak disentuh TIDAK dikirim (null) -- nilai tersimpan tidak tertimpa', (
      tester,
    ) async {
      final results = await open(tester, initial: existing);

      await tester.enterText(field(0), 'BCA Utama');
      await tester.pump();
      await save(tester, t.transaction.saveChangesAction);

      final saved = results.single! as WalletFormSaved;
      expect(saved.name, 'BCA Utama');
      expect(saved.initialBalance, isNull);
    });

    testWidgets('saldo awal yang diubah dikirim dalam sen', (tester) async {
      final results = await open(tester, initial: existing);

      await tester.tap(find.text('+500rb'));
      await tester.pump();
      await save(tester, t.transaction.saveChangesAction);

      expect((results.single! as WalletFormSaved).initialBalance, 150000000);
    });

    testWidgets('saldo awal negatif tidak terwakili kolom: kolom kosong dan tidak dikirim kecuali disentuh', (
      tester,
    ) async {
      final results = await open(
        tester,
        initial: existing.copyWith(initialBalance: -5000000),
      );
      expect(find.text('50.000'), findsNothing, reason: 'tanda minus tidak boleh hilang diam-diam');

      await save(tester, t.transaction.saveChangesAction);

      expect((results.single! as WalletFormSaved).initialBalance, isNull);
    });

    testWidgets('sakelar aktif menonaktifkan dompet', (tester) async {
      final results = await open(tester, initial: existing);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);

      await tester.tap(find.byType(Switch));
      await tester.pump();
      await save(tester, t.transaction.saveChangesAction);

      expect((results.single! as WalletFormSaved).isActive, isFalse);
    });

    testWidgets('hapus meminta konfirmasi: batal tidak menghapus, konfirmasi mengembalikan WalletFormDeleted', (
      tester,
    ) async {
      final results = await open(tester, initial: existing);

      await tester.tap(find.widgetWithText(AppButton, t.wallet.deleteAction));
      await tester.pumpAndSettle();
      expect(find.text(t.wallet.deleteConfirmTitle), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, t.common.cancel));
      await tester.pumpAndSettle();
      expect(results, isEmpty, reason: 'formulir masih terbuka');

      await tester.tap(find.widgetWithText(AppButton, t.wallet.deleteAction));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, t.common.delete));
      await tester.pumpAndSettle();

      expect(results.single, isA<WalletFormDeleted>());
    });

    testWidgets('layar 360px + teks 2x + nama panjang: tidak overflow', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await open(tester, initial: existing.copyWith(name: 'Rekening Bank Central Asia'));
      tester.view.physicalSize = const Size(360, 3200);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
