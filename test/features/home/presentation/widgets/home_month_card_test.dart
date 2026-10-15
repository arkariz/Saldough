import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/home/presentation/widgets/home_summary.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Kartu Arus Beranda sebagai pintu ke Analisis (D4): pasangan Pemasukan/
/// Pengeluaran bertanda panah; selisih dan footer tetap di luar pintu.
void main() {
  const flow = CashFlow(income: 1461543750, expense: 1142070000);

  Future<void> pump(WidgetTester tester, {VoidCallback? onOpen, Widget? footer}) => tester.pumpWidget(
    MaterialApp(
      theme: PixelTheme.light,
      home: Scaffold(
        body: HomeMonthCard(
          cashFlow: flow,
          footer: footer,
          onOpenAnalysis: onOpen,
          analysisLabel: onOpen == null ? null : 'Analisis September: pemasukan dan pengeluaran per kategori',
        ),
      ),
    ),
  );

  testWidgets('mengetuk pasangan Pemasukan/Pengeluaran membuka Analisis', (tester) async {
    var opened = 0;
    await pump(tester, onOpen: () => opened++);
    expect(find.byKey(const ValueKey('home-analysis-door')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('home-analysis-door')));
    expect(opened, 1);
  });

  testWidgets('pintu bersemantik tombol dengan label periodenya; selisih bukan bagian pintu', (tester) async {
    final semantics = tester.ensureSemantics();
    var opened = 0;
    await pump(tester, onOpen: () => opened++);
    expect(find.bySemanticsLabel('Analisis September: pemasukan dan pengeluaran per kategori'), findsOneWidget);
    await tester.tap(find.text('Selisih'));
    expect(opened, 0);
    semantics.dispose();
  });

  testWidgets('tanpa pemanggil: kartu seperti biasa, bukan pintu, nominal dan selisih tetap tampil', (tester) async {
    await pump(tester);
    expect(find.byKey(const ValueKey('home-analysis-door')), findsNothing);
    expect(find.text('+Rp14.615.438'), findsOneWidget);
    expect(find.text('−Rp11.420.700'), findsOneWidget);
    expect(find.text('Rp3.194.738'), findsOneWidget);
  });

  testWidgets('footer perkiraan tetap di bawah selisih dan muat di 360dp', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pump(tester, onOpen: () {}, footer: const Text('Perkiraan saldo'));
    expect(find.text('Perkiraan saldo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
