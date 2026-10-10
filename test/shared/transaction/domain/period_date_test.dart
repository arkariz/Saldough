import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Tanggal periode transaksi (ADR-038 §3.5, FINANCIAL_PERIOD P-4).
void main() {
  final occurrence = DateTime(2026, 10, 25);

  IncomeTransaction gaji(DateTime date, {bool linked = true}) => IncomeTransaction(
    id: 'gaji',
    date: date,
    amount: 1200000000,
    note: 'Gaji',
    walletId: 'bca',
    recurrence: linked ? RecurrenceLink(ruleId: 'gaji', occurrenceDate: occurrence) : null,
  );

  test('tanpa tautan rutin: date', () {
    final date = DateTime(2026, 10, 23, 9);
    expect(periodDateOf(gaji(date, linked: false)), date);
  });

  test('tertaut, cair 2 hari lebih awal (contoh D): tanggal kemunculan', () {
    expect(periodDateOf(gaji(DateTime(2026, 10, 23, 9))), occurrence);
  });

  test('batas 7 hari berlaku di kedua arah; 8 hari kembali ke date', () {
    expect(periodDateOf(gaji(DateTime(2026, 10, 18, 23))), occurrence);
    expect(periodDateOf(gaji(DateTime(2026, 11, 1, 8))), occurrence);
    expect(periodDateOf(gaji(DateTime(2026, 10, 17, 9))), DateTime(2026, 10, 17, 9));
    expect(periodDateOf(gaji(DateTime(2026, 11, 2))), DateTime(2026, 11, 2));
  });
}
