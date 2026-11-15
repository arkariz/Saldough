import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/features/period_book/domain/entities/closed_period.dart';
import 'package:saldough/features/period_book/domain/entities/period_book_memory.dart';
import 'package:saldough/features/period_book/domain/services/closed_periods.dart';
import 'package:saldough/features/period_book/domain/services/period_book_shelf.dart';
import 'package:saldough/shared/transaction/transaction.dart';

final DateTime today = DateTime(2026, 11, 14);
final FinancialMonthSchedule calendar = FinancialMonthSchedule.initial;

ExpenseTransaction tx(String id, DateTime date, {RecurrenceLink? recurrence}) => ExpenseTransaction(
  id: id,
  date: date,
  amount: 1000,
  note: '',
  walletId: 'w',
  categoryId: 'c',
  recurrence: recurrence,
);

List<Transaction> many(int n, DateTime month) => [for (var i = 0; i < n; i++) tx('${month.month}-$i', DateTime(month.year, month.month, 2 + i))];

List<ClosedPeriod> closed(List<Transaction> t) => closedPeriodsOf(transactions: t, schedule: calendar, today: today);

void main() {
  group('closedPeriodsOf', () {
    test('periode berjalan tidak punya buku; yang sudah berakhir terbaru di atas', () {
      final result = closed([...many(2, DateTime(2026, 11)), ...many(3, DateTime(2026, 10)), ...many(1, DateTime(2026, 9))]);
      expect(result.map((c) => (c.id, c.transactionCount)), [('2026-10-01', 3), ('2026-09-01', 1)]);
    });

    test('periode kosong tidak ada; hari terakhir periode belum tertutup, hari berikutnya sudah', () {
      final t = [tx('a', DateTime(2026, 10, 31))];
      expect(closedPeriodsOf(transactions: t, schedule: calendar, today: DateTime(2026, 10, 31)), isEmpty);
      expect(closedPeriodsOf(transactions: t, schedule: calendar, today: DateTime(2026, 11)), hasLength(1));
      expect(closed(const []), isEmpty);
    });

    test('transaksi tertaut rutin dihitung ke periode kemunculannya (periodDateOf)', () {
      final t = [
        tx('a', DateTime(2026, 11, 2), recurrence: RecurrenceLink(ruleId: 'r', occurrenceDate: DateTime(2026, 10, 30))),
      ];
      expect(closed(t).single.id, '2026-10-01');
    });

    test('jadwal tanggal 25 dan periode peralihan memakai id awal periodenya sendiri', () {
      final schedule25 = FinancialMonthSchedule.single(const FinancialMonthStart.day(25));
      final t = [tx('a', DateTime(2026, 9, 26)), tx('b', DateTime(2026, 11, 10))];
      final result = closedPeriodsOf(transactions: t, schedule: schedule25, today: today);
      expect(result.map((c) => c.id), ['2026-09-25']);
    });
  });

  group('shelfOf', () {
    final periods = closed([...many(3, DateTime(2026, 10)), ...many(2, DateTime(2026, 9)), ...many(1, DateTime(2026, 8))]);
    final memory = PeriodBookMemory.empty.withOpened('2026-09-01', DateTime(2026, 11, 2));

    test('Plus: yang pernah dibuka terbuka, sisanya Belum dibuka', () {
      final shelf = shelfOf(closed: periods, memory: memory, plusActive: true);
      expect(shelf.map((e) => e.status), [ShelfStatus.unopened, ShelfStatus.opened, ShelfStatus.unopened]);
    });

    test('bukan Plus: yang pernah dibuka tetap terbuka (BP-10), sisanya terkunci', () {
      final shelf = shelfOf(closed: periods, memory: memory, plusActive: false);
      expect(shelf.map((e) => e.status), [ShelfStatus.locked, ShelfStatus.opened, ShelfStatus.locked]);
    });
  });

  group('invitationFor', () {
    final prev = DateTime(2026, 10);
    final periods = closed(many(3, DateTime(2026, 10)));

    PeriodInvitation? invite({List<ClosedPeriod>? closedList, PeriodBookMemory? memory, bool plus = true}) =>
        invitationFor(closed: closedList ?? periods, memory: memory ?? PeriodBookMemory.empty, plusActive: plus, previousPeriodStart: prev);

    test('Plus: ajakan buku; Gratis: ajakan kartu', () {
      expect(invite()?.kind, InvitationKind.book);
      expect(invite(plus: false)?.kind, InvitationKind.card);
    });

    test('hanya periode tepat sebelum yang berjalan dan butuh ≥3 transaksi (BP-2, BP-9, BP-20)', () {
      expect(invite(closedList: closed(many(2, DateTime(2026, 10)))), isNull);
      expect(invite(closedList: closed(many(5, DateTime(2026, 9)))), isNull, reason: 'periode lebih lama masuk Rak, bukan ajakan');
      expect(invite(closedList: const []), isNull);
    });

    test('"Nanti" menutup kartu untuk periode itu (BP-2)', () {
      final memory = PeriodBookMemory.empty.withCardDismissed('2026-10-01');
      expect(invite(memory: memory), isNull);
      expect(invite(memory: memory, plus: false), isNull);
    });

    test('Plus: sakelar ajakan mati atau buku sudah dibuka = tidak diajak (BP-14)', () {
      expect(invite(memory: PeriodBookMemory.empty.withInviteEnabled(enabled: false)), isNull);
      expect(invite(memory: PeriodBookMemory.empty.withOpened('2026-10-01', DateTime(2026, 11, 3))), isNull);
      expect(
        invite(memory: PeriodBookMemory.empty.withInviteEnabled(enabled: false), plus: false)?.kind,
        InvitationKind.card,
        reason: 'sakelar hanya untuk Plus; Gratis tetap melihat kartu',
      );
    });
  });

  test('previousPeriodOf: periode tepat sebelum periode berjalan', () {
    expect(previousPeriodOf(today, calendar).start, DateTime(2026, 10));
    final schedule25 = FinancialMonthSchedule.single(const FinancialMonthStart.day(25));
    expect(previousPeriodOf(today, schedule25).start, DateTime(2026, 9, 25));
  });
}
