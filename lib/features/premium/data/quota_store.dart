import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/features/premium/data/entitlement_dates.dart';

/// Kunci pemakaian jatah; tidak ikut cadangan (ADR-041 §3.9).
const quotaStorageKey = StorageKey(namespace: 'entitlement', name: 'quota');

/// Satuan hitung pemakaian (ADR-041 §3.7).
enum QuotaScope {
  /// Jatah Gratis dan jatah cicip, per periode keuangan.
  freePeriod,

  /// Batas wajar Plus, per bulan kalender.
  plusMonth,
}

/// Pemakaian jatah per [QuotaScope] (ADR-041 §3.7): satu dokumen
/// `{schemaVersion, scopes: {scope: {start, used: {feature: n}}}}`.
///
/// Tiap satuan hanya menyimpan "ember" terakhir: memakai [bucketStart] yang
/// berbeda dari yang tersimpan berarti periode/bulan baru, jadi hitungan
/// mulai dari nol. Ember dihitung pemanggil (`financialPeriodOf` untuk
/// periode), bukan di sini.
final class QuotaStore with RepositoryGuard {
  /// Membuat [QuotaStore] di atas [_storage].
  const QuotaStore({required this._storage});

  /// Versi skema dokumen.
  static const schemaVersion = 1;

  final KeyValueStorage _storage;

  StoredValue<Map<QuotaScope, _Bucket>> get _store => StoredValue<Map<QuotaScope, _Bucket>>.json(
    key: quotaStorageKey,
    fromJson: _fromJson,
    toJson: (scopes) => {
      'schemaVersion': schemaVersion,
      'scopes': {for (final MapEntry(:key, :value) in scopes.entries) key.name: value.toJson()},
    },
    storage: _storage,
  );

  static Map<QuotaScope, _Bucket> _fromJson(Map<String, dynamic> json) {
    final scopes = json['scopes'];
    if (scopes is! Map<String, dynamic>) throw const FormatException('Dokumen jatah tidak valid');
    final byName = QuotaScope.values.asNameMap();
    return {
      for (final MapEntry(:key, :value) in scopes.entries)
        if (byName[key] case final scope? when value is Map<String, dynamic>) scope: _Bucket.fromJson(value),
    };
  }

  Future<Map<QuotaScope, _Bucket>> _readForWrite() async {
    try {
      return await _store.read() ?? const {};
    } on Failure {
      return const {};
    } on FormatException {
      return const {};
    }
  }

  /// Pemakaian [feature] di ember [bucketStart] satuan [scope]; `0` bila ember
  /// tersimpan sudah lain (periode baru).
  Future<Either<Failure, int>> used(QuotaScope scope, DateTime bucketStart, PlusFeature feature) => guard(() async {
    final bucket = (await _store.read())?[scope];
    if (bucket == null || bucket.start != _day(bucketStart)) return 0;
    return bucket.used[feature] ?? 0;
  });

  /// Menambah [delta] ke pemakaian [feature] (negatif untuk mengembalikan
  /// jatah yang gagal dipakai; tidak pernah di bawah nol). Ember lain diganti
  /// ember baru. Mengembalikan pemakaian sesudahnya.
  Future<Either<Failure, int>> add(QuotaScope scope, DateTime bucketStart, PlusFeature feature, int delta) =>
      guard(() async {
        final scopes = await _readForWrite();
        final start = _day(bucketStart);
        final current = scopes[scope];
        final used = current != null && current.start == start ? current.used : const <PlusFeature, int>{};
        final next = ((used[feature] ?? 0) + delta).clamp(0, 1 << 31);
        await _store.write({
          ...scopes,
          scope: _Bucket(start: start, used: {...used, feature: next}),
        });
        return next;
      });

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
}

final class _Bucket {
  const _Bucket({required this.start, required this.used});

  factory _Bucket.fromJson(Map<String, dynamic> json) {
    final used = json['used'];
    if (used is! Map<String, dynamic>) throw const FormatException('Dokumen jatah tidak valid');
    final byName = PlusFeature.values.asNameMap();
    return _Bucket(
      start: decodeDay(json['start']),
      used: {
        for (final MapEntry(:key, :value) in used.entries)
          if (byName[key] case final feature? when value is int) feature: value,
      },
    );
  }

  final DateTime start;
  final Map<PlusFeature, int> used;

  Map<String, Object> toJson() => {
    'start': encodeDay(start),
    'used': {for (final MapEntry(:key, :value) in used.entries) key.name: value},
  };
}
