import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/freelance/domain/entities/freelance_payment.dart';
import 'package:saldough/features/freelance/domain/entities/payment_status.dart';
import 'package:saldough/features/freelance/domain/entities/worklog_entry.dart';
import 'package:saldough/features/freelance/domain/usecases/summarize_worklog.dart';

void main() {
  const summarize = SummarizeWorklog();
  const rate = 7250000; // Rp72.500 per jam

  WorklogEntry entry(String id, int hours, {String? paymentId}) => WorklogEntry(
    id: id,
    projectId: 'p1',
    date: DateTime(2026, 9),
    hours: hours,
    hourlyRate: rate,
    paymentId: paymentId,
  );

  final paid = FreelancePayment(
    id: 'bayar-1',
    projectId: 'p1',
    entryIds: const ['a'],
    expectedDate: DateTime(2026, 9, 10),
    status: PaymentStatus.paid,
    walletId: 'bca',
    incomeTransactionId: 'freelance-bayar-1',
    receivedDate: DateTime(2026, 9, 10),
  );
  final pending = FreelancePayment(
    id: 'bayar-2',
    projectId: 'p1',
    entryIds: const ['b'],
    expectedDate: DateTime(2026, 10, 10),
  );

  test('hanya entri yang pembayarannya diterima yang terhitung dibayar (kotor)', () {
    final summary = summarize(
      [entry('a', 37, paymentId: 'bayar-1'), entry('b', 10, paymentId: 'bayar-2'), entry('c', 3)],
      [paid, pending],
    );

    expect(summary.totalHours, 50);
    expect(summary.earned, 50 * rate);
    expect(summary.paid, 268250000, reason: '37 jam × Rp72.500 = Rp2.682.500, kotor');
    expect(summary.unpaid, 13 * rate);
  });

  test('entri yang menunjuk pembayaran yang sudah terhapus dihitung belum diterima', () {
    final summary = summarize([entry('a', 37, paymentId: 'hilang')], [paid]);
    expect(summary.paid, 0);
    expect(summary.unpaid, 37 * rate);
  });

  test('tanpa entri, seluruh angka nol', () {
    final summary = summarize(const [], [paid]);
    expect((summary.totalHours, summary.earned, summary.paid), (0, 0, 0));
  });
}
