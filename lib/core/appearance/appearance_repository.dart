import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/appearance/appearance_settings.dart';
import 'package:saldough/core/foundation/repository_guard.dart';

/// Setelan tampilan tersimpan.
abstract interface class AppearanceRepository {
  /// Setelan tersimpan; belum pernah diatur berarti [AppearanceSettings.initial].
  Future<Either<Failure, AppearanceSettings>> load();

  /// Menyimpan setelan.
  Future<Either<Failure, Unit>> save(AppearanceSettings settings);
}

const _appearanceKey = StorageKey(namespace: 'settings', name: 'appearance');

/// [AppearanceRepository] di atas [KeyValueStorage]: satu dokumen
/// `{schemaVersion, presetId, mode}`.
final class AppearanceRepositoryImpl with RepositoryGuard implements AppearanceRepository {
  /// Membuat [AppearanceRepositoryImpl] di atas [_storage].
  const AppearanceRepositoryImpl({required this._storage});

  /// Versi skema dokumen.
  static const schemaVersion = 1;

  final KeyValueStorage _storage;

  StoredValue<AppearanceSettings> get _store => StoredValue<AppearanceSettings>.json(
    key: _appearanceKey,
    fromJson: (json) => AppearanceSettings(
      presetId: json['presetId'] as String? ?? AppearanceSettings.initial.presetId,
      themeMode: _modeFrom(json['mode'] as String?),
    ),
    toJson: (settings) => {
      'schemaVersion': schemaVersion,
      'presetId': settings.presetId,
      'mode': settings.themeMode.name,
    },
    storage: _storage,
  );

  /// Nilai tak dikenal jatuh ke mengikuti sistem.
  static ThemeMode _modeFrom(String? name) =>
      ThemeMode.values.firstWhere((m) => m.name == name, orElse: () => ThemeMode.system);

  @override
  Future<Either<Failure, AppearanceSettings>> load() =>
      guard(() async => await _store.read() ?? AppearanceSettings.initial);

  @override
  Future<Either<Failure, Unit>> save(AppearanceSettings settings) => guardVoid(() => _store.write(settings));
}
