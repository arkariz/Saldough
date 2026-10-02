import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/features/recurring/domain/reminder_settings.dart';

const _key = StorageKey(namespace: 'settings', name: 'recurring_reminders');

/// [ReminderSettingsRepository] satu dokumen `{schemaVersion, enabled}` di
/// `settings/recurring_reminders`.
final class ReminderSettingsRepositoryImpl with RepositoryGuard implements ReminderSettingsRepository {
  /// Membuat [ReminderSettingsRepositoryImpl].
  const ReminderSettingsRepositoryImpl({required this._storage});

  final KeyValueStorage _storage;

  StoredValue<bool> get _store => StoredValue<bool>.json(
    key: _key,
    fromJson: (json) => json['enabled'] as bool? ?? false,
    toJson: (enabled) => {'schemaVersion': 1, 'enabled': enabled},
    storage: _storage,
  );

  @override
  Future<Either<Failure, bool>> isEnabled() => guard(() async => await _store.read() ?? false);

  @override
  Future<Either<Failure, Unit>> setEnabled({required bool enabled}) => guardVoid(() => _store.write(enabled));
}
