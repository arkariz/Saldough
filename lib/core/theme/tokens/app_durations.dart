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

  /// Jeda sebelum input teks yang berubah cepat (bukan lewat `onSubmitted`)
  /// dianggap "selesai diketik" dan boleh dikomit ke bloc — mis. pengali
  /// minggu rencana belanja (UX-04). Bukan durasi animasi seperti token lain
  /// di kelas ini, tapi tetap satu-satunya tempat nilai waktu UI ditulis,
  /// supaya tidak ada angka harfiah `Duration` yang menyelip di widget.
  static const debounce = Duration(milliseconds: 500);
}
