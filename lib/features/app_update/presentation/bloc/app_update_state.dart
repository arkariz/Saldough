import 'package:saldough/features/app_update/domain/entities/app_update_memory.dart';
import 'package:saldough/features/app_update/domain/entities/update_snapshot.dart';
import 'package:saldough/features/app_update/domain/services/update_policy.dart';
import 'package:state_management/state_management.dart';

/// Keadaan pengumuman pembaruan (ADR-039). [snapshot] `null` = belum pernah
/// dibaca atau gagal dibaca (diam, B-5).
final class AppUpdateState extends UiState<AppUpdateState> {
  /// Membuat [AppUpdateState].
  const AppUpdateState({
    this.snapshot,
    this.memory = AppUpdateMemory.empty,
    this.announcement = UpdateAnnouncement.none,
    this.busy = false,
    super.effect,
  });

  /// Keadaan Play dan Shorebird terakhir yang dibaca.
  final UpdateSnapshot? snapshot;

  /// Ingatan aplikasi (Nanti, pembaruan kecil yang sudah diumumkan).
  final AppUpdateMemory memory;

  /// Banner yang harus tampil di Beranda.
  final UpdateAnnouncement announcement;

  /// Unduhan sedang dimulai (menunggu dialog Play).
  final bool busy;

  /// Keterangan keadaan untuk baris Akun.
  VersionStatus get status => snapshot == null ? VersionStatus.unknown : versionStatusOf(snapshot!);

  @override
  AppUpdateState copyWith({
    UpdateSnapshot? Function()? snapshot,
    AppUpdateMemory? memory,
    UpdateAnnouncement? announcement,
    bool? busy,
    UiEffect? effect,
  }) => AppUpdateState(
    snapshot: snapshot != null ? snapshot() : this.snapshot,
    memory: memory ?? this.memory,
    announcement: announcement ?? this.announcement,
    busy: busy ?? this.busy,
    effect: effect,
  );

  @override
  List<Object?> get props => [snapshot, memory, announcement, busy];
}
