import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/features/notification_capture/domain/repositories/merchant_memory_store.dart';

const _memoryKey = StorageKey(namespace: 'capture', name: 'merchant_memory');

/// [MerchantMemoryStore] di atas [KeyValueStorage]: satu dokumen
/// `{schemaVersion, items: [{key, categoryId}]}`; urutan daftar = urutan sisip.
final class MerchantMemoryStoreImpl with RepositoryGuard implements MerchantMemoryStore {
  /// Membuat [MerchantMemoryStoreImpl] di atas [_storage].
  const MerchantMemoryStoreImpl({required this._storage});

  /// Versi skema dokumen.
  static const schemaVersion = 1;

  final KeyValueStorage _storage;

  StoredValue<Map<String, String>> get _value => StoredValue<Map<String, String>>.json(
    key: _memoryKey,
    fromJson: (json) => {
      for (final item in json['items'] as List? ?? const [])
        if (item case {'key': final String key, 'categoryId': final String categoryId}) key: categoryId,
    },
    toJson: (memory) => {
      'schemaVersion': schemaVersion,
      'items': [
        for (final e in memory.entries) {'key': e.key, 'categoryId': e.value},
      ],
    },
    storage: _storage,
  );

  @override
  Future<Either<Failure, Map<String, String>>> load() => guard(() async => await _value.read() ?? const {});

  @override
  Future<Either<Failure, Unit>> save(Map<String, String> memory) => guardVoid(() => _value.write(memory));
}
