import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/freelance/domain/entities/freelance_project.dart';
import 'package:saldough/features/freelance/presentation/bloc/freelance_state.dart';
import 'package:saldough/features/freelance/presentation/widgets/project_widgets.dart';

void main() {
  const project = FreelanceProject(id: 'p', name: 'Studio Kopi Senja — redesain situs', hourlyRate: 15000000);
  const noPayments = ProjectPaymentStats(
    pendingCount: 0,
    pendingNet: 0,
    nextExpectedDate: null,
    paidCount: 0,
    paidNet: 0,
  );

  ProjectStats stats({required int earned, required int paid}) => ProjectStats(
    entryCount: 3,
    totalHours: 12,
    earned: earned,
    unbilledCount: 0,
    unbilledHours: 0,
    unbilledAmount: 0,
    pendingAmount: 0,
    paidAmount: paid,
    lastEntryDate: DateTime(2026, 11),
  );

  Future<void> pump(WidgetTester tester, Widget child, {double scale = 1}) => tester.pumpWidget(
    MaterialApp(
      theme: AppThemeBridge.build(DsThemePresets.fallback, Brightness.light),
      builder: (context, c) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
        child: c!,
      ),
      home: Scaffold(
        body: SizedBox(width: 360, child: DsListCard(children: [child])),
      ),
    ),
  );

  testWidgets('proyek dengan sisa: nominal belum diterima dan keterangannya, tanpa lencana Lunas', (tester) async {
    var tapped = false;
    await pump(
      tester,
      ProjectCard(
        project: project,
        stats: stats(earned: 18000000, paid: 6000000),
        paymentStats: noPayments,
        onTap: () => tapped = true,
      ),
    );
    expect(find.text(t.freelance.unpaidLabel), findsOneWidget);
    expect(find.text(t.freelance.paidOffBadge), findsNothing);

    await tester.tap(find.byType(ProjectCard));
    expect(tapped, isTrue);
  });

  testWidgets('proyek lunas: lencana Lunas menggantikan nominal', (tester) async {
    await pump(
      tester,
      ProjectCard(
        project: project,
        stats: stats(earned: 18000000, paid: 18000000),
        paymentStats: noPayments,
        onTap: () {},
      ),
    );
    expect(find.text(t.freelance.paidOffBadge), findsOneWidget);
    expect(find.text(t.freelance.unpaidLabel), findsNothing);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('360dp teks ${scale}x: baris proyek bernama panjang tanpa luap', (tester) async {
      await pump(
        tester,
        ProjectCard(
          project: project,
          stats: stats(earned: 18000000, paid: 6000000),
          paymentStats: noPayments,
          onTap: () {},
        ),
        scale: scale,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('keadaan kosong: judul, penjelasan, dan tombol tambah', (tester) async {
    var added = false;
    await pump(
      tester,
      FreelanceEmptyState(
        title: t.freelance.projectsEmptyTitle,
        body: t.freelance.projectsEmpty,
        actionLabel: t.freelance.projectAddTitle,
        onAction: () => added = true,
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(t.freelance.projectsEmptyTitle), findsOneWidget);
    await tester.tap(find.text(t.freelance.projectAddTitle));
    expect(added, isTrue);
  });
}
