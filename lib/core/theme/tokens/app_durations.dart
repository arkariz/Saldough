/// Durasi animasi baku. Pakai ini, bukan `Duration` harfiah, di `AnimatedXxx`
/// dan `Tween`.
abstract final class AppDurations {
  AppDurations._();

  /// Transisi sangat cepat — highlight tekan, perubahan warna kecil.
  static const fast = Duration(milliseconds: 120);

  /// Transisi bawaan untuk kebanyakan animasi UI (fade, perubahan ukuran).
  static const normal = Duration(milliseconds: 220);

  /// Transisi lebih terasa, dipakai untuk perpindahan layar khusus
  /// (`slideFromBottom`) dan balon kata yang muncul.
  static const slow = Duration(milliseconds: 360);
}
