import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/features/premium/data/entitlement_dates.dart';

/// Kunci cache hak RevenueCat; tidak ikut cadangan (ADR-041 §3.9).
const entitlementCacheStorageKey = StorageKey(namespace: 'entitlement', name: 'cache');

/// Hak RevenueCat terakhir yang diketahui (ADR-041 §3.3): satu dokumen
/// `{schemaVersion, source, until?, inGrace, onHoldSince?, lastVerifiedAt}`.
/// Hanya sumber `purchase` dan `promotional` yang disimpan.
final class EntitlementCacheStore with RepositoryGuard {
  /// Membuat [EntitlementCacheStore] di atas [_storage].
  const EntitlementCacheStore({required this._storage});

  /// Versi skema dokumen.
  static const schemaVersion = 1;

  static const Set<PlanSource> _sources = {PlanSource.purchase, PlanSource.promotional};

  final KeyValueStorage _storage;

  StoredValue<CachedPlus> get _store => StoredValue<CachedPlus>.json(
    key: entitlementCacheStorageKey,
    fromJson: _fromJson,
    toJson: (cached) => {
      'schemaVersion': schemaVersion,
      'source': cached.source.name,
      if (cached.until case final until?) 'until': encodeInstant(until),
      'inGrace': cached.inGrace,
      if (cached.onHoldSince case final since?) 'onHoldSince': encodeInstant(since),
      'lastVerifiedAt': encodeInstant(cached.lastVerifiedAt),
    },
    storage: _storage,
  );

  static CachedPlus _fromJson(Map<String, dynamic> json) {
    final source = PlanSource.values.asNameMap()[json['source']];
    if (source == null || !_sources.contains(source)) throw const FormatException('Cache hak tidak valid');
    return CachedPlus(
      source: source,
      until: json['until'] == null ? null : decodeInstant(json['until']),
      inGrace: json['inGrace'] == true,
      onHoldSince: json['onHoldSince'] == null ? null : decodeInstant(json['onHoldSince']),
      lastVerifiedAt: decodeInstant(json['lastVerifiedAt']),
    );
  }

  /// Hak terakhir yang diketahui, atau `null` bila belum pernah ada.
  Future<Either<Failure, CachedPlus?>> load() => guard(_store.read);

  /// Menyimpan hak terbaru dari RevenueCat. Sumber selain `purchase` dan
  /// `promotional` ditolak supaya pengganti uji tidak pernah masuk cache.
  Future<Either<Failure, Unit>> save(CachedPlus cached) => guardVoid(() async {
    if (!_sources.contains(cached.source)) throw ArgumentError.value(cached.source, 'source');
    await _store.write(cached);
  });

  /// Menghapus cache, mis. RevenueCat melaporkan tidak ada hak sama sekali.
  Future<Either<Failure, Unit>> clear() => guardVoid(_store.remove);
}
