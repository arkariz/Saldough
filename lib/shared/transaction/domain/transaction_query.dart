import 'package:dependencies/dependencies.dart';
import 'package:saldough/shared/transaction/domain/transaction.dart';

/// Nama kategori untuk id-nya, atau `null` kalau tidak dikenal. Disuntikkan
/// supaya fungsi di berkas ini tetap Dart murni (nama kategori aktif hidup di
/// `ActiveCategories`, lapisan presentasi).
typedef CategoryNameOf = String? Function(String categoryId);

/// Jenis transaksi yang disaring layar riwayat (FR-TXN-004). `all` bukan
/// "tanpa filter" di level data -- ia satu pilihan chip seperti tiga
/// lainnya, hanya kebetulan tidak mengecualikan apa pun berdasarkan jenis.
enum TransactionTypeFilter {
  /// Semua jenis.
  all,

  /// Hanya `IncomeTransaction`.
  income,

  /// Hanya `ExpenseTransaction`.
  expense,

  /// Hanya `TransferTransaction`.
  transfer,
}

/// Satu kelompok transaksi pada tanggal [date] yang sama, sudah tersaring
/// dan terurut (terbaru dulu) sesuai filter aktif saat kelompok ini dihitung.
final class TransactionDateGroup extends Equatable {
  /// Membuat [TransactionDateGroup].
  const TransactionDateGroup({
    required this.date,
    required this.netSen,
    required this.transactions,
  });

  /// Tanggal kelompok ini, waktu diabaikan (`day`-precision).
  final DateTime date;

  /// Jumlah pemasukan dikurangi pengeluaran pada tanggal ini. Transfer
  /// TIDAK ikut dihitung (CLAUDE.md aturan 7) -- boleh negatif.
  final int netSen;

  /// Transaksi pada tanggal ini, terbaru dulu.
  final List<Transaction> transactions;

  @override
  List<Object?> get props => [date, netSen, transactions];
}

/// Dompet yang tersentuh oleh [transaction] -- satu untuk pemasukan/
/// pengeluaran, dua untuk transfer. Menyaring dompet "BCA" karenanya juga
/// menampilkan transfer yang menyentuh BCA sebagai asal ATAU tujuan.
Set<String> walletIdsOf(Transaction transaction) => switch (transaction) {
  IncomeTransaction(:final walletId) => {walletId},
  ExpenseTransaction(:final walletId) => {walletId},
  TransferTransaction(:final fromWalletId, :final toWalletId) => {fromWalletId, toWalletId},
};

/// Apakah [transaction] termasuk jenis [filter].
bool matchesTransactionType(Transaction transaction, TransactionTypeFilter filter) => switch (filter) {
  TransactionTypeFilter.all => true,
  TransactionTypeFilter.income => transaction is IncomeTransaction,
  TransactionTypeFilter.expense => transaction is ExpenseTransaction,
  TransactionTypeFilter.transfer => transaction is TransferTransaction,
};

/// Menyaring [transactions] dengan dompet, kategori, kata kunci, dan jenis.
///
/// [query] cocok (tanpa beda huruf besar/kecil, spasi tepi diabaikan) dengan
/// nama kategori, catatan, atau nama salah satu dompet yang disentuh
/// transaksi; [walletNames] memetakan id dompet ke namanya. Urutan masukan
/// dipertahankan.
List<Transaction> filterTransactions(
  Iterable<Transaction> transactions, {
  required CategoryNameOf categoryName,
  required Map<String, String> walletNames,
  String? walletId,
  String? categoryId,
  String query = '',
  TransactionTypeFilter type = TransactionTypeFilter.all,
}) {
  final needle = query.trim().toLowerCase();
  final names = {for (final entry in walletNames.entries) entry.key: entry.value.toLowerCase()};
  bool matchesSearch(Transaction transaction) {
    final category = transaction.categoryId == null ? null : categoryName(transaction.categoryId!);
    if ((category ?? '').toLowerCase().contains(needle)) return true;
    if (transaction.note.toLowerCase().contains(needle)) return true;
    return walletIdsOf(transaction).any((id) => (names[id] ?? '').contains(needle));
  }

  return [
    for (final transaction in transactions)
      if ((walletId == null || walletIdsOf(transaction).contains(walletId)) &&
          (categoryId == null || transaction.categoryId == categoryId) &&
          (needle.isEmpty || matchesSearch(transaction)) &&
          matchesTransactionType(transaction, type))
        transaction,
  ];
}

/// Banyaknya transaksi per jenis, termasuk [TransactionTypeFilter.all] --
/// angka pada chip penyaring jenis.
Map<TransactionTypeFilter, int> countTransactionsByType(Iterable<Transaction> transactions) => {
  for (final filter in TransactionTypeFilter.values)
    filter: transactions.where((transaction) => matchesTransactionType(transaction, filter)).length,
};

/// Id kategori yang dipakai [transactions], tanpa duplikat, urut nama
/// (ADR-026); id yang namanya tidak dikenal diurutkan dengan id-nya sendiri.
List<String> distinctCategoryIds(Iterable<Transaction> transactions, {required CategoryNameOf categoryName}) {
  final ids = <String>{
    for (final transaction in transactions)
      if (transaction.categoryId != null) transaction.categoryId!,
  };
  String nameOf(String id) => categoryName(id)?.toLowerCase() ?? id;
  return ids.toList()..sort((a, b) => nameOf(a).compareTo(nameOf(b)));
}

/// Pemasukan dikurangi pengeluaran. Transfer TIDAK ikut dihitung (CLAUDE.md
/// aturan 7 -- transfer tidak pernah terhitung sebagai pemasukan maupun
/// pengeluaran).
int netSenOf(Iterable<Transaction> transactions) {
  var net = 0;
  for (final transaction in transactions) {
    switch (transaction) {
      case IncomeTransaction(:final amount):
        net += amount;
      case ExpenseTransaction(:final amount):
        net -= amount;
      case TransferTransaction():
        break;
    }
  }
  return net;
}

/// Mengelompokkan [transactions] per tanggal kalender: tanggal terbaru
/// dulu, dan di dalam satu tanggal transaksi terbaru dulu.
List<TransactionDateGroup> groupTransactionsByDate(Iterable<Transaction> transactions) {
  final byDay = <DateTime, List<Transaction>>{};
  for (final transaction in transactions) {
    final day = DateTime(transaction.date.year, transaction.date.month, transaction.date.day);
    byDay.putIfAbsent(day, () => []).add(transaction);
  }
  final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
  return [
    for (final day in days)
      TransactionDateGroup(
        date: day,
        netSen: netSenOf(byDay[day]!),
        transactions: byDay[day]!..sort((a, b) => b.date.compareTo(a.date)),
      ),
  ];
}
