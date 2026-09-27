import 'package:dependencies/dependencies.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Isian bawaan formulir CATAT yang diturunkan dari transaksi terbaru, tanpa
/// penyimpanan baru (UX-2, UX-3): dompet terakhir per jenis dan kategori yang
/// paling sering dipakai per jenis.
final class RecordDefaults extends Equatable {
  /// Membuat [RecordDefaults].
  const RecordDefaults({
    this.incomeWalletId,
    this.expenseWalletId,
    this.transferFromWalletId,
    this.transferToWalletId,
    this.incomeCategories = const [],
    this.expenseCategories = const [],
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
      incomeCategories: _frequentCategories(recent.whereType<IncomeTransaction>()),
      expenseCategories: _frequentCategories(recent.whereType<ExpenseTransaction>()),
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

  /// Kategori pemasukan, paling sering di atas.
  final List<String> incomeCategories;

  /// Kategori pengeluaran, paling sering di atas.
  final List<String> expenseCategories;

  /// Paling banyak sekian kategori riwayat yang ditawarkan.
  static const maxCategories = 5;

  @override
  List<Object?> get props => [
    incomeWalletId,
    expenseWalletId,
    transferFromWalletId,
    transferToWalletId,
    incomeCategories,
    expenseCategories,
  ];
}

/// Kategori [transactions] (terbaru di atas), paling sering di atas; seri
/// dipecah oleh yang terbaru. Beda huruf besar-kecil dihitung satu kategori
/// dengan ejaan terbarunya.
List<String> _frequentCategories(Iterable<Transaction> transactions) {
  final counts = <String, int>{};
  final spelling = <String, String>{};
  final firstSeen = <String, int>{};
  var index = 0;
  for (final transaction in transactions) {
    final category = transaction.categoryKey?.trim() ?? '';
    if (category.isEmpty) continue;
    final key = category.toLowerCase();
    counts[key] = (counts[key] ?? 0) + 1;
    spelling.putIfAbsent(key, () => category);
    firstSeen.putIfAbsent(key, () => index++);
  }
  final keys = counts.keys.toList()
    ..sort((a, b) {
      final byCount = counts[b]!.compareTo(counts[a]!);
      return byCount != 0 ? byCount : firstSeen[a]!.compareTo(firstSeen[b]!);
    });
  return [for (final key in keys.take(RecordDefaults.maxCategories)) spelling[key]!];
}

/// Saran kategori formulir: kategori riwayat [frequent] lebih dulu, lalu
/// saran bawaan [builtIn] yang belum ada — tanpa duplikat beda huruf
/// besar-kecil (UX-3).
List<String> mergeCategorySuggestions(List<String> frequent, List<String> builtIn) {
  final seen = <String>{};
  return [
    for (final category in [...frequent, ...builtIn])
      if (seen.add(category.toLowerCase())) category,
  ];
}

/// Dompet awal formulir (UX-2): [shortcut] (pintasan kontekstual) selalu
/// menang; kalau hanya satu dompet aktif, dompet itu; selain itu [lastUsed]
/// selama masih aktif.
String? initialWalletFor({required String? shortcut, required List<String> activeWalletIds, String? lastUsed}) {
  if (shortcut != null) return shortcut;
  if (activeWalletIds.length == 1) return activeWalletIds.single;
  return activeWalletIds.contains(lastUsed) ? lastUsed : null;
}
