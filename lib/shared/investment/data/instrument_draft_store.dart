import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/shared/investment/data/investment_models.dart';
import 'package:saldough/shared/investment/domain/instrument.dart';

const _draftKey = StorageKey(namespace: 'investment', name: 'draft');

/// Draf formulir instrumen baru yang tertahan paywall P12 (ADR-049 §3.12):
/// satu draf, milik perangkat, tidak ikut cadangan.
final class InstrumentDraftStore with RepositoryGuard {
  /// Membuat [InstrumentDraftStore].
  const InstrumentDraftStore({required this._storage});

  final KeyValueStorage _storage;

  StoredValue<Instrument> get _store => StoredValue<Instrument>.json(
    key: _draftKey,
    fromJson: (json) => InstrumentModel.fromJson(json['draft'] as Map<String, dynamic>),
    toJson: (i) => {'schemaVersion': InstrumentModel.schemaVersion, 'draft': InstrumentModel.toJson(i)},
    storage: _storage,
  );

  /// Draf tersimpan, atau `null`.
  Future<Either<Failure, Instrument?>> read() => guard(_store.read);

  /// Menyimpan [instrument] sebagai draf, menimpa yang lama.
  Future<Either<Failure, Unit>> save(Instrument instrument) => guardVoid(() => _store.write(instrument));

  /// Membuang draf.
  Future<Either<Failure, Unit>> clear() => guardVoid(_store.remove);
}
