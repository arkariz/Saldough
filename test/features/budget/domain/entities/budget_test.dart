import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/budget/domain/entities/budget.dart';
import 'package:saldough/features/budget/domain/entities/budget_period.dart';

/// Periode anggaran sebagai batas tautan transaksi (keputusan KT-1).
void main() {
  Budget budget(BudgetPeriod period, DateTime start) =>
      Budget(id: 'b', name: 'b', walletId: 'bca', period: period, startDate: start);

  group('Budget.covers', () {
    final september = budget(BudgetPeriod.monthly, DateTime(2026, 9, 1, 14));

    test('mencakup awal periode sejak tengah malam, walau startDate berjam', () {
      expect(september.covers(DateTime(2026, 9)), isTrue);
      expect(september.covers(DateTime(2026, 9, 30, 23, 59)), isTrue);
    });

    test('tidak mencakup sehari sebelumnya maupun endDate (eksklusif)', () {
      expect(september.covers(DateTime(2026, 8, 31, 23, 59)), isFalse);
      expect(september.covers(DateTime(2026, 10)), isFalse);
    });
  });

  group('Budget.months', () {
    test('bulanan mulai tanggal 1: ditambah bulan sebelumnya untuk transaksi tertaut rutin (ADR-038 §3.5)', () {
      expect(budget(BudgetPeriod.monthly, DateTime(2026, 9)).months, [DateTime(2026, 8), DateTime(2026, 9)]);
    });

    test('mulai tanggal 8 ke atas: tanpa bulan tetangga; tanggal 7 ke bawah: paling banyak satu', () {
      expect(budget(BudgetPeriod.monthly, DateTime(2026, 9, 8)).months, [DateTime(2026, 9), DateTime(2026, 10)]);
      expect(
        budget(BudgetPeriod.monthly, DateTime(2026, 9, 7)).months,
        [DateTime(2026, 8), DateTime(2026, 9), DateTime(2026, 10)],
      );
    });

    test('bulanan mulai tengah bulan: dua bulan', () {
      expect(budget(BudgetPeriod.monthly, DateTime(2026, 9, 25)).months, [DateTime(2026, 9), DateTime(2026, 10)]);
    });

    test('mingguan melintasi pergantian tahun', () {
      expect(budget(BudgetPeriod.weekly, DateTime(2026, 12, 29)).months, [DateTime(2026, 12), DateTime(2027)]);
    });

    test('mingguan di dalam satu bulan: satu bulan', () {
      expect(budget(BudgetPeriod.weekly, DateTime(2026, 9, 14)).months, [DateTime(2026, 9)]);
    });
  });
}
