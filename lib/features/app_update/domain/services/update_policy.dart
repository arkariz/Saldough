import 'package:saldough/features/app_update/domain/entities/app_update_memory.dart';
import 'package:saldough/features/app_update/domain/entities/update_snapshot.dart';

/// Pengumuman di slot banner Beranda (APP_UPDATE §7). Urutan enum = prioritas
/// (B-3); [none] = tidak ada banner.
enum UpdateAnnouncement {
  /// Tidak ada.
  none,

  /// Versi baru sudah diunduh: Pasang sekarang.
  storeDownloaded,

  /// Versi baru tersedia: Perbarui / Nanti.
  storeAvailable,

  /// Versi baru sedang diunduh: tanpa aksi.
  storeDownloading,

  /// Pembaruan kecil siap: Oke.
  patchReady,
}

/// Keterangan keadaan di baris Versi aplikasi (APP_UPDATE F4).
enum VersionStatus {
  /// Tidak bisa dicek: kosong.
  unknown,

  /// Terbaru.
  latest,

  /// Versi baru tersedia.
  available,

  /// Mengunduh versi baru.
  downloading,

  /// Versi baru sudah diunduh.
  downloaded,

  /// Pembaruan kecil siap, buka ulang aplikasi.
  patchReady,
}

/// Lama Nanti menunda banner sebuah build (B-6).
const deferDuration = Duration(days: 7);

/// Memilih pengumuman untuk Beranda dari keadaan [snapshot] dan [memory].
///
/// Aturan: versi baru mengalahkan pembaruan kecil walau ditunda (B-4, S4);
/// "sudah diunduh" dan "mengunduh" tidak bisa ditunda; Nanti hanya menahan
/// "tersedia" untuk build itu (dan yang lebih lama) 7 hari (B-6);
/// pembaruan kecil diumumkan sekali per nomor per build (B-8), dan rollback
/// atau nomor sama tidak pernah diumumkan.
UpdateAnnouncement pickAnnouncement({
  required UpdateSnapshot snapshot,
  required AppUpdateMemory memory,
  required DateTime now,
}) {
  switch (snapshot.store.stage) {
    case StoreUpdateStage.downloaded:
      return UpdateAnnouncement.storeDownloaded;
    case StoreUpdateStage.downloading:
      return UpdateAnnouncement.storeDownloading;
    case StoreUpdateStage.available:
      return _isDeferred(snapshot.store.availableBuild, memory, now)
          ? UpdateAnnouncement.none
          : UpdateAnnouncement.storeAvailable;
    case StoreUpdateStage.none:
    case StoreUpdateStage.unknown:
      break;
  }
  final ready = snapshot.patch.ready;
  if (ready == null) return UpdateAnnouncement.none;
  final announced = memory.announcedPatches[snapshot.version.build];
  return announced != null && announced >= ready ? UpdateAnnouncement.none : UpdateAnnouncement.patchReady;
}

bool _isDeferred(int? build, AppUpdateMemory memory, DateTime now) {
  final deferredBuild = memory.deferredBuild;
  final deferredAt = memory.deferredAt;
  if (build == null || deferredBuild == null || deferredAt == null) return false;
  return build <= deferredBuild && now.isBefore(deferredAt.add(deferDuration));
}

/// Keterangan keadaan untuk baris Akun (tidak terpengaruh Nanti).
VersionStatus versionStatusOf(UpdateSnapshot snapshot) => switch (snapshot.store.stage) {
  StoreUpdateStage.downloaded => VersionStatus.downloaded,
  StoreUpdateStage.downloading => VersionStatus.downloading,
  StoreUpdateStage.available => VersionStatus.available,
  StoreUpdateStage.none => snapshot.patch.ready != null ? VersionStatus.patchReady : VersionStatus.latest,
  StoreUpdateStage.unknown => snapshot.patch.ready != null ? VersionStatus.patchReady : VersionStatus.unknown,
};
