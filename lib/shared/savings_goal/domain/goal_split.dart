/// Menabung ke beberapa tujuan sekaligus (ADR-048 §9): pembagian nominal
/// menurut persen. Fungsi murni, tanpa penyimpanan.
library;

/// Membagi [total] sen menurut [percents] (`goalId` → persen 0–100, urutan
/// tampil). Tujuan ber-0% tidak ikut. Tiap bagian = `total × persen ~/ 100`;
/// sisa sen pembulatan diberikan ke tujuan dengan persen terbesar (yang
/// pertama bila sama), sehingga jumlah semua bagian tepat [total]
/// (ADR-048 §9.2). Bila jumlah persen bukan 100 (lihat [isValidSplit]), tiap
/// bagian dikembalikan apa adanya tanpa sisa.
Map<String, int> splitByPercent(int total, Map<String, int> percents) {
  final included = [
    for (final e in percents.entries)
      if (e.value > 0) e,
  ];
  if (included.isEmpty) return const {};
  final result = {for (final e in included) e.key: total * e.value ~/ 100};
  // Persen belum 100 (pengguna masih mengetik): tiap bagian apa adanya,
  // tanpa sisa yang bisa negatif.
  if (splitPercentTotal(percents) != 100) return result;
  final remainder = total - result.values.fold<int>(0, (a, b) => a + b);
  var largest = included.first;
  for (final e in included) {
    if (e.value > largest.value) largest = e;
  }
  result[largest.key] = result[largest.key]! + remainder;
  return result;
}

/// Jumlah persen yang ikut.
int splitPercentTotal(Map<String, int> percents) =>
    percents.values.where((p) => p > 0).fold<int>(0, (a, b) => a + b);

/// Pembagian sah untuk dicatat: jumlah persen tepat 100, minimal dua tujuan
/// ikut, dan tiap bagian dari [total] lebih dari 0 (ADR-048 §9.2).
bool isValidSplit(int total, Map<String, int> percents) {
  if (total <= 0 || splitPercentTotal(percents) != 100) return false;
  final parts = splitByPercent(total, percents);
  return parts.length >= 2 && parts.values.every((amount) => amount > 0);
}

/// Persen awal formulir untuk [goalIds] (urutan tampil): persen tersimpan
/// [remembered] bila ada (tujuan tanpa simpanan mulai dari 0), selain itu
/// dibagi rata dengan sisa ke tujuan pertama (ADR-048 §9.3).
Map<String, int> initialSplitPercents(
  List<String> goalIds,
  Map<String, int> remembered,
) {
  if (goalIds.isEmpty) return const {};
  if (remembered.keys.any(goalIds.contains)) {
    return {for (final id in goalIds) id: (remembered[id] ?? 0).clamp(0, 100)};
  }
  final even = 100 ~/ goalIds.length;
  return {
    for (final (i, id) in goalIds.indexed)
      id: even + (i == 0 ? 100 - even * goalIds.length : 0),
  };
}
