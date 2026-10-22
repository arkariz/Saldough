import 'package:saldough/features/data_portability/domain/restore_models.dart';
import 'package:state_management/state_management.dart';

/// Tahap alur pulihkan (`Pulihkan.dc.html`).
enum RestorePhase {
  /// Berkas sedang diperiksa.
  inspecting,

  /// Pratinjau dan perbandingan; menunggu "Lanjut".
  preview,

  /// Menyiapkan penggantian (langkah 1); sesudahnya aplikasi dimulai ulang.
  running,

  /// Gagal; data tidak berubah.
  error,
}

/// Jenis galat yang ditampilkan.
enum RestoreErrorKind {
  /// Bukan cadangan, rusak, atau isinya tidak konsisten (R-1, R-3).
  invalid,

  /// Dibuat versi yang lebih baru (R-2).
  newer,

  /// Ruang penyimpanan tidak cukup.
  space,

  /// Lainnya.
  other,
}

/// Keadaan alur pulihkan.
final class RestoreState extends UiState<RestoreState> {
  /// Membuat [RestoreState].
  const RestoreState({
    this.phase = RestorePhase.inspecting,
    this.session,
    this.error,
    this.source = RestoreKind.account,
    super.effect,
  });

  /// Tahap saat ini.
  final RestorePhase phase;

  /// Hasil pemeriksaan yang siap diterapkan.
  final RestoreSession? session;

  /// Galat saat [phase] `error`.
  final RestoreErrorKind? error;

  /// Asal alur.
  final RestoreKind source;

  @override
  RestoreState copyWith({
    RestorePhase? phase,
    RestoreSession? Function()? session,
    RestoreErrorKind? Function()? error,
    RestoreKind? source,
    UiEffect? effect,
  }) => RestoreState(
    phase: phase ?? this.phase,
    session: session != null ? session() : this.session,
    error: error != null ? error() : this.error,
    source: source ?? this.source,
    effect: effect,
  );

  @override
  List<Object?> get props => [phase, session, error, source];
}
