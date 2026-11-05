import 'package:saldough/shared/budget_catalog/budget_catalog.dart';
import 'package:saldough/shared/capture/capture.dart';

/// Saran pos anggaran untuk pengeluaran bebas (ADR-044 §3.2, E2/B-86).
///
/// Hanya saran: tidak pernah diisi diam-diam dan tidak dipakai jalur satu
/// ketuk atau otomatis. Pos tidak punya kategori, jadi satu-satunya petunjuk
/// adalah nama pos yang muncul di teks notifikasi, atau nama pos yang pernah
/// dipilih untuk pedagang itu ([rememberedName], ingatan pedagang). Kandidat harus pos
/// pengeluaran (bukan transfer) dari anggaran yang belum diarsipkan, berdompet
/// sama dengan draf, dan periodenya mencakup tanggal transaksi. Bila lebih dari
/// satu pos berbeda cocok, tidak ada saran (ambigu tidak ditebak).
BudgetItemOption? suggestBudgetItem({
  required RecordDraft draft,
  required DateTime date,
  required String text,
  required Iterable<BudgetItemOption> options,
  String? rememberedName,
}) {
  if (draft.kind != DraftKind.expense || draft.walletId == null) return null;
  final eligible = [
    for (final option in options)
      if (!option.isArchived && !option.isTransfer && option.walletId == draft.walletId && option.covers(date)) option,
  ];
  final haystack = text.toLowerCase();
  final byText = <String, BudgetItemOption>{};
  for (final option in eligible) {
    final name = option.itemName.trim().toLowerCase();
    if (name.replaceAll(RegExp('[^a-z]'), '').length < 3) continue;
    final word = RegExp('(?<![a-z0-9])${RegExp.escape(name)}(?![a-z0-9])');
    if (word.hasMatch(haystack)) byText[option.itemId] = option;
  }
  if (byText.length == 1) return byText.values.single;
  if (byText.length > 1) return null;
  // Tanpa nama di teks: pos yang pernah dipilih untuk pedagang itu (nama sama,
  // karena id pos baru tiap periode).
  final remembered = rememberedName?.trim().toLowerCase();
  if (remembered == null || remembered.isEmpty) return null;
  final byMemory = {
    for (final option in eligible)
      if (option.itemName.trim().toLowerCase() == remembered) option.itemId: option,
  };
  return byMemory.length == 1 ? byMemory.values.single : null;
}
