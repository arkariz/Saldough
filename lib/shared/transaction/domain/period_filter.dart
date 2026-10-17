import 'package:dependencies/dependencies.dart';
import 'package:saldough/shared/transaction/domain/period_date.dart';
import 'package:saldough/shared/transaction/domain/transaction.dart';
import 'package:saldough/shared/transaction/domain/transaction_query.dart';

/// Apakah [transaction] masuk "Tanpa kategori" (FINANCIAL_ANALYSIS B-9):
/// pemasukan atau pengeluaran tanpa kategori, atau dengan id yang tidak
/// dikenal ([isKnownCategory] salah). Pemasukan pembayaran freelance tanpa
/// kategori adalah kelompok Freelance, bukan Tanpa kategori. Transfer tidak
/// pernah.
bool isUncategorizedTransaction(Transaction transaction, {required bool Function(String id) isKnownCategory}) =>
    switch (transaction) {
      IncomeTransaction(:final categoryId, :final isFreelancePayment) =>
        categoryId == null ? !isFreelancePayment : !isKnownCategory(categoryId),
      ExpenseTransaction(:final categoryId) => categoryId == null || !isKnownCategory(categoryId),
      TransferTransaction() => false,
    };

/// Saringan satu periode keuangan untuk Daftar tersaring yang dibuka dari
/// Analisis (T-19.3, F4/F5): jumlah yang lolos sama persis dengan total
/// barisnya di Analisis untuk periode, jenis, dan dompet yang sama.
final class PeriodTransactionFilter extends Equatable {
  /// Membuat [PeriodTransactionFilter] untuk `from <= d < until`.
  const PeriodTransactionFilter({
    required this.from,
    required this.until,
    required this.type,
    this.uncategorized = false,
    this.categoryId,
    this.freelance = false,
    this.walletId,
  });

  /// Awal periode (termasuk).
  final DateTime from;

  /// Awal periode berikutnya (tidak termasuk).
  final DateTime until;

  /// Jenis yang diperlihatkan: pengeluaran atau pemasukan.
  final TransactionTypeFilter type;

  /// Hanya transaksi Tanpa kategori ([isUncategorizedTransaction]).
  final bool uncategorized;

  /// Hanya satu kategori.
  final String? categoryId;

  /// Hanya pemasukan pembayaran freelance tanpa kategori: kelompok Freelance
  /// di Analisis (B-9).
  final bool freelance;

  /// Hanya satu dompet.
  final String? walletId;

  /// Apakah [transaction] lolos. Keanggotaan periode memakai `periodDateOf`
  /// (ADR-038 §3.5), sama dengan Analisis dan kartu Arus Beranda.
  bool matches(Transaction transaction, {required bool Function(String id) isKnownCategory}) {
    final date = periodDateOf(transaction);
    if (date.isBefore(from) || !date.isBefore(until)) return false;
    if (!matchesTransactionType(transaction, type)) return false;
    if (walletId != null && !walletIdsOf(transaction).contains(walletId)) return false;
    if (uncategorized && !isUncategorizedTransaction(transaction, isKnownCategory: isKnownCategory)) return false;
    if (categoryId != null && transaction.categoryId != categoryId) return false;
    if (freelance && !(transaction is IncomeTransaction && transaction.categoryId == null && transaction.isFreelancePayment)) {
      return false;
    }
    return true;
  }

  @override
  List<Object?> get props => [from, until, type, uncategorized, categoryId, freelance, walletId];
}
