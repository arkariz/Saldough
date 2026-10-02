/// Tanggal [day] di bulan [month] tahun [year], dijepit ke hari terakhir
/// bulan itu kalau bulannya lebih pendek: `clampedDate(2027, 2, 31)` adalah
/// 28 Februari 2027, bukan 3 Maret seperti `DateTime(2027, 2, 31)`.
///
/// [month] boleh di luar 1–12 dan dinormalkan seperti `DateTime`
/// (`month: 13` = Januari tahun berikutnya). Dipakai `BudgetPeriod.endFrom`
/// dan jadwal transaksi rutin (ADR-034 §3.1), supaya keduanya menjepit
/// dengan cara yang sama.
DateTime clampedDate(int year, int month, int day) {
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, day > lastDay ? lastDay : day);
}
