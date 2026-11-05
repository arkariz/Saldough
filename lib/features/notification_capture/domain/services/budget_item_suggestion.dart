import 'package:saldough/shared/budget_catalog/budget_catalog.dart';
import 'package:saldough/shared/capture/capture.dart';

/// Saran pos anggaran untuk pengeluaran bebas (ADR-044 §3.2, E2/B-86).
///
/// Hanya saran: tidak pernah diisi diam-diam dan tidak dipakai jalur satu
/// ketuk atau otomatis. Pos tidak punya kategori, jadi satu-satunya petunjuk
/// adalah nama pos yang muncul di teks notifikasi. Kandidat harus pos
/// pengeluaran (bukan transfer) dari anggaran yang belum diarsipkan, berdompet
/// sama dengan draf, dan periodenya mencakup tanggal transaksi. Bila lebih dari
/// satu pos berbeda cocok, tidak ada saran (ambigu tidak ditebak).
BudgetItemOption? suggestBudgetItem({
  required RecordDraft draft,
  required DateTime date,
  required String text,
  required Iterable<BudgetItemOption> options,
}) {
  if (draft.kind != DraftKind.expense || draft.walletId == null) return null;
  final haystack = text.toLowerCase();
  final hits = <String, BudgetItemOption>{};
  for (final option in options) {
    if (option.isArchived || option.isTransfer) continue;
    if (option.walletId != draft.walletId || !option.covers(date)) continue;
    final name = option.itemName.trim().toLowerCase();
    if (name.replaceAll(RegExp('[^a-z]'), '').length < 3) continue;
    final word = RegExp('(?<![a-z0-9])${RegExp.escape(name)}(?![a-z0-9])');
    if (word.hasMatch(haystack)) hits[option.itemId] = option;
  }
  return hits.length == 1 ? hits.values.single : null;
}
