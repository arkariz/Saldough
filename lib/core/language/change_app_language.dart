import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/language/active_language.dart';
import 'package:saldough/core/language/language_preference_repository.dart';

/// Mengganti bahasa aplikasi (ADR-028 §3.3): simpan pilihan, pasang locale
/// slang, perbarui [ActiveLanguage], lalu jalankan [afterChange] (mis.
/// mengganti nama kategori bawaan, ADR-028 §3.7).
///
/// Pilihan disimpan lebih dulu: gagal menyimpan berarti bahasa tidak berganti,
/// bukan berganti sementara lalu kembali saat aplikasi dibuka ulang.
final class ChangeAppLanguage {
  /// Membuat [ChangeAppLanguage].
  const ChangeAppLanguage({required this._repository, this._afterChange});

  final LanguagePreferenceRepository _repository;
  final Future<void> Function(AppLocale from, AppLocale to)? _afterChange;

  /// Mengganti bahasa ke [to].
  Future<Either<Failure, Unit>> call(AppLocale to) async {
    final from = LocaleSettings.currentLocale;
    if (await _repository.save(to) case Left(value: final failure)) return left(failure);
    await LocaleSettings.setLocale(to);
    ActiveLanguage.notifier.value = to;
    if (from != to) await _afterChange?.call(from, to);
    return right(unit);
  }
}
