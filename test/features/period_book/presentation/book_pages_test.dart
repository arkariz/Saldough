import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/period_book/domain/entities/closed_period.dart';
import 'package:saldough/features/period_book/domain/entities/period_book_content.dart';
import 'package:saldough/features/period_book/presentation/pages/book_cover_page.dart';
import 'package:saldough/features/period_book/presentation/pages/book_report_page.dart';
import 'package:saldough/features/period_book/presentation/period_book_read_access.dart';

import '../../../helpers/reduced_motion.dart';

final class _Access implements PeriodBookReadAccess {
  _Access(this.result);
  BookLoad result;
  int opened = 0;
  int categorized = 0;

  @override
  Future<BookLoad> open(String periodId) async {
    opened++;
    return result;
  }

  @override
  Future<void> categorizeFirstUntagged(BuildContext context, String periodId) async => categorized++;
}

ClosedPeriod _period({FinancialMonthSchedule? schedule, DateTime? at}) => ClosedPeriod(
  period: financialPeriodOf(at ?? DateTime(2026, 10), schedule ?? FinancialMonthSchedule.initial),
  transactionCount: 12,
);

PeriodBookContent _content({
  int income = 850000000,
  int expense = 470500000,
  int untagged = 0,
  bool spending = true,
  bool compare = true,
  BookPlan? plan = const BookPlan(recorded: 2, skipped: 1, planned: 500000000, spent: 184000000),
}) => PeriodBookContent(
  period: _period(),
  flow: BookFlow(income: income, expense: expense),
  uncategorizedCount: untagged,
  spending: spending
      ? const BookSpending(
          total: 470500000,
          count: 12,
          rows: [
            BookSpendRow(kind: BookRowKind.category, amount: 164000000, count: 5, percent: 35, categoryId: 'makan', categoryName: 'Makan'),
            BookSpendRow(kind: BookRowKind.uncategorized, amount: 1000000, count: 1, percent: 0, belowOne: true),
          ],
        )
      : null,
  compare: compare
      ? const BookCompare(
          months: 3,
          highlights: [
            BookHighlight(kind: BookRowKind.category, amount: 180000000, average: 100000000, percent: 80, isHigher: true, categoryId: 'makan', categoryName: 'Makan'),
          ],
        )
      : null,
  plan: plan,
);

Widget _host(Widget page) => MaterialApp(theme: DsTheme.light, builder: reducedMotion, home: page);

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.id));

  group('sampul', () {
    testWidgets('membuka buku, menampilkan nama periode dan stempel tercetak, tombol Buka rapor', (tester) async {
      final access = _Access(BookReady(content: _content(), stamps: const ['period_tidy', 'recurring_clear']));
      await tester.pumpWidget(_host(BookCoverPage(access: access, periodId: '2026-10-01')));
      await tester.pumpAndSettle();
      expect(access.opened, 1);
      expect(find.text('Oktober'), findsOneWidget);
      expect(find.text(t.book.cover.openReport), findsOneWidget);
      expect(find.byType(DsStampSeal), findsNWidgets(2));
      expect(
        find.bySemanticsLabel(RegExp('${t.stamps.names.period_tidy}.*${t.stamps.names.recurring_clear}')),
        findsOneWidget,
        reason: 'pembaca layar mendengar stempel di sampul',
      );
    });

    testWidgets('nol stempel: ruang kosong tanpa tulisan "belum ada"', (tester) async {
      await tester.pumpWidget(_host(BookCoverPage(access: _Access(BookReady(content: _content(), stamps: const [])), periodId: 'p')));
      await tester.pumpAndSettle();
      expect(find.textContaining('belum'), findsNothing);
      expect(find.byType(DsStampSeal), findsNothing);
    });

    testWidgets('terkunci atau gagal: tidak menampilkan buku', (tester) async {
      for (final r in [const BookLocked(), const BookFailed()]) {
        await tester.pumpWidget(_host(BookCoverPage(access: _Access(r), periodId: 'p')));
        await tester.pumpAndSettle();
        expect(find.byType(DsButton), findsNothing);
      }
    });
  });

  group('rapor', () {
    Future<void> pump(WidgetTester tester, PeriodBookContent content, {_Access? access}) async {
      await tester.pumpWidget(_host(BookReportPage(access: access ?? _Access(BookReady(content: content, stamps: const [])), periodId: 'p')));
      await tester.pumpAndSettle();
    }

    Future<void> next(WidgetTester tester) async {
      await tester.drag(find.byType(PageView), const Offset(-600, 0));
      await tester.pumpAndSettle();
    }

    testWidgets('halaman 1: kalimat netral, pemasukan, pengeluaran, selisih', (tester) async {
      await pump(tester, _content());
      expect(find.text(t.book.report.flowPositive), findsOneWidget);
      expect(find.text(t.book.report.income.toUpperCase()), findsOneWidget);
      expect(find.text(t.book.report.net.toUpperCase()), findsOneWidget);
    });

    testWidgets('selisih negatif: kalimat netral tanpa warna peringatan', (tester) async {
      await pump(tester, _content(income: 100, expense: 400));
      expect(find.text(t.book.report.flowNegative), findsOneWidget);
    });

    testWidgets('lima halaman bila semua data ada: Arus, Ke mana, Dibanding, Rutin, Kata Tanuki', (tester) async {
      await pump(tester, _content());
      expect(find.bySemanticsLabel(t.book.page.label(current: 1, total: 5)), findsOneWidget);
      await next(tester);
      expect(find.text(t.book.page.where), findsOneWidget);
      expect(find.text('35%'), findsOneWidget);
      expect(find.text(t.book.report.belowOne), findsOneWidget);
      await next(tester);
      expect(find.text(t.book.page.compare), findsOneWidget);
      expect(find.text('+80%'), findsOneWidget);
      await next(tester);
      expect(find.text(t.book.page.recurring), findsOneWidget);
      await next(tester);
      expect(find.text(t.book.page.tanuki), findsOneWidget);
    });

    testWidgets('halaman tanpa data dilewati dan titik menyesuaikan', (tester) async {
      await pump(tester, _content(spending: false, compare: false, plan: null));
      expect(find.bySemanticsLabel(t.book.page.label(current: 1, total: 2)), findsOneWidget);
    });

    testWidgets('catatan netral tanpa kategori dengan Beri kategori', (tester) async {
      final access = _Access(BookReady(content: _content(untagged: 2), stamps: const []));
      await pump(tester, _content(untagged: 2), access: access);
      await next(tester);
      expect(find.text(t.book.report.noteUncategorized(n: 2, count: 2)), findsOneWidget);
      await tester.tap(find.text(t.book.ritual.fix));
      expect(access.categorized, 1);
    });
  });
}
