import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/features/app_update/domain/entities/update_snapshot.dart';
import 'package:saldough/features/app_update/domain/repositories/update_sources.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

/// [PatchSource] di atas `shorebird_code_push`, baca saja (ADR-039 §3.2):
/// tanpa `checkForUpdate`/`update` sehingga tanpa jaringan tambahan, dan
/// `auto_update` mesin tidak diubah.
final class ShorebirdPatchSource with RepositoryGuard implements PatchSource {
  /// Membuat [ShorebirdPatchSource]; [updater] untuk uji.
  ShorebirdPatchSource({ShorebirdUpdater? updater}) : _updater = updater ?? ShorebirdUpdater();

  final ShorebirdUpdater _updater;

  @override
  Future<Either<Failure, PatchState>> read() => guard(() async {
    if (!_updater.isAvailable) return PatchState.none;
    final current = await _updater.readCurrentPatch();
    final next = await _updater.readNextPatch();
    return PatchState(current: current?.number ?? 0, next: next?.number);
  });
}
