/// Rentang berlakunya sebuah `Budget`. Lihat DOMAIN_MODEL.md bagian
/// "Anggaran".
enum BudgetPeriod {
  /// Tujuh hari sejak `startDate`.
  weekly,

  /// Satu bulan kalender sejak `startDate`.
  monthly;

  /// Batas akhir periode yang dimulai pada [start], **eksklusif** —
  /// periode berlaku untuk `start <= t < endFrom(start)`.
  ///
  /// Untuk [monthly], tanggal yang tidak ada di bulan berikutnya dijepit ke
  /// hari terakhir bulan itu: mulai 31 Januari berakhir 28/29 Februari, bukan
  /// meluber ke 2/3 Maret seperti `DateTime(y, m + 1, 31)`.
  DateTime endFrom(DateTime start) {
    final day = DateTime(start.year, start.month, start.day);
    switch (this) {
      case BudgetPeriod.weekly:
        return DateTime(day.year, day.month, day.day + 7);
      case BudgetPeriod.monthly:
        final lastDayOfNextMonth = DateTime(day.year, day.month + 2, 0).day;
        final clamped = day.day > lastDayOfNextMonth ? lastDayOfNextMonth : day.day;
        return DateTime(day.year, day.month + 1, clamped);
    }
  }
}
