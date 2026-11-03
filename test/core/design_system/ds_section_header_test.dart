import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/design_system/design_system.dart';

void main() {
  testWidgets('DsSectionHeader: judul dan tautan panjang tidak meluap di 280dp dengan teks 200%', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemeBridge.build(DsThemePresets.fallback, Brightness.light),
        builder: (c, child) => MediaQuery(
          data: MediaQuery.of(c).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const Scaffold(
          body: SizedBox(
            width: 280,
            child: DsSectionHeader(title: 'Berikutnya bulan ini', actionLabel: 'Semua di Rutin'),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
