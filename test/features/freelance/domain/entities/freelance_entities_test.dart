import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/freelance/domain/entities/freelance_payment.dart';
import 'package:saldough/features/freelance/domain/entities/payment_status.dart';
import 'package:saldough/features/freelance/domain/entities/worklog_entry.dart';

void main() {
  group('WorklogEntry', () {
    test('earnedAmount = jam × tarif milik entri itu sendiri (ADR-019)', () {
      final entry = WorklogEntry(id: 'w1', projectId: 'p', date: DateTime(2026, 9), hours: 37, hourlyRate: 7250000);
      expect(entry.earnedAmount, 268250000);
      expect(entry.isBilled, isFalse);
    });

    test('copyWith bisa mengosongkan catatan dan paymentId', () {
      final entry = WorklogEntry(
        id: 'w1',
        projectId: 'p',
        date: DateTime(2026, 9),
        hours: 1,
        hourlyRate: 100,
        note: 'x',
        paymentId: 'pay',
      );
      final cleared = entry.copyWith(note: () => null, paymentId: () => null);
      expect(cleared.note, isNull);
      expect(cleared.paymentId, isNull);
      expect(cleared.hours, 1);
    });
  });

  group('FreelancePayment', () {
    final payment = FreelancePayment(
      id: 'pay1',
      projectId: 'p',
      entryIds: const ['w1'],
      expectedDate: DateTime(2026, 10),
    );

    test('id transaksi diturunkan dari id pembayaran', () {
      expect(payment.transactionId, 'freelance-pay1');
    });

    test('markPaid mengisi status, dompet, id transaksi, dan tanggal bersamaan', () {
      final paid = payment.markPaid(walletId: 'bca', date: DateTime(2026, 10, 3));
      expect(paid.status, PaymentStatus.paid);
      expect(paid.walletId, 'bca');
      expect(paid.incomeTransactionId, 'freelance-pay1');
      expect(paid.receivedDate, DateTime(2026, 10, 3));
      expect(paid.entryIds, payment.entryIds);
    });

    test('markPending mengosongkan ketiganya bersamaan', () {
      final pending = payment.markPaid(walletId: 'bca', date: DateTime(2026, 10, 3)).markPending();
      expect(pending, payment);
    });

    test('withExpectedDate mempertahankan status', () {
      final paid = payment.markPaid(walletId: 'bca', date: DateTime(2026, 10, 3));
      final moved = paid.withExpectedDate(DateTime(2026, 11));
      expect(moved.expectedDate, DateTime(2026, 11));
      expect(moved.isPaid, isTrue);
      expect(moved.receivedDate, DateTime(2026, 10, 3));
    });
  });
}
