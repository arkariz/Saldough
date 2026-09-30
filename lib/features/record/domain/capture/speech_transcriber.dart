/// Alasan pengenalan ucapan gagal.
enum SpeechFailure {
  /// Izin mikrofon atau pengenalan ucapan ditolak.
  permissionDenied,

  /// Perangkat tidak punya layanan pengenal ucapan.
  unavailable,

  /// Tidak ada ucapan yang dikenali.
  noMatch,

  /// Pengenal membutuhkan jaringan dan jaringan tidak tersedia.
  network,

  /// Galat lain.
  other,
}

/// Kabar dari satu sesi pengenalan ucapan.
sealed class SpeechUpdate {
  /// Membuat [SpeechUpdate].
  const SpeechUpdate();
}

/// Hasil sementara selama pengguna masih berbicara.
final class SpeechPartial extends SpeechUpdate {
  /// Membuat [SpeechPartial].
  const SpeechPartial(this.text);

  /// Teks sementara.
  final String text;
}

/// Kekuatan suara saat merekam, 0 (sunyi) sampai 1 (keras) -- hanya untuk
/// umpan balik tampilan, bukan data.
final class SpeechLevel extends SpeechUpdate {
  /// Membuat [SpeechLevel].
  const SpeechLevel(this.level);

  /// Kekuatan suara ternormalisasi.
  final double level;
}

/// Pengenal sudah benar-benar mendengarkan (mikrofon terbuka).
final class SpeechListening extends SpeechUpdate {
  /// Membuat [SpeechListening].
  const SpeechListening();
}

/// Hasil akhir; sesi selesai.
final class SpeechFinal extends SpeechUpdate {
  /// Membuat [SpeechFinal].
  const SpeechFinal(this.text);

  /// Transkrip akhir.
  final String text;
}

/// Sesi gagal; sesi selesai.
final class SpeechFailed extends SpeechUpdate {
  /// Membuat [SpeechFailed].
  const SpeechFailed(this.reason);

  /// Alasannya.
  final SpeechFailure reason;
}

/// Port pengenal ucapan (ADR-027 §3.1, penangkap sumber `voice`).
/// Implementasi: pengenal sistem (`speech_to_text`); kelak Whisper.
abstract interface class SpeechTranscriber {
  /// Mulai mendengarkan dalam [localeId] (mis. `id_ID`). [phrases] adalah
  /// kata yang kemungkinan diucapkan (nama dompet) untuk membantu pengenal.
  /// Aliran berakhir sesudah satu [SpeechFinal] atau [SpeechFailed].
  Stream<SpeechUpdate> listen({required String localeId, List<String> phrases = const []});

  /// Berhenti mendengarkan dan meminta hasil akhir.
  Future<void> stop();

  /// Membatalkan sesi tanpa hasil.
  Future<void> cancel();
}
