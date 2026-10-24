import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/features/premium/data/entitlement_dates.dart';

/// Kunci rekaman uji coba; tidak ikut cadangan (ADR-041 §3.9).
const trialStorageKey = StorageKey(namespace: 'entitlement', name: 'trial');

/// Rekaman uji coba per akun di perangkat ini (ADR-041 §3.4): satu dokumen
/// `{schemaVersion, accounts: {uid: {firstSeen?, start?, endsOn?}}}`.
///
/// Uji coba dihitung **sekali** per akun: [save] tidak menimpa rekaman yang
/// sudah ada. `firstSeen` dipakai jangkar akun lama (dibuat sebelum Plus
/// diluncurkan) dan juga hanya ditulis sekali.
final class TrialStore with RepositoryGuard {
  /// Membuat [TrialStore] di atas [_storage].
  const TrialStore({required this._storage});

  /// Versi skema dokumen.
  static const schemaVersion = 1;

  final KeyValueStorage _storage;

  StoredValue<Map<String, _Account>> get _store => StoredValue<Map<String, _Account>>.json(
    key: trialStorageKey,
    fromJson: _fromJson,
    toJson: (accounts) => {
      'schemaVersion': schemaVersion,
      'accounts': {for (final MapEntry(:key, :value) in accounts.entries) key: value.toJson()},
    },
    storage: _storage,
  );

  static Map<String, _Account> _fromJson(Map<String, dynamic> json) {
    final accounts = json['accounts'];
    if (accounts is! Map<String, dynamic>) throw const FormatException('Dokumen uji coba tidak valid');
    return {
      for (final MapEntry(:key, :value) in accounts.entries)
        if (value is Map<String, dynamic>) key: _Account.fromJson(value),
    };
  }

  Future<Map<String, _Account>> _read() async => await _store.read() ?? const {};

  /// Dokumen rusak ditimpa, bukan membuat uji coba gagal disimpan selamanya.
  Future<Map<String, _Account>> _readForWrite() async {
    try {
      return await _read();
    } on Failure {
      return const {};
    } on FormatException {
      return const {};
    }
  }

  /// Uji coba akun [uid], atau `null` bila belum dimulai.
  Future<Either<Failure, TrialRecord?>> recordFor(String uid) => guard(() async {
    final account = (await _read())[uid];
    final start = account?.start;
    final endsOn = account?.endsOn;
    if (start == null || endsOn == null) return null;
    return TrialRecord(uid: uid, start: start, endsOn: endsOn);
  });

  /// Hari pertama akun [uid] tercatat masuk di perangkat ini, atau `null`.
  Future<Either<Failure, DateTime?>> firstSeen(String uid) => guard(() async => (await _read())[uid]?.firstSeen);

  /// Mencatat [day] sebagai hari pertama [uid] masuk; tidak menimpa yang ada.
  /// Mengembalikan nilai yang berlaku sesudahnya.
  Future<Either<Failure, DateTime>> markFirstSeen(String uid, DateTime day) => guard(() async {
    final accounts = await _readForWrite();
    final existing = accounts[uid];
    final kept = existing?.firstSeen;
    if (kept != null) return kept;
    final seen = DateTime(day.year, day.month, day.day);
    await _store.write({...accounts, uid: (existing ?? const _Account()).copyWith(firstSeen: seen)});
    return seen;
  });

  /// Layar hadiah uji coba akun [uid] sudah ditampilkan.
  Future<Either<Failure, bool>> giftSeen(String uid) => guard(() async => (await _read())[uid]?.giftSeen ?? false);

  /// Menandai layar hadiah [uid] sudah ditampilkan.
  Future<Either<Failure, Unit>> markGiftSeen(String uid) => guardVoid(() async {
    final accounts = await _readForWrite();
    await _store.write({...accounts, uid: (accounts[uid] ?? const _Account()).copyWith(giftSeen: true)});
  });

  /// Mengganti hari akhir uji coba [uid] menjadi [endsOn]. Hanya untuk layar
  /// hadiah, sesaat sesudah uji coba dimulai dan pengguna baru memilih tanggal
  /// gajian (FREEMIUM_PAYWALL §8.1): menolak bila hadiah sudah ditampilkan,
  /// supaya tanggal tidak berubah sesudahnya. Mengembalikan rekaman yang berlaku.
  Future<Either<Failure, TrialRecord?>> reanchor(String uid, DateTime endsOn) => guard(() async {
    final accounts = await _readForWrite();
    final existing = accounts[uid];
    final start = existing?.start;
    final current = existing?.endsOn;
    if (existing == null || start == null || current == null) return null;
    if (existing.giftSeen) return TrialRecord(uid: uid, start: start, endsOn: current);
    await _store.write({...accounts, uid: existing.copyWith(endsOn: endsOn)});
    return TrialRecord(uid: uid, start: start, endsOn: endsOn);
  });

  /// Menyimpan [record] bila akunnya belum punya uji coba; uji coba yang sudah
  /// ada tidak pernah ditimpa. Mengembalikan rekaman yang berlaku.
  Future<Either<Failure, TrialRecord>> save(TrialRecord record) => guard(() async {
    final accounts = await _readForWrite();
    final existing = accounts[record.uid];
    final start = existing?.start;
    final endsOn = existing?.endsOn;
    if (start != null && endsOn != null) return TrialRecord(uid: record.uid, start: start, endsOn: endsOn);
    await _store.write({
      ...accounts,
      record.uid: (existing ?? const _Account()).copyWith(start: record.start, endsOn: record.endsOn),
    });
    return record;
  });
}

final class _Account {
  const _Account({this.firstSeen, this.start, this.endsOn, this.giftSeen = false});

  factory _Account.fromJson(Map<String, dynamic> json) => _Account(
    firstSeen: json['firstSeen'] == null ? null : decodeDay(json['firstSeen']),
    start: json['start'] == null ? null : decodeDay(json['start']),
    endsOn: json['endsOn'] == null ? null : decodeDay(json['endsOn']),
    giftSeen: json['giftSeen'] == true,
  );

  final DateTime? firstSeen;
  final DateTime? start;
  final DateTime? endsOn;
  final bool giftSeen;

  _Account copyWith({DateTime? firstSeen, DateTime? start, DateTime? endsOn, bool? giftSeen}) => _Account(
    firstSeen: firstSeen ?? this.firstSeen,
    start: start ?? this.start,
    endsOn: endsOn ?? this.endsOn,
    giftSeen: giftSeen ?? this.giftSeen,
  );

  Map<String, Object> toJson() => {
    if (firstSeen case final d?) 'firstSeen': encodeDay(d),
    if (start case final d?) 'start': encodeDay(d),
    if (endsOn case final d?) 'endsOn': encodeDay(d),
    if (giftSeen) 'giftSeen': true,
  };
}
