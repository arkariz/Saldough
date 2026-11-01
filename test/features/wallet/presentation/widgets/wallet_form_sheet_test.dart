import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/design_system/design_system.dart';
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
    await tester.tap(find.widgetWithText(DsButton, label));
    await tester.pumpAndSettle();
  }

  group('WalletFormSheet -- tambah', () {
    testWidgets('tombol simpan nonaktif sampai nama terisi', (tester) async {
      await open(tester);

      DsButton button() => tester.widget<DsButton>(find.widgetWithText(DsButton, t.wallet.saveAddAction));
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
      await tester.tap(find.text(t.wallet.typeCash));
      await tester.pump();
      await tester.tap(find.text('+500rb'));
      await tester.tap(find.text('+1jt'));
      await tester.pump();
      expect(find.text('1.500.000'), findsOneWidget, reason: 'pilihan cepat menambah dan memformat ulang');
      await save(tester, t.wallet.saveAddAction);

      final saved = results.single! as WalletFormSaved;
      expect(saved.name, 'Dompet Saku');
      expect(saved.iconKey, 'walletCash');
      expect(saved.balance, 150000000);
      expect(saved.isActive, isTrue);
    });

    testWidgets('tanpa mengisi saldo awal, saldo awal nol (FR-WAL-002: boleh nol)', (tester) async {
      final results = await open(tester);

      await tester.enterText(field(0), 'Kosong');
      await tester.pump();
      await save(tester, t.wallet.saveAddAction);

      expect((results.single! as WalletFormSaved).balance, 0);
    });

    testWidgets('tombol Bersihkan mengosongkan saldo awal', (tester) async {
      final results = await open(tester);

      await tester.enterText(field(0), 'A');
      await tester.tap(find.text('+1jt'));
      await tester.pump();
      await tester.tap(find.text(t.record.clearAmountAction));
      await tester.pump();
      await save(tester, t.wallet.saveAddAction);

      expect((results.single! as WalletFormSaved).balance, 0);
    });

    testWidgets('nama dibatasi $walletNameMaxLength karakter', (tester) async {
      await open(tester);

      await tester.enterText(field(0), 'X' * 40);
      await tester.pump();

      expect(tester.widget<TextField>(field(0)).controller!.text.length, walletNameMaxLength);
    });

    testWidgets('mode tambah tidak menampilkan saldo tercatat, sakelar aktif, maupun hapus', (tester) async {
      await open(tester);

      expect(find.text(t.wallet.currentBalanceLabel), findsNothing);
      expect(find.byType(Switch), findsNothing);
      expect(find.text(t.wallet.deleteAction), findsNothing);
    });

    testWidgets('input cepat: semua chip satu baris horizontal, juga di 320dp dengan teks 2x', (tester) async {
      tester.view
        ..physicalSize = const Size(320, 900)
        ..devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(() {
        tester.view.reset();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });
      await open(tester);

      final clear = tester.getTopLeft(find.text(t.record.clearAmountAction)).dy;
      final chips = find.ancestor(of: find.text(t.record.clearAmountAction), matching: find.byType(Row));
      expect(chips, findsWidgets);
      final row = tester.widget<Row>(chips.first);
      expect(row.children.whereType<Expanded>().length, greaterThanOrEqualTo(4), reason: 'chip berbagi lebar sebaris');
      for (final label in find.descendant(of: chips.first, matching: find.byType(Text)).evaluate()) {
        expect(tester.getTopLeft(find.byWidget(label.widget)).dy, closeTo(clear, 12), reason: 'sebaris');
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('tombol kembali menutup tanpa hasil', (tester) async {
      final results = await open(tester);

      await tester.tap(find.byTooltip(t.common.close));
      await tester.pumpAndSettle();

      expect(results, [null]);
    });
  });

  group('WalletFormSheet -- sunting', () {
    testWidgets('terisi awal, menampilkan saldo tercatat, dan tombolnya "Simpan Perubahan"', (tester) async {
      await open(tester, initial: existing);

      expect(find.text('BCA'), findsWidgets);
      expect(find.text('1.300.000'), findsOneWidget, reason: 'kolom terisi saldo saat ini, bukan saldo awal');
      expect(find.text(t.wallet.currentBalanceLabel), findsOneWidget);
      expect(find.widgetWithText(DsButton, t.transaction.saveChangesAction), findsOneWidget);
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
      expect(saved.balance, isNull);
    });

    testWidgets('saldo yang diubah dikirim dalam sen sebagai saldo saat ini', (tester) async {
      final results = await open(tester, initial: existing);

      await tester.tap(find.text('+500rb'));
      await tester.pump();
      await save(tester, t.transaction.saveChangesAction);

      expect((results.single! as WalletFormSaved).balance, 180000000);
    });

    testWidgets('saldo awal negatif tidak terwakili kolom: kolom kosong dan tidak dikirim kecuali disentuh', (
      tester,
    ) async {
      final results = await open(
        tester,
        initial: existing.copyWith(currentBalance: -5000000),
      );
      expect(find.text('50.000'), findsNothing, reason: 'tanda minus tidak boleh hilang diam-diam');

      await save(tester, t.transaction.saveChangesAction);

      expect((results.single! as WalletFormSaved).balance, isNull);
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

      await tester.tap(find.widgetWithText(DsButton, t.wallet.deleteAction));
      await tester.pumpAndSettle();
      expect(find.text(t.wallet.deleteConfirmTitle), findsOneWidget);
      await tester.tap(find.widgetWithText(AppButton, t.common.cancel));
      await tester.pumpAndSettle();
      expect(results, isEmpty, reason: 'formulir masih terbuka');

      await tester.tap(find.widgetWithText(DsButton, t.wallet.deleteAction));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, t.common.delete));
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
