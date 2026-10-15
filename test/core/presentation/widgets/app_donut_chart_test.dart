import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';

/// Diagram donat Analisis (komponen DonutChart): geometri ketukan dan
/// semantik; gambar irisannya sendiri dijaga lewat label dan pilihan.
void main() {
  const red = Color(0xFFAA0000);
  const green = Color(0xFF00AA00);
  const blue = Color(0xFF0000AA);
  const slices = [
    DonutSlice(value: 50, color: red),
    DonutSlice(value: 30, color: green),
    DonutSlice(value: 20, color: blue),
  ];

  group('sliceAt', () {
    // Pusat (108, 108), cincin di jari-jari 96; irisan mulai jam 12 searah jarum jam.
    test('jam 3 (25%) = irisan pertama, jam 9 (75%) = kedua, dekat jam 12 sebelum putaran penuh = ketiga', () {
      expect(AppDonutChart.sliceAt(const Offset(204, 108), slices), 0);
      expect(AppDonutChart.sliceAt(const Offset(106, 204), slices), 1, reason: 'sesaat lewat jam 6 (50%)');
      expect(AppDonutChart.sliceAt(const Offset(12, 108), slices), 1);
      expect(AppDonutChart.sliceAt(const Offset(88, 14), slices), 2);
    });

    test('lubang di tengah, di luar kotak, dan donat kosong tidak memilih apa pun', () {
      expect(AppDonutChart.sliceAt(const Offset(108, 108), slices), isNull);
      expect(AppDonutChart.sliceAt(const Offset(300, 300), slices), isNull);
      expect(AppDonutChart.sliceAt(const Offset(204, 108), const []), isNull);
      expect(AppDonutChart.sliceAt(const Offset(204, 108), const [DonutSlice(value: 0, color: red)]), isNull);
    });

    test('irisan bernilai nol dilewati tanpa menggeser indeks', () {
      const withZero = [
        DonutSlice(value: 0, color: red),
        DonutSlice(value: 100, color: green),
      ];
      expect(AppDonutChart.sliceAt(const Offset(204, 108), withZero), 1);
    });
  });

  group('AppDonutChart', () {
    Future<List<int>> tapRing(WidgetTester tester, List<Offset> points) async {
      final selected = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppDonutChart(
                slices: slices,
                selected: 1,
                semanticsLabel: 'Pengeluaran September: A 50%, B 30%, C 20%',
                center: const Text('Rp100'),
                onSelect: selected.add,
              ),
            ),
          ),
        ),
      );
      final origin = tester.getTopLeft(find.byType(AppDonutChart));
      for (final point in points) {
        await tester.tapAt(origin + point);
        await tester.pump();
      }
      return selected;
    }

    testWidgets('mengetuk cincin memilih irisannya; tengah tidak menangkap ketukan', (tester) async {
      final selected = await tapRing(tester, const [Offset(204, 108), Offset(12, 108), Offset(108, 108)]);
      expect(selected, [0, 1]);
    });

    testWidgets('label ringkas diagram terbaca pembaca layar, isi tengah tampil', (tester) async {
      final semantics = tester.ensureSemantics();
      await tapRing(tester, const []);
      expect(find.text('Rp100'), findsOneWidget);
      expect(find.bySemanticsLabel('Pengeluaran September: A 50%, B 30%, C 20%'), findsOneWidget);
      semantics.dispose();
    });
  });
}
