import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/language/language_preference_repository.dart';

const _languageKey = StorageKey(namespace: 'settings', name: 'language');

/// Implementasi [LanguagePreferenceRepository] di atas [KeyValueStorage]:
/// satu dokumen `{schemaVersion, code}`, pola yang sama dengan mata uang.
final class LanguagePreferenceRepositoryImpl with RepositoryGuard implements LanguagePreferenceRepository {
  /// Membuat [LanguagePreferenceRepositoryImpl] di atas [_storage].
  const LanguagePreferenceRepositoryImpl({required this._storage});

  /// Versi skema dokumen.
  static const schemaVersion = 1;

  final KeyValueStorage _storage;

  StoredValue<AppLocale?> get _store => StoredValue<AppLocale?>.json(
    key: _languageKey,
    fromJson: (json) {
      final code = json['code'] as String?;
      for (final locale in AppLocale.values) {
        if (locale.languageCode == code) return locale;
      }
      return null;
    },
    toJson: (locale) => {'schemaVersion': schemaVersion, 'code': locale?.languageCode},
    storage: _storage,
  );

  @override
  Future<Either<Failure, AppLocale?>> load() => guard(_store.read);

  @override
  Future<Either<Failure, Unit>> save(AppLocale locale) => guardVoid(() => _store.write(locale));
}
