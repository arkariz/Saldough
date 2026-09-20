import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/record/presentation/widgets/record_choice.dart';
import 'package:saldough/features/record/presentation/widgets/record_choice_sheet.dart';

void main() {
  Future<void> open(WidgetTester tester, void Function(RecordChoice?) onResult) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                final result = await showModalBottomSheet<RecordChoice>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => const RecordChoiceSheet(),
                );
                onResult(result);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('RecordChoiceSheet', () {
    testWidgets('menampilkan kop, kartu info, dan tiga kartu jenis lengkap dengan lencana dan akibat saldo', (
      tester,
    ) async {
      await open(tester, (_) {});

      expect(find.text(t.record.sheetTitle), findsOneWidget);
      expect(find.text(t.record.choiceStepLabel.toUpperCase()), findsOneWidget);
      expect(find.text(t.record.noticeTitle), findsOneWidget);
      expect(find.text(t.record.disclaimerMessage), findsOneWidget);

      for (final title in [t.record.incomeAction, t.record.expenseAction, t.record.transferAction]) {
        expect(find.text(title), findsOneWidget);
      }
      for (final badge in [t.record.incomeBadge, t.record.expenseBadge, t.record.transferBadge]) {
        expect(find.text(badge.toUpperCase()), findsOneWidget);
      }
      for (final effect in [t.record.incomeEffectLabel, t.record.expenseEffectLabel, t.record.transferEffectLabel]) {
        expect(find.text(effect.toUpperCase()), findsOneWidget);
      }
      expect(find.text(t.record.transferExampleTopUp), findsOneWidget);
    });

    testWidgets('tiap kartu punya diagram alur uang sesuai fungsinya', (tester) async {
      await open(tester, (_) {});

      // Pemasukan: Luar -> Dompet(+). Pengeluaran: Dompet(-) -> Luar.
      expect(find.text(t.record.flowOutside), findsNWidgets(2));
      expect(find.text('+ ${t.record.flowWallet}'), findsOneWidget);
      expect(find.text('− ${t.record.flowWallet}'), findsOneWidget);
      // Transfer: Dompet asal(-) -> Dompet tujuan(+).
      expect(find.text('− ${t.record.flowSourceWallet}'), findsOneWidget);
      expect(find.text('+ ${t.record.flowTargetWallet}'), findsOneWidget);
    });

    testWidgets('kop berupa bilah datar, bukan kartu: tidak berbingkai AppHardCard', (tester) async {
      await open(tester, (_) {});

      expect(find.byType(AppHardCard), findsNothing);
    });

    testWidgets('mengetuk kartu mengembalikan pilihannya', (tester) async {
      RecordChoice? result;
      await open(tester, (r) => result = r);

      await tester.tap(find.text(t.record.expenseAction));
      await tester.pumpAndSettle();

      expect(result, RecordChoice.expense);
    });

    testWidgets('tombol tutup mengembalikan null tanpa memilih', (tester) async {
      RecordChoice? result = RecordChoice.income;
      await open(tester, (r) => result = r);

      // Tombol tutup adalah satu-satunya kontrol di kop selain kartu jenis.
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });

    testWidgets('tidak memakai kosakata yang menyiratkan aplikasi memindahkan uang', (tester) async {
      await open(tester, (_) {});

      const forbidden = ['transfer berhasil', 'kirim uang', 'bayar sekarang', 'transfer sekarang'];
      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((w) => (w.data ?? w.textSpan?.toPlainText() ?? '').toLowerCase());
      for (final text in texts) {
        for (final word in forbidden) {
          expect(text.contains(word), isFalse, reason: '"$text" memuat "$word"');
        }
      }
    });

    testWidgets('layar 360px + teks 2x: tidak overflow, seluruh kartu tetap bisa dijangkau lewat gulir', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(() {
        tester.view.reset();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });
      await open(tester, (_) {});

      await tester.scrollUntilVisible(find.text(t.record.pickTransferAction), 200);
      expect(find.text(t.record.pickTransferAction), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
