import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';

/// Baris legenda donat (komponen LegendRow): satu baris penanda, nama, persen,
/// nominal; ketukan memilih, tidak berpindah layar.
void main() {
  Future<void> pump(WidgetTester tester, List<Widget> rows) => tester.pumpWidget(
    MaterialApp(
      theme: PixelTheme.light,
      home: Scaffold(body: Column(children: rows)),
    ),
  );

  testWidgets('menampilkan nama, persen, dan nominal penuh tanpa tanda; ketukan dipanggil', (tester) async {
    var taps = 0;
    await pump(tester, [
      AppLegendRow(
        name: 'Makan',
        percent: '11%',
        sen: 124500000,
        semanticsLabel: 'Makan, 11%, Rp1.245.000',
        swatch: Colors.orange,
        onTap: () => taps++,
      ),
    ]);
    expect(find.text('Makan'), findsOneWidget);
    expect(find.text('11%'), findsOneWidget);
    expect(find.text('Rp1.245.000'), findsOneWidget);
    await tester.tap(find.byType(AppLegendRow));
    expect(taps, 1);
  });

  testWidgets('tombol bersemantik: label lengkap, terpilih ditandai', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester, [
      AppLegendRow(
        key: const ValueKey('row'),
        name: 'Makan',
        percent: '11%',
        sen: 124500000,
        semanticsLabel: 'Makan, 11%, Rp1.245.000',
        swatch: Colors.orange,
        selected: true,
        onTap: () {},
      ),
    ]);
    expect(
      tester.getSemantics(find.byKey(const ValueKey('row'))),
      matchesSemantics(
        label: 'Makan, 11%, Rp1.245.000',
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('baris Lainnya memberi panah buka-tutup; baris anak tanpa penanda dan menjorok', (tester) async {
    await pump(tester, [
      const AppLegendRow(
        name: 'Lainnya (2 kategori)',
        percent: '12%',
        sen: 100,
        semanticsLabel: 'x',
        swatch: Colors.grey,
        expanded: false,
      ),
      const AppLegendRow(name: 'Tagihan', percent: '5%', sen: 50, semanticsLabel: 'y', child: true, showDivider: true),
    ]);
    expect(find.byType(AppIcon), findsOneWidget, reason: 'hanya panah Lainnya');
    final parent = tester.getTopLeft(find.textContaining('Lainnya (2 kategori)', findRichText: true)).dx;
    final child = tester.getTopLeft(find.text('Tagihan')).dx;
    expect(child, parent, reason: 'anak menjorok sejajar nama induknya (penanda 10 + jarak 10 di kiri)');
  });

  testWidgets('muat di 360dp dengan teks 2x tanpa overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: PixelTheme.light,
        home: const MediaQuery(
          data: MediaQueryData(size: Size(360, 800), textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: AppLegendRow(
              name: 'Tempat tinggal',
              percent: '<1%',
              sen: 123456789012,
              semanticsLabel: 'z',
              swatch: Colors.teal,
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
