import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/freelance/domain/entities/deduction_kind.dart';
import 'package:saldough/features/freelance/domain/entities/deduction_rule.dart';
import 'package:saldough/features/freelance/domain/entities/freelance_payment.dart';
import 'package:saldough/features/freelance/domain/entities/freelance_project.dart';
import 'package:saldough/features/freelance/domain/entities/worklog_entry.dart';
import 'package:saldough/features/freelance/presentation/bloc/freelance_state.dart';

/// Angka ringkasan Ikhtisar Freelance satu layar (T-5.9): total pembayaran
/// bersih lintas proyek dan urutan kartu proyek.
void main() {
  // Potongan per mil: 100 = 10%.
  const tax = DeductionRule(id: 'pajak', label: 'Pajak', kind: DeductionKind.percentage, value: 100);
  const alpha = FreelanceProject(id: 'alpha', name: 'Alpha', hourlyRate: 10000000);
  const beta = FreelanceProject(id: 'beta', name: 'Beta', hourlyRate: 10000000, deductionRules: [tax]);

  WorklogEntry entry(String id, String projectId, int hours, String paymentId) => WorklogEntry(
    id: id,
    projectId: projectId,
    date: DateTime(2026, 9),
    hours: hours,
    hourlyRate: 10000000,
    paymentId: paymentId,
  );

  final state = FreelanceState(
    projects: const [alpha, beta],
    entries: [entry('a1', 'alpha', 10, 'pa'), entry('b1', 'beta', 4, 'pb1'), entry('b2', 'beta', 2, 'pb2')],
    payments: [
      FreelancePayment(id: 'pa', projectId: 'alpha', entryIds: const ['a1'], expectedDate: DateTime(2026, 10, 5)),
      FreelancePayment(
        id: 'pb1',
        projectId: 'beta',
        entryIds: const ['b1'],
        expectedDate: DateTime(2026, 9, 20),
        deductionRules: const [tax],
      ).markPaid(walletId: 'bca', date: DateTime(2026, 9, 21)),
      FreelancePayment(
        id: 'pb2',
        projectId: 'beta',
        entryIds: const ['b2'],
        expectedDate: DateTime(2026, 10),
        deductionRules: const [tax],
      ),
    ],
    wallets: const [],
    isLoading: false,
  );

  test('paymentTotals menjumlahkan gaji bersih seluruh proyek', () {
    final totals = state.paymentTotals;
    // Tertunda: Alpha Rp1.000.000 utuh + Beta Rp200.000 − 10% = Rp1.180.000.
    expect(totals.pendingCount, 2);
    expect(totals.pendingNet, 118000000);
    expect(totals.nextExpectedDate, DateTime(2026, 10));
    // Diterima: Beta Rp400.000 − 10% = Rp360.000.
    expect(totals.paidCount, 1);
    expect(totals.paidNet, 36000000);
    // Sama dengan total yang sudah ada, supaya ringkasan tidak pernah
    // berbeda dari jumlah kartu proyek.
    expect(totals.pendingNet, state.pendingNetTotal);
    expect(totals.paidNet, state.paidNetTotal);
  });

  test('kartu proyek diurutkan menurut perkiraan pembayaran tertunda terdekat', () {
    expect(state.projectsByNextPayment.map((p) => p.id), ['beta', 'alpha']);
  });
}
