import 'package:dependencies/dependencies.dart';

/// Versi yang sedang berjalan: nama (`0.6.0`), nomor build (versionCode Play)
/// dan nomor pembaruan kecil Shorebird (0 = tanpa tambalan).
final class AppVersion extends Equatable {
  /// Membuat [AppVersion].
  const AppVersion({required this.name, required this.build, this.patch = 0});

  /// Nama versi, mis. `0.6.0`.
  final String name;

  /// Nomor build, mis. `7`.
  final int build;

  /// Nomor pembaruan kecil yang berjalan; 0 bila tanpa tambalan.
  final int patch;

  /// Salinan dengan [patch] lain.
  AppVersion withPatch(int patch) => AppVersion(name: name, build: build, patch: patch);

  @override
  List<Object?> get props => [name, build, patch];
}
