import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/card/domain/entities/card_statement_period.dart';

void main() {
  group('CardStatementPeriod.forDate', () {
    test('tanggal tepat di hari cetak masuk periode yang berakhir hari itu juga', () {
      final period = CardStatementPeriod.forDate(DateTime(2026, 9, 15), 15);
      expect(period.start, DateTime(2026, 8, 16));
      expect(period.end, DateTime(2026, 9, 15));
    });

    test('tanggal sehari setelah hari cetak masuk periode berikutnya', () {
      final period = CardStatementPeriod.forDate(DateTime(2026, 9, 16), 15);
      expect(period.start, DateTime(2026, 9, 16));
      expect(period.end, DateTime(2026, 10, 15));
    });

    test('tanggal sehari sebelum hari cetak masih masuk periode berjalan', () {
      final period = CardStatementPeriod.forDate(DateTime(2026, 9, 14), 15);
      expect(period.start, DateTime(2026, 8, 16));
      expect(period.end, DateTime(2026, 9, 15));
    });

    test('periode yang melewati pergantian tahun dihitung benar', () {
      final period = CardStatementPeriod.forDate(DateTime(2025, 12, 20), 15);
      expect(period.start, DateTime(2025, 12, 16));
      expect(period.end, DateTime(2026, 1, 15));
    });
  });

  group('CardStatementPeriod.next', () {
    test('periode berikutnya bersambung tanpa celah atau tumpang tindih', () {
      final current = CardStatementPeriod(start: DateTime(2026, 8, 16), end: DateTime(2026, 9, 15));
      final next = current.next(15);
      expect(next.start, DateTime(2026, 9, 16));
      expect(next.end, DateTime(2026, 10, 15));
    });
  });
}
