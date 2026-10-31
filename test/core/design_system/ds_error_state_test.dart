import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/design_system/design_system.dart';

void main() {
  testWidgets('DsErrorState menampilkan judul, keterangan, dan memanggil coba lagi', (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: DsTheme.light,
        home: Scaffold(
          body: DsErrorState(
            title: 'Gagal memuat',
            body: 'Coba beberapa saat lagi.',
            retryLabel: 'Coba lagi',
            onRetry: () => retries++,
          ),
        ),
      ),
    );
    expect(find.text('Gagal memuat'), findsOneWidget);
    expect(find.text('Coba beberapa saat lagi.'), findsOneWidget);
    await tester.tap(find.text('Coba lagi'));
    expect(retries, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('DsErrorState tidak luap di 320dp dengan teks 2x', (tester) async {
    tester.view
      ..physicalSize = const Size(320, 500)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: DsTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: DsErrorState(
            title: 'Gagal memuat Beranda',
            body: 'Periksa lagi sebentar lagi ya.',
            retryLabel: 'Coba lagi',
            onRetry: () {},
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
