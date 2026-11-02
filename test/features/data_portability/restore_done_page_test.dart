import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/data_portability/domain/restore_models.dart';
import 'package:saldough/features/data_portability/presentation/pages/restore_done_page.dart';

void main() {
  Future<void> pump(WidgetTester tester, {required bool reduced, RestoreKind kind = RestoreKind.account}) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemeBridge.build(DsThemePresets.fallback, Brightness.light),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
          child: child!,
        ),
        home: RestoreDonePage(
          report: RestoreReport(kind: kind, backupCreatedAt: DateTime(2026, 10, 12)),
        ),
      ),
    );
  }

  testWidgets('gerak dikurangi: judul, tiga hal yang kembali, dan tombol Ke Beranda langsung tampil', (tester) async {
    await pump(tester, reduced: true);
    await tester.pumpAndSettle();

    expect(find.textContaining('12 Okt 2026'), findsOneWidget);
    for (final label in t.dataPortability.restoreDoneKept) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('restore-home')), findsOneWidget);
  });

  testWidgets('beranimasi: bagian muncul bertahap tanpa galat dan semuanya terlihat di akhir', (tester) async {
    await pump(tester, reduced: false);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 3));

    expect(tester.takeException(), isNull);
    for (final label in t.dataPortability.restoreDoneKept) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('kembalikan: memakai judul undo', (tester) async {
    await pump(tester, reduced: true, kind: RestoreKind.undo);
    await tester.pumpAndSettle();
    expect(find.text(t.dataPortability.undoDoneTitle), findsOneWidget);
  });
}
