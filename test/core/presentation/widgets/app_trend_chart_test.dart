import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/currency/amount_visibility.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';

/// Tren enam periode (TrendChart, ADR-034): slot tetap rata kanan, kolom
/// terpilih, label sumbu, dan nominal tersembunyi.
void main() {
  tearDown(() => AmountVisibility.notifier.value = false);

  TrendColumn column(
    String label,
    int income,
    int expense, {
    String? caption,
  }) => TrendColumn(
    label: label,
    income: income,
    expense: expense,
    netText: '+1 jt',
    caption: caption,
    semanticsLabel: '$label lengkap',
  );

  Future<List<int>> pump(
    WidgetTester tester,
    List<TrendColumn> columns, {
    int selected = 0,
    double width = 296,
  }) async {
    final taps = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: PixelTheme.light,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: AppTrendChart(
                columns: columns,
                selected: selected,
                onSelect: taps.add,
                axisLabel: (sen) => '${sen ~/ 100000000} jt',
              ),
            ),
          ),
        ),
      ),
    );
    return taps;
  }

  test(
    'skala sumbu: langkah rapi 1/2/2,5/5 × 10ⁿ dengan paling banyak sekitar tiga garis',
    () {
      final scale = AppTrendChart.scaleFor(1461543750); // Rp14,6 jt dalam sen
      expect(scale.step, 500000000);
      expect(scale.max, 1500000000);
      expect(AppTrendChart.scaleFor(0).max, greaterThan(0));
      expect(AppTrendChart.scaleFor(100).step, 50);
    },
  );

  testWidgets(
    'enam slot rata kanan: tiga kolom menempati tiga slot terakhir, tanpa kolom nol di kiri',
    (tester) async {
      await pump(tester, [
        column('Jul', 10000000000, 5000000000),
        column('Agu', 0, 0),
        column('Sep', 1, 1),
      ]);
      final first = tester.getTopLeft(find.byKey(const ValueKey('trend-col-0'))).dx;
      final last = tester.getTopRight(find.byKey(const ValueKey('trend-col-2'))).dx;
      final left = tester.getTopLeft(find.byType(AppTrendChart)).dx;
      const slot = (296 - AppTrendChart.axisWidth) / 6;
      expect(first - left, closeTo(3 * slot, 0.5));
      expect(last - left, closeTo(6 * slot, 0.5));
      expect(find.byKey(const ValueKey('trend-col-3')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'mengetuk kolom memilih indeksnya; terpilih bersemantik "selected"',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final taps = await pump(tester, [
        column('Agu', 100, 50),
        column('Sep', 200, 100),
      ], selected: 1);
      await tester.tap(find.byKey(const ValueKey('trend-col-0')));
      expect(taps, [0]);
      expect(
        tester.getSemantics(find.byKey(const ValueKey('trend-col-1'))),
        matchesSemantics(
          label: 'Sep lengkap',
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
          hasTapAction: true,
        ),
      );
      semantics.dispose();
    },
  );

  testWidgets(
    'label kolom, selisih ringkas, dan keterangan tampil; label sumbu hilang saat nominal disembunyikan',
    (
      tester,
    ) async {
      await pump(tester, [
        column('Agu', 1500000000, 500000000),
        column('Okt', 100000000, 0, caption: 's.d. 10 Okt'),
      ]);
      expect(find.text('Agu'), findsOneWidget);
      expect(find.text('s.d. 10 Okt'), findsOneWidget);
      expect(find.text('+1 jt'), findsNWidgets(2));
      expect(find.text('5 jt'), findsOneWidget, reason: 'garis bantu pertama');

      AmountVisibility.notifier.value = true;
      await pump(tester, [column('Agu', 1500000000, 500000000)]);
      await tester.pump();
      expect(find.text('5 jt'), findsNothing);
      expect(find.text('Agu'), findsOneWidget, reason: 'kolom tetap tampil');
    },
  );

  testWidgets('satu besaran: garis rata-rata berlabel; tanpa garis bila rata-rata null', (tester) async {
    Future<void> pumpSingle(int? average) => tester.pumpWidget(
      MaterialApp(
        theme: PixelTheme.light,
        home: Scaffold(
          body: SizedBox(
            width: 296,
            child: AppTrendChart(
              columns: [column('Agu', 0, 1000000000), column('Sep', 0, 1245000000)],
              selected: 1,
              single: true,
              average: average,
              averageLabel: 'rata-rata 3 bulan',
              onSelect: (_) {},
              axisLabel: (sen) => '${sen ~/ 100000000} jt',
            ),
          ),
        ),
      ),
    );
    await pumpSingle(950000000);
    expect(find.text('rata-rata 3 bulan'), findsOneWidget);
    await pumpSingle(null);
    expect(find.text('rata-rata 3 bulan'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('360dp dan teks 2x: tanpa overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: PixelTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: AppTrendChart(
              columns: [
                for (final l in ['Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu']) column(l, 100, 50, caption: '24 hari'),
              ],
              selected: 5,
              onSelect: (_) {},
              axisLabel: (sen) => '15 jt',
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
