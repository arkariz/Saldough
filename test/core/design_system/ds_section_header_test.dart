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

  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      theme: AppThemeBridge.build(DsThemePresets.fallback, Brightness.light),
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );

  testWidgets('DsSectionHeader: tautan Semua menempel di tepi kanan, sejajar kartu di bawahnya', (tester) async {
    await pump(
      tester,
      const Column(
        children: [
          DsSectionHeader(title: 'Transaksi terbaru', actionLabel: 'Semua'),
          SizedBox(key: ValueKey('card'), width: double.infinity, height: 10),
        ],
      ),
    );
    final right = tester.getTopRight(find.byKey(const ValueKey('card'))).dx;
    // Ikon panah berada paling kanan; tepinya sama dengan tepi kartu.
    expect(tester.getTopRight(find.byIcon(Icons.chevron_right)).dx, closeTo(right, 0.5));
  });

  testWidgets('DsPageHeader: pil di kanan judul menempel di tepi kanan', (tester) async {
    await pump(
      tester,
      const Column(
        children: [
          DsPageHeader(
            title: 'Halo, Kenji!',
            trailing: DsStatusPill(label: 'LVL 12', pulse: false),
          ),
          SizedBox(key: ValueKey('card'), width: double.infinity, height: 10),
        ],
      ),
    );
    final right = tester.getTopRight(find.byKey(const ValueKey('card'))).dx;
    expect(tester.getTopRight(find.byType(DsStatusPill)).dx, closeTo(right, 0.5));
    expect(tester.takeException(), isNull);
  });
}
