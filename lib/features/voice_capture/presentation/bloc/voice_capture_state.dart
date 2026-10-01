part of 'voice_capture_bloc.dart';

/// Tahap lembar rekam.
enum VoiceCapturePhase {
  /// Lembar terbuka, mikrofon belum dibuka; menunggu tombol rekam.
  idle,

  /// Tombol rekam ditekan; pengenal sedang menyiapkan mikrofon.
  starting,

  /// Sedang merekam.
  listening,

  /// Transkrip sedang ditafsirkan.
  interpreting,

  /// Draf siap dibuka di CATAT.
  done,

  /// Gagal; lihat `failure`.
  failed,
}

/// State [VoiceCaptureBloc].
final class VoiceCaptureState extends UiState<VoiceCaptureState> {
  /// Membuat [VoiceCaptureState].
  const VoiceCaptureState({
    this.phase = VoiceCapturePhase.idle,
    this.heardText = '',
    this.level = 0,
    this.draft,
    this.failure,
    super.effect,
  });

  /// Tahap saat ini.
  final VoiceCapturePhase phase;

  /// Teks yang tertangkap sejauh ini.
  final String heardText;

  /// Kekuatan suara terakhir, 0..1 -- hanya untuk animasi tombol rekam.
  final double level;

  /// Mikrofon sedang (atau hampir) terbuka.
  bool get isRecording => phase == VoiceCapturePhase.starting || phase == VoiceCapturePhase.listening;

  /// Draf hasil, saat [phase] `done`.
  final RecordDraft? draft;

  /// Alasan gagal, saat [phase] `failed`.
  final SpeechFailure? failure;

  @override
  VoiceCaptureState copyWith({
    VoiceCapturePhase? phase,
    String? heardText,
    double? level,
    RecordDraft? draft,
    SpeechFailure? failure,
    UiEffect? effect,
  }) {
    return VoiceCaptureState(
      phase: phase ?? this.phase,
      heardText: heardText ?? this.heardText,
      level: level ?? this.level,
      draft: draft ?? this.draft,
      failure: failure ?? this.failure,
      effect: effect,
    );
  }

  @override
  List<Object?> get props => [phase, heardText, level, draft, failure];
}
