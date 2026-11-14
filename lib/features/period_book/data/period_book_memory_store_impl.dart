import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/features/period_book/domain/entities/period_book_memory.dart';
import 'package:saldough/features/period_book/domain/repositories/period_book_memory_store.dart';

const _memoryKey = StorageKey(namespace: 'period_book', name: 'memory');

/// [PeriodBookMemoryStore] di atas [KeyValueStorage]: satu dokumen
/// `{schemaVersion, opened, ritualSteps, cardDismissed, cardFacts, inviteEnabled}`.
final class PeriodBookMemoryStoreImpl with RepositoryGuard implements PeriodBookMemoryStore {
  /// Membuat [PeriodBookMemoryStoreImpl] di atas [_storage].
  const PeriodBookMemoryStoreImpl({required this._storage});

  /// Versi skema dokumen; samakan dengan `appBackupRegistry`.
  static const schemaVersion = 1;

  final KeyValueStorage _storage;

  StoredValue<PeriodBookMemory> get _value => StoredValue<PeriodBookMemory>.json(
    key: _memoryKey,
    fromJson: _fromJson,
    toJson: _toJson,
    storage: _storage,
  );

  @override
  Future<Either<Failure, PeriodBookMemory>> load() => guard(() async => await _value.read() ?? PeriodBookMemory.empty);

  @override
  Future<Either<Failure, Unit>> save(PeriodBookMemory memory) => guardVoid(() => _value.write(memory));

  static PeriodBookMemory _fromJson(Map<String, dynamic> json) {
    final opened = <String, DateTime>{};
    if (json['opened'] case final Map<String, dynamic> map) {
      for (final MapEntry(:key, :value) in map.entries) {
        final at = value is String ? DateTime.tryParse(value) : null;
        if (at != null) opened[key] = at;
      }
    }
    final steps = <String, Set<int>>{};
    if (json['ritualSteps'] case final Map<String, dynamic> map) {
      for (final MapEntry(:key, :value) in map.entries) {
        if (value is List) steps[key] = {for (final v in value) if (v is int) v};
      }
    }
    Set<String> strings(Object? raw) => {
      if (raw is List) for (final v in raw) if (v is String) v,
    };
    return PeriodBookMemory(
      opened: opened,
      ritualSteps: steps,
      cardDismissed: strings(json['cardDismissed']),
      cardFacts: strings(json['cardFacts']),
      inviteEnabled: json['inviteEnabled'] as bool? ?? true,
    );
  }

  static Map<String, dynamic> _toJson(PeriodBookMemory m) => {
    'schemaVersion': schemaVersion,
    'opened': {for (final e in m.opened.entries) e.key: e.value.toIso8601String()},
    'ritualSteps': {for (final e in m.ritualSteps.entries) e.key: (e.value.toList()..sort())},
    'cardDismissed': m.cardDismissed.toList()..sort(),
    'cardFacts': m.cardFacts.toList()..sort(),
    'inviteEnabled': m.inviteEnabled,
  };
}
