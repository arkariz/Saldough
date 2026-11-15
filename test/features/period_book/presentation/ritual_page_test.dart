import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/period_book/domain/entities/closed_period.dart';
import 'package:saldough/features/period_book/domain/entities/ritual_info.dart';
import 'package:saldough/features/period_book/presentation/pages/ritual_page.dart';
import 'package:saldough/features/period_book/presentation/period_book_ritual_access.dart';

import '../../../helpers/reduced_motion.dart';

final class _Access implements PeriodBookRitualAccess {
  _Access(this.result);
  RitualLoad result;
  final List<(String, RitualStep)> done = [];
  final List<String> finished = [];
  final List<String> categorized = [];
  int recurring = 0;

  @override
  Future<RitualLoad> load(String periodId) async => result;

  @override
  Future<void> markStepDone(String periodId, RitualStep step) async => done.add((periodId, step));

  @override
  Future<void> finish(String periodId) async => finished.add(periodId);

  @override
  Future<void> categorize(BuildContext context, String transactionId) async => categorized.add(transactionId);

  @override
  void showRecurring(BuildContext context) => recurring++;
}

ClosedPeriod _period() =>
    ClosedPeriod(period: financialPeriodOf(DateTime(2026, 10), FinancialMonthSchedule.initial), transactionCount: 12);

RitualReady _ready({
  List<RitualUntagged> untagged = const [],
  int open = 0,
  int? planned,
  int? spent,
  RitualStep resume = RitualStep.uncategorized,
}) => RitualReady(
  info: RitualInfo(period: _period(), untagged: untagged, openRoutines: open, planned: planned, spent: spent),
  resume: resume,
);

final _untagged = [
  RitualUntagged(transactionId: 'a', date: DateTime(2026, 10, 3), amount: 2500000, note: 'Kopi', isIncome: false),
  RitualUntagged(transactionId: 'b', date: DateTime(2026, 10, 9), amount: 5000000, note: '', isIncome: false),
];

Widget _host(Widget page) => MaterialApp(theme: DsTheme.light, builder: reducedMotion, home: page);

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.id));

  testWidgets('semua rapi: tiga langkah dengan keadaan rapi, penutup menandai buku dibuka dan menutup layar', (tester) async {
    final access = _Access(_ready(planned: 500000000, spent: 184000000));
    await tester.pumpWidget(_host(RitualPage(access: access, periodId: '2026-10-01')));
    await tester.pumpAndSettle();
    expect(find.text(t.book.ritual.uncategorized.none), findsOneWidget);

    await tester.tap(find.text(t.book.ritual.next));
    await tester.pumpAndSettle();
    expect(find.text(t.book.ritual.recurring.none), findsOneWidget);

    await tester.tap(find.text(t.book.ritual.next));
    await tester.pumpAndSettle();
    expect(find.text(t.book.ritual.review), findsOneWidget);
    expect(find.text(t.book.ritual.note), findsOneWidget, reason: 'tidak mengunci (BP-5)');
    expect(find.text(t.book.ritual.next), findsNothing);

    await tester.tap(find.text(t.book.ritual.finish));
    await tester.pumpAndSettle();
    expect(access.finished, ['2026-10-01']);
    expect(access.done.map((e) => e.$2), [RitualStep.uncategorized, RitualStep.routines, RitualStep.review]);
  });

  testWidgets('Lewati tidak menandai langkah selesai; Lanjut menandai (BP-6)', (tester) async {
    final access = _Access(_ready());
    await tester.pumpWidget(_host(RitualPage(access: access, periodId: 'p')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.book.ritual.skip));
    await tester.pumpAndSettle();
    expect(access.done, isEmpty);
    await tester.tap(find.text(t.book.ritual.next));
    await tester.pumpAndSettle();
    expect(access.done.map((e) => e.$2), [RitualStep.routines]);
  });

  testWidgets('ada yang tanpa kategori: daftar ringkas dua transaksi, Beri kategori membuka penyunting, langkah muat ulang', (tester) async {
    final access = _Access(_ready(untagged: _untagged));
    await tester.pumpWidget(_host(RitualPage(access: access, periodId: 'p')));
    await tester.pumpAndSettle();
    expect(find.text(t.book.ritual.uncategorized.some(n: 2, count: 2)), findsOneWidget);
    expect(find.text('Kopi'), findsOneWidget);
    access.result = _ready();
    await tester.tap(find.text(t.book.ritual.fix));
    await tester.pumpAndSettle();
    expect(access.categorized, ['a']);
    expect(find.text(t.book.ritual.uncategorized.none), findsOneWidget, reason: 'rapi setelah diberi kategori');
  });

  testWidgets('rutin menunggu: jumlah dan jalan ke Rutin', (tester) async {
    final access = _Access(_ready(open: 3, resume: RitualStep.routines));
    await tester.pumpWidget(_host(RitualPage(access: access, periodId: 'p')));
    await tester.pumpAndSettle();
    expect(find.text(t.book.ritual.recurring.some(n: 3, count: 3)), findsOneWidget);
    await tester.tap(find.text(t.book.ritual.seeRoutines));
    expect(access.recurring, 1);
  });

  testWidgets('tanpa anggaran: baris info, tanpa ubin; melanjutkan di langkah tersimpan', (tester) async {
    final access = _Access(_ready(resume: RitualStep.review));
    await tester.pumpWidget(_host(RitualPage(access: access, periodId: 'p')));
    await tester.pumpAndSettle();
    expect(find.text(t.book.ritual.noPlan), findsOneWidget);
    expect(find.text(t.book.ritual.planned.toUpperCase()), findsNothing);
  });

  testWidgets('terkunci atau gagal: tidak menampilkan isi ritual', (tester) async {
    for (final result in [const RitualLocked(), const RitualFailed()]) {
      await tester.pumpWidget(_host(RitualPage(access: _Access(result), periodId: 'p')));
      await tester.pumpAndSettle();
      expect(find.byType(DsButton), findsNothing);
    }
  });
}
