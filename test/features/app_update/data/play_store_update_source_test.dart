import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_update/in_app_update.dart' as play;
import 'package:saldough/features/app_update/data/play_store_update_source.dart';
import 'package:saldough/features/app_update/domain/entities/update_snapshot.dart';

/// Pemetaan hasil Play ke keadaan APP_UPDATE (ADR-039 §3.1).
void main() {
  play.AppUpdateInfo info({
    play.UpdateAvailability availability = play.UpdateAvailability.updateAvailable,
    play.InstallStatus status = play.InstallStatus.unknown,
    bool flexible = true,
    int? code = 7,
  }) => play.AppUpdateInfo(
    updateAvailability: availability,
    updatePriority: 0,
    availableVersionCode: code,
    installStatus: status,
    packageName: 'app.test',
    clientVersionStalenessDays: null,
    immediateUpdateAllowed: false,
    flexibleUpdateAllowed: flexible,
    immediateAllowedPreconditions: null,
    flexibleAllowedPreconditions: null,
  );

  test('tersedia dan boleh fleksibel', () {
    expect(
      PlayStoreUpdateSource.map(info()),
      const StoreUpdateInfo(stage: StoreUpdateStage.available, availableBuild: 7),
    );
  });

  test('tersedia tetapi tidak boleh fleksibel: diam', () {
    expect(PlayStoreUpdateSource.map(info(flexible: false)), StoreUpdateInfo.unknown);
  });

  test('tidak ada versi baru', () {
    expect(
      PlayStoreUpdateSource.map(info(availability: play.UpdateAvailability.updateNotAvailable, code: null)),
      const StoreUpdateInfo(stage: StoreUpdateStage.none),
    );
  });

  test('mengunduh dan sudah diunduh menurut status pemasangan, walau Play menyebut pembaruan berjalan', () {
    const running = play.UpdateAvailability.developerTriggeredUpdateInProgress;
    expect(
      PlayStoreUpdateSource.map(info(availability: running, status: play.InstallStatus.downloading)).stage,
      StoreUpdateStage.downloading,
    );
    expect(
      PlayStoreUpdateSource.map(info(availability: running, status: play.InstallStatus.downloaded)).stage,
      StoreUpdateStage.downloaded,
    );
  });

  test('keadaan tak dikenal: diam', () {
    expect(PlayStoreUpdateSource.map(info(availability: play.UpdateAvailability.unknown)), StoreUpdateInfo.unknown);
  });

  test('aliran status: gagal atau dibatalkan kembali ke tersedia', () {
    expect(PlayStoreUpdateSource.mapStatus(play.InstallStatus.downloaded), StoreUpdateStage.downloaded);
    expect(PlayStoreUpdateSource.mapStatus(play.InstallStatus.downloading), StoreUpdateStage.downloading);
    expect(PlayStoreUpdateSource.mapStatus(play.InstallStatus.failed), StoreUpdateStage.available);
    expect(PlayStoreUpdateSource.mapStatus(play.InstallStatus.canceled), StoreUpdateStage.available);
    expect(PlayStoreUpdateSource.mapStatus(play.InstallStatus.installing), isNull);
  });

  test('diagnostik memuat jawaban mentah Play di setiap hasil, tanpa mengubah kesamaan nilai', () {
    final available = PlayStoreUpdateSource.map(info());
    expect(available.diagnostic, contains('availability=updateAvailable'));
    expect(available.diagnostic, contains('flexibleAllowed=true'));
    expect(available.diagnostic, contains('availableVersionCode=7'));
    expect(available, const StoreUpdateInfo(stage: StoreUpdateStage.available, availableBuild: 7));

    final notFlexible = PlayStoreUpdateSource.map(info(flexible: false));
    expect(notFlexible.stage, StoreUpdateStage.unknown);
    expect(notFlexible.diagnostic, contains('flexibleAllowed=false'));

    final none = PlayStoreUpdateSource.map(info(availability: play.UpdateAvailability.updateNotAvailable, code: null));
    expect(none.diagnostic, contains('availability=updateNotAvailable'));
  });
}
