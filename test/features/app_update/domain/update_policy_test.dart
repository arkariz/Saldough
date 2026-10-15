import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/app_update/domain/entities/app_update_memory.dart';
import 'package:saldough/features/app_update/domain/entities/app_version.dart';
import 'package:saldough/features/app_update/domain/entities/update_snapshot.dart';
import 'package:saldough/features/app_update/domain/services/update_policy.dart';

/// Aturan pengumuman pembaruan (APP_UPDATE §6 B-3, B-4, B-5, B-6, B-8, §11).
void main() {
  final now = DateTime(2026, 10, 15, 9);

  UpdateSnapshot snap({
    int build = 6,
    int patch = 0,
    StoreUpdateStage stage = StoreUpdateStage.none,
    int? available,
    int? next,
  }) => UpdateSnapshot(
    version: AppVersion(name: '0.5.0', build: build, patch: patch),
    store: StoreUpdateInfo(stage: stage, availableBuild: available),
    patch: PatchState(current: patch, next: next),
  );

  UpdateAnnouncement pick(UpdateSnapshot s, [AppUpdateMemory memory = AppUpdateMemory.empty]) =>
      pickAnnouncement(snapshot: s, memory: memory, now: now);

  group('B-3 prioritas', () {
    test('sudah diunduh > tersedia > mengunduh dipilih menurut keadaan Play', () {
      expect(pick(snap(stage: StoreUpdateStage.downloaded, available: 7)), UpdateAnnouncement.storeDownloaded);
      expect(pick(snap(stage: StoreUpdateStage.available, available: 7)), UpdateAnnouncement.storeAvailable);
      expect(pick(snap(stage: StoreUpdateStage.downloading, available: 7)), UpdateAnnouncement.storeDownloading);
    });

    test('urutan enum mencerminkan prioritas', () {
      expect(UpdateAnnouncement.storeDownloaded.index, lessThan(UpdateAnnouncement.storeAvailable.index));
      expect(UpdateAnnouncement.storeAvailable.index, lessThan(UpdateAnnouncement.storeDownloading.index));
      expect(UpdateAnnouncement.storeDownloading.index, lessThan(UpdateAnnouncement.patchReady.index));
    });
  });

  group('B-4 versi baru mengalahkan pembaruan kecil (S4)', () {
    test('keduanya ada: hanya versi baru', () {
      final s = snap(patch: 1, next: 2, stage: StoreUpdateStage.available, available: 7);
      expect(pick(s), UpdateAnnouncement.storeAvailable);
    });

    test('versi baru ditunda: pembaruan kecil build lama tetap tidak diumumkan', () {
      final s = snap(patch: 1, next: 2, stage: StoreUpdateStage.available, available: 7);
      final memory = AppUpdateMemory.empty.defer(7, now.subtract(const Duration(days: 1)));
      expect(pick(s, memory), UpdateAnnouncement.none);
    });
  });

  group('B-5 gagal = diam', () {
    test('Play tidak diketahui dan Shorebird tanpa tambalan: tidak ada banner', () {
      expect(pick(snap(stage: StoreUpdateStage.unknown)), UpdateAnnouncement.none);
    });

    test('Play tidak diketahui tidak menghalangi pembaruan kecil', () {
      expect(pick(snap(stage: StoreUpdateStage.unknown, next: 1)), UpdateAnnouncement.patchReady);
    });
  });

  group('B-6 Nanti', () {
    final deferred = AppUpdateMemory.empty.defer(7, now);
    final available = snap(stage: StoreUpdateStage.available, available: 7);

    test('menunda build itu 7 hari', () {
      expect(pick(available, deferred), UpdateAnnouncement.none);
      expect(
        pickAnnouncement(snapshot: available, memory: deferred, now: now.add(const Duration(days: 6, hours: 23))),
        UpdateAnnouncement.none,
      );
      expect(
        pickAnnouncement(snapshot: available, memory: deferred, now: now.add(deferDuration)),
        UpdateAnnouncement.storeAvailable,
      );
    });

    test('build lebih baru dari yang ditunda tampil lagi tanpa menunggu', () {
      final newer = snap(stage: StoreUpdateStage.available, available: 8);
      expect(pick(newer, deferred.defer(7, now)), UpdateAnnouncement.storeAvailable);
    });

    test('sudah diunduh dan mengunduh tidak bisa ditunda', () {
      expect(
        pick(snap(stage: StoreUpdateStage.downloaded, available: 7), deferred),
        UpdateAnnouncement.storeDownloaded,
      );
      expect(
        pick(snap(stage: StoreUpdateStage.downloading, available: 7), deferred),
        UpdateAnnouncement.storeDownloading,
      );
    });
  });

  group('B-8 pembaruan kecil sekali per nomor', () {
    test('tampil, lalu tidak lagi untuk nomor yang sama', () {
      final s = snap(next: 1);
      expect(pick(s), UpdateAnnouncement.patchReady);
      expect(pick(s, AppUpdateMemory.empty.announce(6, 1)), UpdateAnnouncement.none);
    });

    test('nomor lebih baru diumumkan lagi', () {
      final memory = AppUpdateMemory.empty.announce(6, 1);
      expect(pick(snap(next: 2), memory), UpdateAnnouncement.patchReady);
    });

    test('hitungan per build: versi baru terpasang mengatur ulang (§11)', () {
      final memory = AppUpdateMemory.empty.announce(6, 2);
      expect(pick(snap(build: 7, next: 1), memory), UpdateAnnouncement.patchReady);
    });
  });

  group('rollback dan nomor sama (§11)', () {
    test('tambalan berikutnya lebih kecil atau sama dengan yang berjalan: diam', () {
      expect(snap(patch: 2, next: 1).patch.ready, isNull);
      expect(pick(snap(patch: 2, next: 1)), UpdateAnnouncement.none);
      expect(pick(snap(patch: 2, next: 2)), UpdateAnnouncement.none);
      expect(pick(snap(patch: 2)), UpdateAnnouncement.none);
    });
  });

  group('keterangan di Akun (F4)', () {
    test('menurut keadaan, tidak terpengaruh Nanti', () {
      expect(versionStatusOf(snap()), VersionStatus.latest);
      expect(versionStatusOf(snap(stage: StoreUpdateStage.unknown)), VersionStatus.unknown);
      expect(versionStatusOf(snap(stage: StoreUpdateStage.available, available: 7)), VersionStatus.available);
      expect(versionStatusOf(snap(stage: StoreUpdateStage.downloading)), VersionStatus.downloading);
      expect(versionStatusOf(snap(stage: StoreUpdateStage.downloaded)), VersionStatus.downloaded);
      expect(versionStatusOf(snap(next: 1)), VersionStatus.patchReady);
      expect(versionStatusOf(snap(stage: StoreUpdateStage.unknown, next: 1)), VersionStatus.patchReady);
    });

    test('versi baru mengalahkan pembaruan kecil', () {
      expect(versionStatusOf(snap(stage: StoreUpdateStage.available, next: 1)), VersionStatus.available);
    });
  });

  group('AppUpdateMemory', () {
    test('versi terakhir dilihat tidak pernah turun (rollback)', () {
      final memory = AppUpdateMemory.empty.see(7, 2);
      expect(memory.see(7, 1), memory);
      expect(memory.see(6, 9), memory);
      expect(memory.see(7, 3).lastSeenPatch, 3);
      expect(memory.see(8, 0).lastSeenBuild, 8);
    });
  });
}
