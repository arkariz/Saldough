import 'package:dependencies/dependencies.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Isian bawaan formulir CATAT yang diturunkan dari transaksi terbaru, tanpa
/// penyimpanan baru (UX-2, UX-3): dompet terakhir per jenis dan kategori yang
/// paling sering dipakai per jenis (id kategori, ADR-026).
final class RecordDefaults extends Equatable {
  /// Membuat [RecordDefaults].
  const RecordDefaults({
    this.incomeWalletId,
    this.expenseWalletId,
    this.transferFromWalletId,
    this.transferToWalletId,
    this.incomeCategoryIds = const [],
    this.expenseCategoryIds = const [],
  });

  /// Menurunkan isian bawaan dari [recent] (terbaru di atas). Dompet yang
  /// tidak ada di [activeWalletIds] tidak pernah dipakai sebagai bawaan.
  factory RecordDefaults.from(List<Transaction> recent, {required Set<String> activeWalletIds}) {
    String? active(String id) => activeWalletIds.contains(id) ? id : null;
    String? income;
    String? expense;
    String? from;
    String? to;
    for (final transaction in recent) {
      switch (transaction) {
        case IncomeTransaction(:final walletId):
          income ??= active(walletId);
        case ExpenseTransaction(:final walletId):
          expense ??= active(walletId);
        case TransferTransaction(:final fromWalletId, :final toWalletId):
          if (from == null && to == null && active(fromWalletId) != null && active(toWalletId) != null) {
            from = fromWalletId;
            to = toWalletId;
          }
      }
    }
    return RecordDefaults(
      incomeWalletId: income,
      expenseWalletId: expense,
      transferFromWalletId: from,
      transferToWalletId: to,
      incomeCategoryIds: _frequentCategoryIds(recent.whereType<IncomeTransaction>()),
      expenseCategoryIds: _frequentCategoryIds(recent.whereType<ExpenseTransaction>()),
    );
  }

  /// Dompet pemasukan terakhir.
  final String? incomeWalletId;

  /// Dompet pengeluaran terakhir.
  final String? expenseWalletId;

  /// Dompet asal transfer terakhir.
  final String? transferFromWalletId;

  /// Dompet tujuan transfer terakhir.
  final String? transferToWalletId;

  /// Id kategori pemasukan, paling sering di atas.
  final List<String> incomeCategoryIds;

  /// Id kategori pengeluaran, paling sering di atas.
  final List<String> expenseCategoryIds;

  /// Paling banyak sekian kategori riwayat yang ditawarkan.
  static const maxCategories = 5;

  @override
  List<Object?> get props => [
    incomeWalletId,
    expenseWalletId,
    transferFromWalletId,
    transferToWalletId,
    incomeCategoryIds,
    expenseCategoryIds,
  ];
}

/// Id kategori [transactions] (terbaru di atas), paling sering di atas; seri
/// dipecah oleh yang terbaru.
List<String> _frequentCategoryIds(Iterable<Transaction> transactions) {
  final counts = <String, int>{};
  final firstSeen = <String, int>{};
  var index = 0;
  for (final transaction in transactions) {
    final id = transaction.categoryId;
    if (id == null) continue;
    counts[id] = (counts[id] ?? 0) + 1;
    firstSeen.putIfAbsent(id, () => index++);
  }
  final ids = counts.keys.toList()
    ..sort((a, b) {
      final byCount = counts[b]!.compareTo(counts[a]!);
      return byCount != 0 ? byCount : firstSeen[a]!.compareTo(firstSeen[b]!);
    });
  return ids.take(RecordDefaults.maxCategories).toList();
}

/// Dompet awal formulir (UX-2): [shortcut] (pintasan kontekstual) selalu
/// menang; kalau hanya satu dompet aktif, dompet itu; selain itu [lastUsed]
/// selama masih aktif.
String? initialWalletFor({required String? shortcut, required List<String> activeWalletIds, String? lastUsed}) {
  if (shortcut != null) return shortcut;
  if (activeWalletIds.length == 1) return activeWalletIds.single;
  return activeWalletIds.contains(lastUsed) ? lastUsed : null;
}
