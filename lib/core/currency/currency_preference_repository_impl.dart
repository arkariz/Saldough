import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/currency/app_currency.dart';
import 'package:saldough/core/currency/currency_preference_repository.dart';
import 'package:saldough/core/foundation/repository_guard.dart';

const _currencyKey = StorageKey(namespace: 'settings', name: 'currency');

/// Implementasi [CurrencyPreferenceRepository] di atas [KeyValueStorage]:
/// satu dokumen `{schemaVersion, code}`.
final class CurrencyPreferenceRepositoryImpl with RepositoryGuard implements CurrencyPreferenceRepository {
  /// Membuat [CurrencyPreferenceRepositoryImpl] di atas [_storage].
  const CurrencyPreferenceRepositoryImpl({required this._storage});

  /// Versi skema dokumen.
  static const schemaVersion = 1;

  final KeyValueStorage _storage;

  StoredValue<AppCurrency> get _store => StoredValue<AppCurrency>.json(
    key: _currencyKey,
    fromJson: (json) => AppCurrency.fromCode(json['code'] as String? ?? '') ?? AppCurrency.idr,
    toJson: (currency) => {'schemaVersion': schemaVersion, 'code': currency.code},
    storage: _storage,
  );

  @override
  Future<Either<Failure, AppCurrency>> load() => guard(() async => await _store.read() ?? AppCurrency.idr);

  @override
  Future<Either<Failure, Unit>> save(AppCurrency currency) => guardVoid(() => _store.write(currency));
}
