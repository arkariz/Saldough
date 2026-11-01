import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/design_system/design_system.dart';

Widget _host(Widget child, {double textScale = 1}) => MaterialApp(
  theme: DsTheme.light,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)),
);

void main() {
  testWidgets('DsPeriodStepper: panah memanggil mundur/maju, panah null nonaktif, tag tampil', (tester) async {
    var back = 0;
    await tester.pumpWidget(
      _host(
        DsPeriodStepper(
          title: 'Mei 2024',
          tag: 'Periode peralihan · 31 hari',
          previousLabel: 'Sebelumnya',
          nextLabel: 'Berikutnya',
          onPrevious: () => back++,
          onNext: null,
        ),
      ),
    );
    expect(find.text('Mei 2024'), findsOneWidget);
    expect(find.text('Periode peralihan · 31 hari'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('period-previous')));
    expect(back, 1);
    expect(tester.widget<DsIconButton>(find.byKey(const ValueKey('period-next'))).onPressed, isNull);
  });

  testWidgets('DsSearchField: mengirim teks dan ikut berubah saat query diganti dari luar', (tester) async {
    String? typed;
    Widget field(String query) => _host(DsSearchField(query: query, onChanged: (v) => typed = v, hint: 'Cari'));
    await tester.pumpWidget(field(''));
    await tester.enterText(find.byType(TextField), 'kopi');
    expect(typed, 'kopi');
    await tester.pumpWidget(field(''));
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, '');
  });

  testWidgets('DsFilterChip: ketukan diteruskan', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(DsFilterChip(label: 'Semua 3', selected: true, onTap: () => taps++)));
    await tester.tap(find.text('Semua 3'));
    expect(taps, 1);
  });

  testWidgets('pemilih periode, kolom cari, dan chip tidak luap di 320dp dengan teks 2x', (tester) async {
    tester.view
      ..physicalSize = const Size(320, 600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _host(
        Column(
          children: [
            DsPeriodStepper(
              title: '25 Okt – 24 Nov',
              tag: 'Periode peralihan · 31 hari',
              previousLabel: 'a',
              nextLabel: 'b',
              onPrevious: () {},
              onNext: () {},
            ),
            DsSearchField(query: '', onChanged: (_) {}, hint: 'Cari di periode ini: catatan / kategori...'),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [DsFilterChip(label: 'Pengeluaran 12', selected: false, onTap: () {})]),
            ),
          ],
        ),
        textScale: 2,
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
