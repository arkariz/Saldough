import 'package:saldough/features/analysis/domain/period_summary.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Jumlah baris yang tampil langsung sebelum digabung ke Lainnya (B-10).
const analysisTopCount = 5;

/// Ringkasan [kind] untuk periode `from <= d < until` (FINANCIAL_ANALYSIS
/// B-1..B-10, B-14), fungsi murni.
///
/// - Keanggotaan lewat `periodDateOf` (B-2): transaksi tertaut rutin ikut
///   tanggal kemunculannya. Hanya pemasukan dan pengeluaran yang dihitung;
///   transfer hanya menjadi [PeriodSummary.transfers] (B-4).
/// - [walletId] membatasi ke satu dompet. Dompet nonaktif tidak dikenal di
///   sini: transaksinya tetap dihitung (B-5).
/// - Kategori dicari lewat [categoryOf]; id yang tidak dikenal dibaca sebagai
///   Tanpa kategori. Pemasukan pembayaran freelance tanpa kategori menjadi
///   kelompok Freelance (B-9).
/// - Uang `int` sen; persen dibulatkan hanya saat membentuk [AnalysisShare].
PeriodSummary summarizePeriod(
  Iterable<Transaction> transactions, {
  required DateTime from,
  required DateTime until,
  required CategoryKind kind,
  required Category? Function(String id) categoryOf,
  String? walletId,
}) {
  final amounts = <String, int>{};
  final counts = <String, int>{};
  final categories = <String, Category>{};
  var uncategorized = 0;
  var uncategorizedCount = 0;
  var total = 0;
  var count = 0;
  var transferTotal = 0;
  var incoming = 0;
  var outgoing = 0;

  for (final transaction in transactions) {
    final date = periodDateOf(transaction);
    if (date.isBefore(from) || !date.isBefore(until)) continue;
    switch (transaction) {
      case TransferTransaction(:final fromWalletId, :final toWalletId, :final amount):
        if (walletId == null) {
          transferTotal += amount;
        } else {
          if (toWalletId == walletId) incoming += amount;
          if (fromWalletId == walletId) outgoing += amount;
        }
      case IncomeTransaction(walletId: final transactionWallet, :final categoryId, :final amount, :final isFreelancePayment)
          when kind == CategoryKind.income && (walletId == null || transactionWallet == walletId):
        final category = categoryId == null ? null : categoryOf(categoryId);
        total += amount;
        count++;
        if (category != null) {
          amounts[category.id] = (amounts[category.id] ?? 0) + amount;
          counts[category.id] = (counts[category.id] ?? 0) + 1;
          categories[category.id] = category;
        } else if (categoryId == null && isFreelancePayment) {
          amounts[_freelanceKey] = (amounts[_freelanceKey] ?? 0) + amount;
          counts[_freelanceKey] = (counts[_freelanceKey] ?? 0) + 1;
        } else {
          uncategorized += amount;
          uncategorizedCount++;
        }
      case ExpenseTransaction(walletId: final transactionWallet, :final categoryId, :final amount)
          when kind == CategoryKind.expense && (walletId == null || transactionWallet == walletId):
        final category = categoryId == null ? null : categoryOf(categoryId);
        total += amount;
        count++;
        if (category != null) {
          amounts[category.id] = (amounts[category.id] ?? 0) + amount;
          counts[category.id] = (counts[category.id] ?? 0) + 1;
          categories[category.id] = category;
        } else {
          uncategorized += amount;
          uncategorizedCount++;
        }
      case IncomeTransaction() || ExpenseTransaction():
        break;
    }
  }

  AnalysisGroup group(String key) {
    final amount = amounts[key]!;
    final category = categories[key];
    return AnalysisGroup(
      kind: category == null ? AnalysisGroupKind.freelance : AnalysisGroupKind.category,
      category: category,
      amount: amount,
      count: counts[key]!,
      share: AnalysisShare.of(amount, total),
    );
  }

  final sorted = [for (final key in amounts.keys) group(key)]
    ..sort((a, b) {
      final byAmount = b.amount.compareTo(a.amount);
      return byAmount != 0 ? byAmount : a.sortName.compareTo(b.sortName);
    });

  // Sisanya digabung hanya bila ada dua atau lebih; satu kategori sisa tampil langsung.
  final merge = sorted.length - analysisTopCount >= 2;
  final top = merge ? sorted.take(analysisTopCount).toList() : sorted;
  final rest = merge ? sorted.skip(analysisTopCount).toList() : const <AnalysisGroup>[];
  final restAmount = rest.fold(0, (sum, g) => sum + g.amount);

  return PeriodSummary(
    kind: kind,
    total: total,
    count: count,
    groups: [
      ...top,
      if (rest.isNotEmpty)
        AnalysisGroup(
          kind: AnalysisGroupKind.others,
          amount: restAmount,
          count: rest.fold(0, (sum, g) => sum + g.count),
          share: AnalysisShare.of(restAmount, total),
          children: rest,
        ),
      if (uncategorized > 0)
        AnalysisGroup(
          kind: AnalysisGroupKind.uncategorized,
          amount: uncategorized,
          count: uncategorizedCount,
          share: AnalysisShare.of(uncategorized, total),
        ),
    ],
    transfers: walletId == null
        ? TransferInfo(total: transferTotal, incoming: 0, outgoing: 0, perWallet: false)
        : TransferInfo(total: 0, incoming: incoming, outgoing: outgoing, perWallet: true),
  );
}

const _freelanceKey = '\u0000freelance';
