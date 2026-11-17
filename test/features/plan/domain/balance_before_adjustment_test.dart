import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/plan/domain/month_review.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// ADR-047 §3.3 dan KT-W1 = B: penyesuaian saldo bertanggal hari ini, jadi saldo
/// hari-hari sebelumnya tidak bergeser.
void main() {
  final income = IncomeTransaction(id: 'gaji', date: DateTime(2026, 10, 25), amount: 1000000, note: '', walletId: 'bca');
  final adjustment = BalanceAdjustmentTransaction(
    id: 'koreksi',
    date: DateTime(2026, 11, 17, 9),
    amount: 50000,
    note: '',
    walletId: 'bca',
    direction: AdjustmentDirection.increase,
  );

  test('saldo sebelum tanggal penyesuaian sama dengan saldo tanpa penyesuaian', () {
    // Saldo awal 0 + gaji 1.000.000 + penyesuaian 50.000.
    final withAdjustment = balanceBefore(
      DateTime(2026, 11),
      currentBalance: 1050000,
      transactions: [income, adjustment],
      walletIds: {'bca'},
    );
    final without = balanceBefore(
      DateTime(2026, 11),
      currentBalance: 1000000,
      transactions: [income],
      walletIds: {'bca'},
    );
    expect(withAdjustment, without);
    expect(withAdjustment, 1000000);
  });

  test('penyesuaian berkurang juga dibalik dengan benar', () {
    final down = BalanceAdjustmentTransaction(
      id: 'turun',
      date: DateTime(2026, 11, 17),
      amount: 20000,
      note: '',
      walletId: 'bca',
      direction: AdjustmentDirection.decrease,
    );
    expect(
      balanceBefore(DateTime(2026, 11, 17), currentBalance: 980000, transactions: [income, down], walletIds: {'bca'}),
      1000000,
    );
  });
}
