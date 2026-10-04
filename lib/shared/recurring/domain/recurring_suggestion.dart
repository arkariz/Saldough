import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/shared/recurring/domain/recurring_rule.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Saran **"Sepertinya rutin"** (ADR-037 §3.3): transaksi dengan jenis,
/// dompet, nominal, dan catatan sama di tiga bulan kalender berturut-turut.
final class RecurringSuggestion extends Equatable {
  /// Membuat [RecurringSuggestion].
  const RecurringSuggestion({required this.key, required this.latest});

  /// Kunci stabil untuk "Bukan rutin".
  final String key;

  /// Transaksi terbaru dari polanya; dipakai "Jadikan rutin".
  final Transaction latest;

  @override
  List<Object?> get props => [key, latest];
}

/// Saran yang ditolak, di `recurring/suggestion_dismissed`.
abstract interface class RecurringSuggestionDismissals {
  /// Kunci yang pernah ditolak.
  Future<Either<Failure, Set<String>>> load();

  /// Menambah [key].
  Future<Either<Failure, Unit>> add(String key);
}

/// Berapa bulan berturut-turut sebelum disarankan.
const suggestionMonths = 3;

/// Saran dari [transactions] per [today], paling banyak [limit], terbaru
/// dulu. Hanya pemasukan dan pengeluaran yang belum tertaut ke rutin dan
/// bercatatan; tanggalnya dalam ±3 hari antarbulan; tiga bulannya berakhir
/// di bulan ini atau bulan lalu. Pola yang sudah punya rutin (jenis, dompet,
/// dan catatan sama) atau pernah ditolak ([dismissed]) tidak disarankan.
List<RecurringSuggestion> suggestRecurring(
  Iterable<Transaction> transactions, {
  required DateTime today,
  required Iterable<RecurringRule> rules,
  required Set<String> dismissed,
  int limit = 3,
}) {
  String norm(String note) => note.trim().toLowerCase();
  final covered = {for (final r in rules) '${r.kind.name}|${r.walletId}|${norm(r.note)}'};
  final groups = <String, List<Transaction>>{};
  for (final t in transactions) {
    if (t.recurrence != null || norm(t.note).isEmpty) continue;
    final (kind, wallet) = switch (t) {
      IncomeTransaction(:final walletId) => (RecurringKind.income, walletId),
      ExpenseTransaction(:final walletId) => (RecurringKind.expense, walletId),
      TransferTransaction() => (null, null),
    };
    if (kind == null || covered.contains('${kind.name}|$wallet|${norm(t.note)}')) continue;
    (groups['${kind.name}|$wallet|${t.amount}|${norm(t.note)}'] ??= []).add(t);
  }
  int monthIndex(DateTime d) => d.year * 12 + d.month - 1;
  final current = monthIndex(today);
  final found = <RecurringSuggestion>[];
  for (final MapEntry(:key, value: group) in groups.entries) {
    if (dismissed.contains(key)) continue;
    final byMonth = <int, Transaction>{for (final t in group) monthIndex(t.date): t};
    for (final end in [current, current - 1]) {
      final picked = [for (var m = end - suggestionMonths + 1; m <= end; m++) byMonth[m]];
      if (picked.any((t) => t == null)) continue;
      final days = [for (final t in picked) t!.date.day];
      if (days.reduce((a, b) => a > b ? a : b) - days.reduce((a, b) => a < b ? a : b) > 6) continue;
      final latest = group.reduce((a, b) => a.date.isAfter(b.date) ? a : b);
      found.add(RecurringSuggestion(key: key, latest: latest));
      break;
    }
  }
  found.sort((a, b) => b.latest.date.compareTo(a.latest.date));
  return found.take(limit).toList();
}
