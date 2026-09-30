part of 'voice_capture_bloc.dart';

/// Tahap lembar rekam.
enum VoiceCapturePhase {
  /// Sedang mendengarkan.
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
    this.phase = VoiceCapturePhase.listening,
    this.heardText = '',
    this.draft,
    this.failure,
    super.effect,
  });

  /// Tahap saat ini.
  final VoiceCapturePhase phase;

  /// Teks yang tertangkap sejauh ini.
  final String heardText;

  /// Draf hasil, saat [phase] `done`.
  final RecordDraft? draft;

  /// Alasan gagal, saat [phase] `failed`.
  final SpeechFailure? failure;

  @override
  VoiceCaptureState copyWith({
    VoiceCapturePhase? phase,
    String? heardText,
    RecordDraft? draft,
    SpeechFailure? failure,
    UiEffect? effect,
  }) {
    return VoiceCaptureState(
      phase: phase ?? this.phase,
      heardText: heardText ?? this.heardText,
      draft: draft ?? this.draft,
      failure: failure ?? this.failure,
      effect: effect,
    );
  }

  @override
  List<Object?> get props => [phase, heardText, draft, failure];
}
