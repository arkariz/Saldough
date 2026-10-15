import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/app_update/domain/entities/app_version.dart';
import 'package:saldough/features/app_update/domain/entities/update_snapshot.dart';
import 'package:saldough/features/app_update/domain/repositories/update_sources.dart';

/// Menggabungkan tiga sumber menjadi [UpdateSnapshot]. Sumber yang gagal
/// menjadi "tidak diketahui" (B-5); hanya versi terpasang yang wajib ada.
final class ReadUpdateSnapshot {
  /// Membuat [ReadUpdateSnapshot].
  const ReadUpdateSnapshot({required this._installed, required this._store, required this._patch});

  final InstalledVersionSource _installed;
  final StoreUpdateSource _store;
  final PatchSource _patch;

  /// Membaca keadaan. [checkStore] = false melewati Play (hanya versi dan
  /// Shorebird, keduanya lokal).
  Future<Either<Failure, UpdateSnapshot>> call({bool checkStore = true}) async {
    final installed = await _installed.read();
    if (installed.isLeft()) return left(installed.swap().getOrElse((_) => throw StateError('Right')));
    final version = installed.getOrElse((_) => throw StateError('Left'));
    final patch = (await _patch.read()).getOrElse((_) => PatchState.none);
    final store = checkStore
        ? (await _store.check()).fold(
            (failure) =>
                StoreUpdateInfo(stage: StoreUpdateStage.unknown, diagnostic: 'gagal dicek: ${failure.message}'),
            (info) => info,
          )
        : StoreUpdateInfo.unknown;
    return right(
      UpdateSnapshot(
        version: AppVersion(name: version.name, build: version.build, patch: patch.current),
        store: store,
        patch: patch,
      ),
    );
  }
}
