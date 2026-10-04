import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/shared/recurring/domain/recurring_suggestion.dart';

const _key = StorageKey(namespace: 'recurring', name: 'suggestion_dismissed');

/// [RecurringSuggestionDismissals] satu dokumen `{schemaVersion, keys}` di
/// `recurring/suggestion_dismissed`.
final class RecurringSuggestionDismissalsImpl with RepositoryGuard implements RecurringSuggestionDismissals {
  /// Membuat [RecurringSuggestionDismissalsImpl].
  const RecurringSuggestionDismissalsImpl({required this._storage});

  final KeyValueStorage _storage;

  StoredValue<Set<String>> get _store => StoredValue<Set<String>>.json(
    key: _key,
    fromJson: (json) => {...(json['keys'] as List<dynamic>).cast<String>()},
    toJson: (keys) => {
      'schemaVersion': 1,
      'keys': [...keys],
    },
    storage: _storage,
  );

  @override
  Future<Either<Failure, Set<String>>> load() => guard(() async => await _store.read() ?? <String>{});

  @override
  Future<Either<Failure, Unit>> add(String key) => guardVoid(() async => _store.write({...?await _store.read(), key}));
}
