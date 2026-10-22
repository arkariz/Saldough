import 'package:saldough/features/data_portability/domain/backup_models.dart';
import 'package:saldough/features/data_portability/domain/backup_summary.dart';
import 'package:state_management/state_management.dart';

/// Tahap lembar cadangkan (prototipe `LembarCadangkan.dc.html`).
enum BackupPhase {
  /// Menghitung ringkasan.
  loading,

  /// Ringkasan isi dan tombol Cadangkan.
  form,

  /// Cadangan sedang dibuat; bisa dibatalkan.
  busy,

  /// Cadangan siap disimpan atau dibagikan.
  ready,
}

/// Keadaan lembar cadangkan.
final class BackupState extends UiState<BackupState> {
  /// Membuat [BackupState].
  const BackupState({
    this.phase = BackupPhase.loading,
    this.summary,
    this.file,
    this.notSaved = false,
    this.finished = false,
    super.effect,
  });

  /// Tahap saat ini.
  final BackupPhase phase;

  /// Ringkasan isi sekarang.
  final BackupSummary? summary;

  /// Cadangan yang sudah siap.
  final BackupFile? file;

  /// Lembar simpan atau bagi ditutup tanpa menyimpan.
  final bool notSaved;

  /// Cadangan sudah disimpan atau dibagikan; lembar boleh ditutup.
  final bool finished;

  @override
  BackupState copyWith({
    BackupPhase? phase,
    BackupSummary? summary,
    BackupFile? Function()? file,
    bool? notSaved,
    bool? finished,
    UiEffect? effect,
  }) => BackupState(
    phase: phase ?? this.phase,
    summary: summary ?? this.summary,
    file: file != null ? file() : this.file,
    notSaved: notSaved ?? this.notSaved,
    finished: finished ?? this.finished,
    effect: effect,
  );

  @override
  List<Object?> get props => [phase, summary, file, notSaved, finished];
}
