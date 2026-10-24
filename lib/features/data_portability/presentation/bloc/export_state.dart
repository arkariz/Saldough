import 'package:saldough/features/data_portability/domain/export_models.dart';
import 'package:state_management/state_management.dart';

/// Tahap lembar ekspor (prototipe `LembarEkspor.dc.html`).
enum ExportPhase {
  /// Menghitung ringkasan.
  loading,

  /// Memilih format.
  form,

  /// Belum ada transaksi.
  empty,

  /// Berkas sedang disiapkan; bisa dibatalkan.
  busy,

  /// Berkas siap disimpan atau dibagikan.
  ready,
}

/// Keadaan lembar ekspor.
final class ExportState extends UiState<ExportState> {
  /// Membuat [ExportState].
  const ExportState({
    this.phase = ExportPhase.loading,
    this.format = ExportFormat.xlsx,
    this.preview,
    this.file,
    this.notSaved = false,
    this.finished = false,
    super.effect,
  });

  /// Tahap saat ini.
  final ExportPhase phase;

  /// Format terpilih; xlsx bawaan (KT-E1).
  final ExportFormat format;

  /// Ringkasan "142 transaksi, 3 Jun – 22 Okt 2026".
  final ExportPreview? preview;

  /// Berkas yang sudah siap.
  final ExportFile? file;

  /// Pengguna menutup lembar simpan atau bagi tanpa menyimpan.
  final bool notSaved;

  /// Berkas sudah disimpan atau dibagikan; lembar boleh ditutup.
  final bool finished;

  @override
  ExportState copyWith({
    ExportPhase? phase,
    ExportFormat? format,
    ExportPreview? preview,
    ExportFile? Function()? file,
    bool? notSaved,
    bool? finished,
    UiEffect? effect,
  }) => ExportState(
    phase: phase ?? this.phase,
    format: format ?? this.format,
    preview: preview ?? this.preview,
    file: file != null ? file() : this.file,
    notSaved: notSaved ?? this.notSaved,
    finished: finished ?? this.finished,
    effect: effect,
  );

  @override
  List<Object?> get props => [phase, format, preview, file, notSaved, finished];
}
