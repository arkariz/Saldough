part of 'voice_capture_bloc.dart';

/// Event [VoiceCaptureBloc].
sealed class VoiceCaptureEvent {
  /// Membuat [VoiceCaptureEvent].
  const VoiceCaptureEvent();
}

/// Mulai (atau ulangi) merekam.
final class VoiceCaptureStarted extends VoiceCaptureEvent {
  /// Membuat [VoiceCaptureStarted].
  const VoiceCaptureStarted({
    required this.localeId,
    required this.languageCode,
    required this.wallets,
    required this.categories,
  });

  /// Bahasa ucapan untuk pengenal, mis. `id_ID`.
  final String localeId;

  /// Bahasa aplikasi (`id`, `en`), untuk memilih paket aturan (ADR-029).
  final String languageCode;

  /// Dompet aktif (nama untuk pengenal dan pencocokan).
  final List<Wallet> wallets;

  /// Seluruh kategori.
  final List<Category> categories;
}

final class _SpeechUpdated extends VoiceCaptureEvent {
  const _SpeechUpdated(this.update);

  final SpeechUpdate update;
}
