import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/features/milestone/domain/entities/milestone_ledger.dart';
import 'package:saldough/features/milestone/domain/repositories/milestone_ports.dart';

const _ledgerKey = StorageKey(namespace: 'milestone', name: 'ledger');

/// [MilestoneStore] di atas [KeyValueStorage]: satu dokumen
/// `{schemaVersion, earned: [{id, earnedAt, seen, quiet}], seeded, introShown,
/// celebrationEnabled}`.
final class MilestoneStoreImpl with RepositoryGuard implements MilestoneStore {
  /// Membuat [MilestoneStoreImpl] di atas [_storage].
  const MilestoneStoreImpl({required this._storage});

  /// Versi skema dokumen; samakan dengan `appBackupRegistry`.
  static const schemaVersion = 1;

  final KeyValueStorage _storage;

  StoredValue<MilestoneLedger> get _value =>
      StoredValue<MilestoneLedger>.json(key: _ledgerKey, fromJson: _fromJson, toJson: _toJson, storage: _storage);

  @override
  Future<Either<Failure, MilestoneLedger>> load() => guard(() async => await _value.read() ?? MilestoneLedger.empty);

  @override
  Future<Either<Failure, Unit>> save(MilestoneLedger ledger) => guardVoid(() => _value.write(ledger));

  static MilestoneLedger _fromJson(Map<String, dynamic> json) {
    final earned = <String, EarnedMilestone>{};
    for (final item in json['earned'] as List? ?? const []) {
      if (item is! Map) continue;
      final id = item['id'];
      final at = item['earnedAt'] is String ? DateTime.tryParse(item['earnedAt'] as String) : null;
      if (id is String && at != null) {
        earned[id] = EarnedMilestone(
          id: id,
          earnedAt: at,
          seen: item['seen'] as bool? ?? false,
          quiet: item['quiet'] as bool? ?? false,
        );
      }
    }
    return MilestoneLedger(
      earned: earned,
      seeded: json['seeded'] as bool? ?? false,
      introShown: json['introShown'] as bool? ?? false,
      celebrationEnabled: json['celebrationEnabled'] as bool? ?? true,
    );
  }

  static Map<String, dynamic> _toJson(MilestoneLedger l) => {
    'schemaVersion': schemaVersion,
    'earned': [
      for (final e in l.earned.values)
        {'id': e.id, 'earnedAt': e.earnedAt.toIso8601String(), 'seen': e.seen, 'quiet': e.quiet},
    ],
    'seeded': l.seeded,
    'introShown': l.introShown,
    'celebrationEnabled': l.celebrationEnabled,
  };
}
