import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/record/domain/budget_item_catalog.dart';
import 'package:saldough/features/record/presentation/widgets/record_budget_item_field.dart';

void main() {
  final september = (start: DateTime(2026, 9), end: DateTime(2026, 10));
  final beras = BudgetItemOption(
    budgetId: 'b1',
    budgetName: 'Rumah tangga',
    itemId: 'beras',
    itemName: 'Beras',
    walletId: 'bca',
    startDate: september.start,
    endDate: september.end,
  );
  final setoran = BudgetItemOption(
    budgetId: 'b1',
    budgetName: 'Rumah tangga',
    itemId: 'setoran',
    itemName: 'Setoran tabungan',
    walletId: 'bca',
    startDate: september.start,
    endDate: september.end,
    transferToWalletId: 'tabungan',
  );
  final kopi = BudgetItemOption(
    budgetId: 'b2',
    budgetName: 'Jajan',
    itemId: 'kopi',
    itemName: 'Kopi',
    walletId: 'gopay',
    startDate: september.start,
    endDate: september.end,
  );
  final listrik = BudgetItemOption(
    budgetId: 'b3',
    budgetName: 'Agustus',
    itemId: 'listrik',
    itemName: 'Listrik',
    walletId: 'bca',
    startDate: DateTime(2026, 8),
    endDate: september.start,
  );
  final gas = BudgetItemOption(
    budgetId: 'b4',
    budgetName: 'Diarsipkan',
    itemId: 'gas',
    itemName: 'Gas',
    walletId: 'bca',
    startDate: september.start,
    endDate: september.end,
    isArchived: true,
  );
  final all = [beras, setoran, kopi, listrik, gas];
  final sep15 = DateTime(2026, 9, 15, 10, 30);

  group('BudgetItemOption.covers (KT-1)', () {
    test('awal periode masuk, akhir periode tidak', () {
      expect(beras.covers(DateTime(2026, 9)), isTrue);
      expect(beras.covers(DateTime(2026, 9, 30, 23, 59)), isTrue);
      expect(beras.covers(DateTime(2026, 10)), isFalse);
      expect(beras.covers(DateTime(2026, 8, 31, 23, 59)), isFalse);
    });
  });

  group('expenseBudgetChoicesFor (ADR-018, KT-1)', () {
    test('hanya pos PENGELUARAN milik dompet asal yang periodenya mencakup tanggal', () {
      expect(expenseBudgetChoicesFor(all, 'bca', null, sep15), [beras]);
      expect(expenseBudgetChoicesFor(all, 'gopay', null, sep15), [kopi]);
    });

    test('tanggal menentukan periode: transaksi Agustus hanya ditawari pos anggaran Agustus', () {
      expect(expenseBudgetChoicesFor(all, 'bca', null, DateTime(2026, 8, 20)), [listrik]);
    });

    test('pos transfer tidak pernah ditawarkan ke pengeluaran', () {
      expect(expenseBudgetChoicesFor(all, 'bca', 'setoran', sep15), [beras]);
    });

    test('tanpa dompet terpilih, tidak ada pilihan', () {
      expect(expenseBudgetChoicesFor(all, null, null, sep15), isEmpty);
    });

    test('pos anggaran diarsipkan hanya muncul kalau sedang dipakai transaksi yang disunting', () {
      expect(expenseBudgetChoicesFor(all, 'bca', 'gas', sep15), [beras, gas]);
    });

    test('pos terpilih di luar periode tanggalnya tidak ditawarkan', () {
      expect(expenseBudgetChoicesFor(all, 'bca', 'listrik', sep15), [beras]);
    });
  });

  group('transferBudgetChoicesFor (ADR-018, KT-1)', () {
    test('hanya pos TRANSFER dengan dompet asal dan tujuan yang cocok', () {
      expect(transferBudgetChoicesFor(all, 'bca', 'tabungan', null, sep15), [setoran]);
    });

    test('di luar periode: pos transfer tidak ditawarkan', () {
      expect(transferBudgetChoicesFor(all, 'bca', 'tabungan', null, DateTime(2026, 10, 2)), isEmpty);
    });

    test('dompet tujuan lain: pos transfer tidak ditawarkan', () {
      expect(transferBudgetChoicesFor(all, 'bca', 'gopay', null, sep15), isEmpty);
    });

    test('dompet tujuan belum dipilih: belum ada pilihan', () {
      expect(transferBudgetChoicesFor(all, 'bca', null, null, sep15), isEmpty);
    });

    test('pos pengeluaran tidak pernah ditawarkan ke transfer', () {
      expect(transferBudgetChoicesFor(all, 'bca', 'tabungan', 'beras', sep15), [setoran]);
    });
  });

  group('budgetItemOutsidePeriod (KT-1)', () {
    test('memberi pos terpilih yang lepas karena tanggalnya di luar periode', () {
      expect(budgetItemOutsidePeriod(all, 'beras', DateTime(2026, 10)), beras);
    });

    test('null kalau tanggal di dalam periode atau tidak ada pos terpilih', () {
      expect(budgetItemOutsidePeriod(all, 'beras', sep15), isNull);
      expect(budgetItemOutsidePeriod(all, null, DateTime(2026, 10)), isNull);
    });
  });
}
