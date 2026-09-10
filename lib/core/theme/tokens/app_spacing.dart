/// Skala jarak berbasis 4 piksel. Pakai ini, bukan angka harfiah, di mana pun
/// widget butuh padding, margin, atau gap.
abstract final class AppSpacing {
  AppSpacing._();

  /// Jarak terkecil — antar elemen yang sangat rapat, misalnya ikon dan label
  /// di dalam satu baris chip.
  static const double xs = 4;

  /// Jarak antar elemen kecil yang masih dalam satu kelompok, misalnya judul
  /// dan subjudul sebuah kartu.
  static const double sm = 8;

  /// Jarak bawaan antar elemen dalam satu panel — nilai paling sering dipakai.
  static const double md = 16;

  /// Jarak antar kelompok elemen di dalam satu layar, misalnya antar baris
  /// daftar.
  static const double lg = 24;

  /// Jarak antar bagian/panel yang berbeda dalam satu layar.
  static const double xl = 32;

  /// Jarak besar untuk memisahkan blok konten utama, misalnya padding atas
  /// layar di bawah app bar.
  static const double xxl = 48;

  /// Jarak terbesar, dipakai untuk spasi vertikal besar seperti state kosong.
  static const double xxxl = 64;
}
