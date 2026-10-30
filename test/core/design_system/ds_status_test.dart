import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/design_system/design_system.dart';

import '../../helpers/reduced_motion.dart';

DsStatusSlideData _data(
  String id, {
  bool attention = false,
  int order = 0,
  String? title,
  VoidCallback? onAction,
}) => DsStatusSlideData(
  id: id,
  icon: Icons.event_note,
  title: title ?? 'Judul $id',
  subtitle: 'Keterangan $id',
  actionLabel: 'Cek',
  onAction: onAction,
  attention: attention,
  order: order,
);

Widget _host(Widget child) => MaterialApp(
  theme: DsTheme.light,
  builder: reducedMotion,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  group('DsStatusBoard', () {
    test('urut: perlu dicek dulu, lalu order, lalu id', () {
      final board = DsStatusBoard()
        ..report('reminder', _data('reminder', order: 2))
        ..report('notification', _data('notification', order: 1))
        ..report('recurring', _data('recurring', attention: true));
      expect(board.slides.map((s) => s.id), ['recurring', 'notification', 'reminder']);
    });

    test('mencabut dengan null dan memberi tahu hanya bila tampilan berubah', () {
      var calls = 0;
      final board = DsStatusBoard()
        ..addListener(() => calls++)
        ..report('a', _data('a', title: 'Satu'));
      expect(calls, 1);
      // Tampilan sama (hanya penutup berbeda): tidak membangunkan pendengar.
      board.report('a', _data('a', title: 'Satu', onAction: () {}));
      expect(calls, 1);
      board.report('a', _data('a', title: 'Dua'));
      expect(calls, 2);
      board.report('a', null);
      expect(board.slides, isEmpty);
      expect(calls, 3);
      board.report('a', null);
      expect(calls, 3);
    });

    test('penutup terbaru yang dipakai walau tampilan tidak berubah', () {
      final board = DsStatusBoard();
      var which = 0;
      board
        ..report('a', _data('a', onAction: () => which = 1))
        ..report('a', _data('a', onAction: () => which = 2))
        ..slides.single.onAction!();
      expect(which, 2);
    });

    test('laporan tertunda sesudah dibuang tidak melempar', () {
      final board = DsStatusBoard()..dispose();
      expect(() => board.report('a', _data('a')), returnsNormally);
    });
  });

  group('DsStatusReport', () {
    testWidgets('melapor saat terpasang, memperbarui, dan mencabut saat dilepas', (tester) async {
      final board = DsStatusBoard();
      addTearDown(board.dispose);
      await tester.pumpWidget(_host(DsStatusReport(board: board, id: 'a', data: _data('a', title: 'Satu'))));
      await tester.pump();
      expect(board.slides.single.title, 'Satu');
      await tester.pumpWidget(_host(DsStatusReport(board: board, id: 'a', data: _data('a', title: 'Dua'))));
      await tester.pump();
      expect(board.slides.single.title, 'Dua');
      await tester.pumpWidget(_host(const SizedBox()));
      await tester.pump();
      expect(board.slides, isEmpty);
    });
  });

  group('DsStatusCarousel', () {
    DsStatusCarousel carousel(DsStatusBoard board, {Widget? trailing}) => DsStatusCarousel(
      board: board,
      trailing: trailing,
      previousLabel: 'Sebelumnya',
      nextLabel: 'Berikutnya',
      dotLabel: (i) => 'Kartu ${i + 1}',
    );

    testWidgets('kosong: tidak ada apa pun', (tester) async {
      final board = DsStatusBoard();
      addTearDown(board.dispose);
      await tester.pumpWidget(_host(carousel(board)));
      expect(find.byType(DsStatusSlide), findsNothing);
      expect(find.byType(DsCarousel), findsNothing);
    });

    testWidgets('satu slide: tanpa titik; dua atau lebih: carousel dengan titik', (tester) async {
      final board = DsStatusBoard();
      addTearDown(board.dispose);
      board.report('a', _data('a', attention: true));
      await tester.pumpWidget(_host(carousel(board)));
      expect(find.byType(DsCarousel), findsNothing);
      expect(find.byKey(const ValueKey('status-slide-a')), findsOneWidget);
      board.report('b', _data('b', order: 1));
      await tester.pump();
      expect(find.byType(DsCarousel), findsOneWidget);
      expect(find.byType(DsCarouselDots), findsOneWidget);
    });

    testWidgets('trailing menjadi slide terakhir dan muncul sendiri bila papan kosong', (tester) async {
      final board = DsStatusBoard();
      addTearDown(board.dispose);
      await tester.pumpWidget(_host(carousel(board, trailing: const Text('MOOD'))));
      expect(find.text('MOOD'), findsOneWidget);
      expect(find.byType(DsCarousel), findsNothing);
      board.report('a', _data('a'));
      await tester.pump();
      expect(find.byType(DsCarousel), findsOneWidget);
    });

    testWidgets('slide dicabut saat sedang di halaman terakhir: indeks dikoreksi', (tester) async {
      final board = DsStatusBoard();
      addTearDown(board.dispose);
      board
        ..report('a', _data('a', attention: true))
        ..report('b', _data('b', order: 1));
      await tester.pumpWidget(_host(carousel(board, trailing: const Text('MOOD'))));
      await tester.tap(find.bySemanticsLabel('Kartu 3'));
      await tester.pumpAndSettle();
      expect(find.text('MOOD').hitTestable(), findsOneWidget);
      board
        ..report('a', null)
        ..report('b', null);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('MOOD'), findsOneWidget);
    });
  });

  group('DsStatusSlide', () {
    testWidgets('ketuk slide memanggil onAction; semantik tombol memuat judul dan keterangan', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_host(DsStatusSlide(data: _data('a', onAction: () => taps++))));
      await tester.tap(find.text('Judul a'));
      expect(taps, 1);
      expect(find.text('CEK'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Judul a. Keterangan a')), findsOneWidget);
    });

    testWidgets('judul dan keterangan panjang di 360px + teks 2x tidak luap', (tester) async {
      tester.view.physicalSize = const Size(360, 1200);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(() {
        tester.view.reset();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });
      await tester.pumpWidget(
        _host(DsStatusSlide(data: _data('a', title: 'Menunggu dicatat (12) yang sangat panjang sekali', onAction: () {}))),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
