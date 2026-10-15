import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/features/app_update/domain/repositories/update_sources.dart';

/// [InstalledVersionSource] di atas `package_info_plus`.
final class PackageInfoVersionSource with RepositoryGuard implements InstalledVersionSource {
  /// Membuat [PackageInfoVersionSource].
  const PackageInfoVersionSource();

  @override
  Future<Either<Failure, InstalledVersion>> read() => guard(() async {
    final info = await PackageInfo.fromPlatform();
    return (name: info.version, build: int.parse(info.buildNumber));
  });
}
