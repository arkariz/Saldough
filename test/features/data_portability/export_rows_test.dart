import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/features/data_portability/domain/export_data.dart';
import 'package:saldough/features/data_portability/domain/export_rows.dart';
import 'package:saldough/shared/transaction/transaction.dart';

import '../../helpers/export_fixtures.dart';

/// Baris ekspor (EXPORT_BACKUP §5.2, E-1–E-6).
void main() {
  group('formatSen: nominal tanpa double', () {
    test('mata uang tanpa desimal: bilangan bulat', () {
      expect(formatSen(850000000, fractionDigits: 0), '8500000');
      expect(formatSen(0, fractionDigits: 0), '0');
      expect(formatSen(-4500000, fractionDigits: 0), '-45000');
    });

    test('mata uang berdesimal: selalu dua digit', () {
      expect(formatSen(4550, fractionDigits: 2), '45.50');
      expect(formatSen(100, fractionDigits: 2), '1.00');
      expect(formatSen(5, fractionDigits: 2), '0.05');
      expect(formatSen(-5, fractionDigits: 2), '-0.05');
    });

    test('sen yang tidak habis dibagi 100 tidak dibulatkan walau mata uangnya tanpa desimal', () {
      expect(formatSen(4550, fractionDigits: 0), '45.50');
      expect(formatSen(-4550, fractionDigits: 0), '-45.50');
    });

    test('nilai besar tetap tepat (tanpa kehilangan ketelitian double)', () {
      // Di luar jangkauan double (2^53); Dart VM memakai int 64-bit.
      // ignore: avoid_js_rounded_ints
      expect(formatSen(9007199254740993, fractionDigits: 2), '90071992547409.93');
    });
  });

  group('flowOf (aturan 7)', () {
    test('pemasukan +, pengeluaran −, transfer 0', () {
      expect(flowOf(ExportKind.income, 500), 500);
      expect(flowOf(ExportKind.expense, 500), -500);
      expect(flowOf(ExportKind.transfer, 500), 0);
    });
  });

  group('buildExportRows', () {
    test('terurut tanggal naik lalu id, dan nama diselesaikan dari id', () {
      final rows = buildExportRows(sampleExportData());
      expect(rows.map((r) => r.id), ['t3', 't1', 't2']);
      final salary = rows.first;
      expect(salary.kind, ExportKind.income);
      expect(salary.wallet, 'BCA');
      expect(salary.category, 'Gaji');
      expect(salary.rule, 'Gaji bulanan');
      final expense = rows.last;
      expect(expense.wallet, 'GoPay', reason: 'dompet nonaktif tetap bernama');
      expect(expense.budget, 'Bulanan › Makan');
      expect(expense.currencyCode, 'IDR');
    });

    test('transfer: dompet asal dan tujuan, tanpa kategori, arus 0', () {
      final transfer = buildExportRows(sampleExportData()).firstWhere((r) => r.kind == ExportKind.transfer);
      expect((transfer.wallet, transfer.toWallet, transfer.category), ('BCA', 'GoPay', ''));
      expect(transfer.flow, 0);
      expect(transfer.amount, 100000000);
    });

    test('Awal periode: gaji maju 2 hari ikut periode kemunculannya, bukan periode tanggal catat', () {
      final rows = buildExportRows(sampleExportData());
      final salary = rows.firstWhere((r) => r.id == 't3');
      expect(salary.date, DateTime(2026, 9, 23));
      expect(salary.periodStart, DateTime(2026, 9, 25), reason: 'periode 25 Sep, bukan 25 Agu – 24 Sep');
      // Transaksi tanpa tautan memakai tanggalnya sendiri.
      expect(rows.firstWhere((r) => r.id == 't2').periodStart, DateTime(2026, 9, 25));
    });

    test('jumlah Arus per Awal periode sama dengan Arus aplikasi: contoh EXPORT_BACKUP §5.2 = 8.455.000', () {
      final rows = buildExportRows(sampleExportData());
      final perPeriod = <DateTime, int>{};
      for (final r in rows) {
        perPeriod.update(r.periodStart, (v) => v + r.flow, ifAbsent: () => r.flow);
      }
      expect(perPeriod, {DateTime(2026, 9, 25): 850000000 + 0 - 4500000});
      expect(perPeriod.values.single, 845500000, reason: '8.455.000 dalam sen');
    });

    test('gaji maju lebih dari 7 hari tidak ikut kemunculannya', () {
      final data = sampleExportData(
        transactions: [
          IncomeTransaction(
            id: 'x',
            date: DateTime(2026, 9, 10),
            amount: 100,
            note: '',
            walletId: 'bca',
            recurrence: RecurrenceLink(ruleId: 'r1', occurrenceDate: DateTime(2026, 9, 25)),
          ),
        ],
      );
      expect(buildExportRows(data).single.periodStart, DateTime(2026, 8, 25));
    });

    test('id yang tidak ditemukan (data yatim) tidak menggagalkan ekspor: kolomnya kosong', () {
      final data = sampleExportData(
        transactions: [
          ExpenseTransaction(
            id: 'y',
            date: DateTime(2026, 10, 3),
            amount: 100,
            note: 'yatim',
            walletId: 'hilang',
            categoryId: 'hilang',
            budgetItemId: 'hilang',
            recurrence: RecurrenceLink(ruleId: 'hilang', occurrenceDate: DateTime(2026, 10, 3)),
          ),
        ],
      );
      final row = buildExportRows(data).single;
      expect((row.wallet, row.category, row.budget, row.rule), ('', '', '', ''));
    });

    test('tanpa transaksi: tanpa baris', () {
      expect(buildExportRows(sampleExportData(transactions: const [])), isEmpty);
    });
  });

  group('Arus per Awal periode = Arus aplikasi (ADR-040 §7 butir 3)', () {
    // Awal bulan keuangan berpindah dari tanggal 1 ke 25 pada 10 Okt 2026, jadi
    // ada periode peralihan; gaji dicatat maju 2 hari (ikut kemunculan) dan
    // 10 hari (tidak ikut); transfer di antaranya.
    final schedule = FinancialMonthSchedule.single(
      FinancialMonthStart.first,
    ).changedOn(DateTime(2026, 10, 10), const FinancialMonthStart.day(25));

    ExportData dataWith(List<Transaction> txs) => ExportData(
      transactions: txs,
      wallets: sampleExportData().wallets,
      categoryNames: const {},
      budgetLabels: const {},
      ruleNames: const {},
      freelanceProjectByPaymentId: const {},
      schedule: schedule,
      currency: sampleExportData().currency,
    );

    test('untuk setiap periode di berkas, jumlah Arus sama dengan CalculateCashFlow', () {
      final txs = <Transaction>[
        for (var i = 0; i < 160; i++)
          switch (i % 4) {
            0 => IncomeTransaction(
              id: 'i$i',
              date: DateTime(2026, 6).add(Duration(days: i)),
              amount: 1000 + i * 7,
              note: '',
              walletId: 'bca',
              recurrence: i % 8 == 0
                  ? RecurrenceLink(
                      ruleId: 'gaji',
                      occurrenceDate: DateTime(2026, 6).add(Duration(days: i + (i % 16 == 0 ? 2 : 10))),
                    )
                  : null,
            ),
            1 || 2 => ExpenseTransaction(
              id: 'e$i',
              date: DateTime(2026, 6).add(Duration(days: i)),
              amount: 300 + i,
              note: '',
              walletId: 'bca',
            ),
            _ => TransferTransaction(
              id: 't$i',
              date: DateTime(2026, 6).add(Duration(days: i)),
              amount: 5000 + i,
              note: '',
              fromWalletId: 'bca',
              toWalletId: 'gopay',
            ),
          },
      ];
      final rows = buildExportRows(dataWith(txs));
      expect(rows.length, txs.length);

      final periodStarts = rows.map((r) => r.periodStart).toSet();
      expect(periodStarts.length, greaterThan(3), reason: 'harus melintasi beberapa periode');
      expect(
        periodStarts.map(schedule.periodOf).any((p) => p.isTransition),
        isTrue,
        reason: 'harus ada periode peralihan',
      );
      for (final start in periodStarts) {
        final period = schedule.periodOf(start);
        final cashFlow = const CalculateCashFlow().inPeriod(txs, from: period.start, until: period.end);
        final inFile = rows.where((r) => r.periodStart == start);
        final income = inFile.where((r) => r.kind == ExportKind.income).fold<int>(0, (a, r) => a + r.amount);
        final expense = inFile.where((r) => r.kind == ExportKind.expense).fold<int>(0, (a, r) => a + r.amount);
        expect(income, cashFlow.income, reason: 'pemasukan periode $start');
        expect(expense, cashFlow.expense, reason: 'pengeluaran periode $start');
        expect(inFile.fold<int>(0, (a, r) => a + r.flow), cashFlow.net, reason: 'Arus periode $start');
      }
    });
  });
}
