import 'package:saldough/features/data_portability/domain/export_data.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Jenis transaksi di berkas.
enum ExportKind {
  /// Pemasukan.
  income,

  /// Pengeluaran.
  expense,

  /// Transfer.
  transfer,
}

/// Satu baris lembar Transaksi (EXPORT_BACKUP §5.2). Nominal tetap `int` sen;
/// konversi ke satuan utama hanya terjadi saat ditulis (`formatSen`).
final class ExportRow {
  /// Membuat [ExportRow].
  const ExportRow({
    required this.date,
    required this.periodStart,
    required this.kind,
    required this.amount,
    required this.flow,
    required this.currencyCode,
    required this.wallet,
    required this.toWallet,
    required this.category,
    required this.note,
    required this.budget,
    required this.rule,
    required this.project,
    required this.id,
  });

  /// `date` transaksi.
  final DateTime date;

  /// Awal periode keuangan tempat transaksi dihitung (`periodDateOf`).
  final DateTime periodStart;

  /// Jenis.
  final ExportKind kind;

  /// Nominal positif, sen.
  final int amount;

  /// Arus: pemasukan `+`, pengeluaran `−`, transfer `0` (aturan 7), sen.
  final int flow;

  /// Kode mata uang.
  final String currencyCode;

  /// Dompet; untuk transfer, dompet asal.
  final String wallet;

  /// Dompet tujuan, hanya transfer.
  final String toWallet;

  /// Nama kategori.
  final String category;

  /// Catatan.
  final String note;

  /// "Anggaran › Pos" bila tertaut.
  final String budget;

  /// Nama rutin bila tertaut.
  final String rule;

  /// Nama proyek freelance bila pemasukan dari pembayaran freelance.
  final String project;

  /// Id transaksi.
  final String id;
}

/// Arus sebuah transaksi untuk kolom Arus: pemasukan `+nominal`, pengeluaran
/// `−nominal`, transfer `0`. Satu-satunya tempat aturan ini ditulis untuk
/// ekspor; jumlah kolom ini per periode harus sama dengan kartu Arus (aturan 7).
int flowOf(ExportKind kind, int amount) => switch (kind) {
  ExportKind.income => amount,
  ExportKind.expense => -amount,
  ExportKind.transfer => 0,
};

/// Menyusun baris lembar Transaksi dari [data], terurut tanggal naik lalu id.
List<ExportRow> buildExportRows(ExportData data) {
  final walletNames = {for (final w in data.wallets) w.id: w.name};
  String wallet(String? id) => id == null ? '' : walletNames[id] ?? '';

  final rows = <ExportRow>[];
  for (final t in data.transactions) {
    final (kind, walletId, toWalletId, categoryId, budgetItemId) = switch (t) {
      IncomeTransaction() => (ExportKind.income, t.walletId, null, t.categoryId, null),
      ExpenseTransaction() => (ExportKind.expense, t.walletId, null, t.categoryId, t.budgetItemId),
      TransferTransaction() => (ExportKind.transfer, t.fromWalletId, t.toWalletId, null, t.budgetItemId),
    };
    final periodDate = periodDateOf(t);
    rows.add(
      ExportRow(
        date: t.date,
        periodStart: data.schedule.periodOf(periodDate).start,
        kind: kind,
        amount: t.amount,
        flow: flowOf(kind, t.amount),
        currencyCode: data.currency.code,
        wallet: wallet(walletId),
        toWallet: wallet(toWalletId),
        category: categoryId == null ? '' : data.categoryNames[categoryId] ?? '',
        note: t.note,
        budget: budgetItemId == null ? '' : data.budgetLabels[budgetItemId] ?? '',
        rule: t.recurrence == null ? '' : data.ruleNames[t.recurrence!.ruleId] ?? '',
        project: switch (t) {
          IncomeTransaction(:final freelancePaymentId?) => data.freelanceProjectByPaymentId[freelancePaymentId] ?? '',
          _ => '',
        },
        id: t.id,
      ),
    );
  }
  rows.sort((a, b) {
    final byDate = a.date.compareTo(b.date);
    return byDate != 0 ? byDate : a.id.compareTo(b.id);
  });
  return rows;
}

/// Nominal [sen] sebagai teks satuan utama, tanpa `double` dan tanpa pemisah
/// ribuan (E-3, ADR-040 §3.6): `850000000` → `8500000`, `4550` dengan mata
/// uang berdesimal → `45.50`. Digit desimal hanya bila [fractionDigits] > 0
/// atau bila sen tidak habis dibagi 100, supaya tidak ada nilai yang terbuang.
String formatSen(int sen, {required int fractionDigits}) {
  final negative = sen < 0;
  final abs = sen.abs();
  final whole = abs ~/ 100;
  final cents = abs % 100;
  final text = fractionDigits == 0 && cents == 0 ? '$whole' : '$whole.${cents.toString().padLeft(2, '0')}';
  return negative ? '-$text' : text;
}
