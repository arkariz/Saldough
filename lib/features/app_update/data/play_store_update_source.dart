import 'dart:async';

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:in_app_update/in_app_update.dart' as play;
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/features/app_update/domain/entities/update_snapshot.dart';
import 'package:saldough/features/app_update/domain/repositories/update_sources.dart';

/// [StoreUpdateSource] di atas Play In-App Updates, mode fleksibel
/// (ADR-039 §3.1). Mode langsung tidak dipakai: ia memblokir layar.
final class PlayStoreUpdateSource with RepositoryGuard implements StoreUpdateSource {
  /// Membuat [PlayStoreUpdateSource].
  const PlayStoreUpdateSource();

  /// Memetakan hasil Play ke [StoreUpdateInfo]. Pembaruan yang tidak boleh
  /// fleksibel dianggap tidak diketahui (diam).
  static StoreUpdateInfo map(play.AppUpdateInfo info) {
    switch (info.installStatus) {
      case play.InstallStatus.downloaded:
        return StoreUpdateInfo(stage: StoreUpdateStage.downloaded, availableBuild: info.availableVersionCode);
      case play.InstallStatus.downloading:
      case play.InstallStatus.pending:
        return StoreUpdateInfo(stage: StoreUpdateStage.downloading, availableBuild: info.availableVersionCode);
      case play.InstallStatus.unknown:
      case play.InstallStatus.installing:
      case play.InstallStatus.installed:
      case play.InstallStatus.failed:
      case play.InstallStatus.canceled:
        break;
    }
    return switch (info.updateAvailability) {
      play.UpdateAvailability.updateAvailable when info.flexibleUpdateAllowed => StoreUpdateInfo(
        stage: StoreUpdateStage.available,
        availableBuild: info.availableVersionCode,
      ),
      play.UpdateAvailability.updateNotAvailable => const StoreUpdateInfo(stage: StoreUpdateStage.none),
      _ => StoreUpdateInfo.unknown,
    };
  }

  /// Memetakan status pemasangan di aliran Play; `null` = tidak mengubah apa-apa.
  static StoreUpdateStage? mapStatus(play.InstallStatus status) => switch (status) {
    play.InstallStatus.downloaded => StoreUpdateStage.downloaded,
    play.InstallStatus.downloading || play.InstallStatus.pending => StoreUpdateStage.downloading,
    play.InstallStatus.failed || play.InstallStatus.canceled => StoreUpdateStage.available,
    _ => null,
  };

  @override
  Future<Either<Failure, StoreUpdateInfo>> check() => guard(() async => map(await play.InAppUpdate.checkForUpdate()));

  @override
  Future<Either<Failure, bool>> startDownload() =>
      guard(() async => await play.InAppUpdate.startFlexibleUpdate() == play.AppUpdateResult.success);

  @override
  Future<Either<Failure, Unit>> completeInstall() => guardVoid(play.InAppUpdate.completeFlexibleUpdate);

  @override
  Stream<StoreUpdateStage> watch() =>
      play.InAppUpdate.installUpdateListener.map(mapStatus).where((stage) => stage != null).cast<StoreUpdateStage>();
}
