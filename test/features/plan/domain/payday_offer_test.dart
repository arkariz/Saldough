import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/features/plan/domain/payday_offer.dart';
import 'package:saldough/shared/transaction/transaction.dart';

void main() {
  const salary = {'builtin.salary'};
  const fresh = (changedByUser: false, offeredRuleIds: <String>{}, paydayCardAnswered: false);

  IncomeTransaction income(
    DateTime date, {
    String? categoryId = 'builtin.salary',
    String? freelancePaymentId,
  }) => IncomeTransaction(
    id: '${date.toIso8601String()}-$categoryId',
    date: date,
    amount: 1000000,
    note: '',
    walletId: 'w',
    categoryId: categoryId,
    freelancePaymentId: freelancePaymentId,
  );

  int? offerFor(
    List<Transaction> ledger, {
    FinancialMonthOffer offer = fresh,
    FinancialMonthSchedule? schedule,
  }) => paydayOfferDay(
    ledger,
    salaryCategoryIds: salary,
    schedule: schedule ?? FinancialMonthSchedule.initial,
    offer: offer,
  );

  test('gaji bertanggal 25: ditawarkan tanggal 25', () {
    expect(offerFor([income(DateTime(2026, 9, 25))]), 25);
  });

  test('tanggal 2 dan 28 batas dalam, tanggal 1 dan 29–31 tidak', () {
    expect(offerFor([income(DateTime(2026, 9, 2))]), 2);
    expect(offerFor([income(DateTime(2026, 9, 28))]), 28);
    expect(offerFor([income(DateTime(2026, 9))]), isNull);
    expect(offerFor([income(DateTime(2026, 8, 29))]), isNull);
    expect(offerFor([income(DateTime(2026, 8, 31))]), isNull);
  });

  test('yang dipakai gaji terbaru', () {
    expect(offerFor([income(DateTime(2026, 7, 20)), income(DateTime(2026, 9, 25)), income(DateTime(2026, 8, 24))]), 25);
  });

  test('bukan kategori Gaji, pengeluaran, kategori kosong, dan pembayaran freelance tidak dihitung', () {
    expect(offerFor([income(DateTime(2026, 9, 25), categoryId: 'builtin.bonus')]), isNull);
    expect(offerFor([income(DateTime(2026, 9, 25), categoryId: null)]), isNull);
    expect(offerFor([income(DateTime(2026, 9, 25), freelancePaymentId: 'p')]), isNull);
    expect(
      offerFor([
        ExpenseTransaction(
          id: 'e',
          date: DateTime(2026, 9, 25),
          amount: 1000,
          note: '',
          walletId: 'w',
          categoryId: 'builtin.salary',
        ),
      ]),
      isNull,
    );
  });

  test('tanpa transaksi tidak ditawarkan', () {
    expect(offerFor(const []), isNull);
  });

  test('pengguna sudah mengubah awal bulan sendiri: tidak ditawarkan', () {
    final ledger = [income(DateTime(2026, 9, 25))];
    expect(offerFor(ledger, offer: (changedByUser: true, offeredRuleIds: const {}, paydayCardAnswered: false)), isNull);
  });

  test('jadwal sudah bukan bawaan: tidak ditawarkan', () {
    final changed = FinancialMonthSchedule.initial.changedOn(DateTime(2026, 9), const FinancialMonthStart.day(25));
    expect(offerFor([income(DateTime(2026, 9, 25))], schedule: changed), isNull);
  });

  test('kartu sudah dijawab (ditutup): tidak ditawarkan lagi', () {
    final ledger = [income(DateTime(2026, 9, 25))];
    expect(offerFor(ledger, offer: (changedByUser: false, offeredRuleIds: const {}, paydayCardAnswered: true)), isNull);
  });
}
