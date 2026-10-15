import 'package:saldough/features/app_update/domain/entities/app_update_memory.dart';
import 'package:saldough/features/app_update/domain/entities/release_note.dart';
import 'package:saldough/features/app_update/domain/entities/update_snapshot.dart';
import 'package:saldough/features/app_update/domain/repositories/release_notes_source.dart';
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
    this.availableVersion,
    this.notes = ReleaseNotesSnapshot.empty,
    this.whatsNew = const [],
    this.installedNotes = const [],
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

  /// Nama versi build yang ditawarkan Play ("0.7.0") untuk chip banner, dari
  /// entri catatan build itu (ADR-039 §3.3 butir 7); `null` = tanpa chip.
  final String? availableVersion;

  /// Catatan yang dikenal aplikasi (Remote Config + salinan lokal).
  final ReleaseNotesSnapshot notes;

  /// Isi lembar Apa yang baru yang menunggu dilihat (terbaru di atas); kosong
  /// = tidak ada lembar.
  final List<ReleaseNote> whatsNew;

  /// Catatan semua versi yang sudah terpasang (daftar di Akun), terbaru di atas.
  final List<ReleaseNote> installedNotes;

  /// Keterangan keadaan untuk baris Akun.
  VersionStatus get status => snapshot == null ? VersionStatus.unknown : versionStatusOf(snapshot!);

  @override
  AppUpdateState copyWith({
    UpdateSnapshot? Function()? snapshot,
    AppUpdateMemory? memory,
    UpdateAnnouncement? announcement,
    bool? busy,
    String? Function()? availableVersion,
    ReleaseNotesSnapshot? notes,
    List<ReleaseNote>? whatsNew,
    List<ReleaseNote>? installedNotes,
    UiEffect? effect,
  }) => AppUpdateState(
    snapshot: snapshot != null ? snapshot() : this.snapshot,
    memory: memory ?? this.memory,
    announcement: announcement ?? this.announcement,
    busy: busy ?? this.busy,
    availableVersion: availableVersion != null ? availableVersion() : this.availableVersion,
    notes: notes ?? this.notes,
    whatsNew: whatsNew ?? this.whatsNew,
    installedNotes: installedNotes ?? this.installedNotes,
    effect: effect,
  );

  @override
  List<Object?> get props => [snapshot, memory, announcement, busy, availableVersion, notes, whatsNew, installedNotes];
}
