import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/language/change_app_language.dart';
import 'package:saldough/core/language/language_preference_repository.dart';

/// Pertanyaan bahasa ucapan sekali untuk pengguna yang belum pernah memilih
/// bahasa, mis. pengguna lama sesudah update yang tidak melewati langkah
/// bahasa onboarding (ADR-028 §3.8).
final class SpeechLanguagePrompt {
  /// Membuat [SpeechLanguagePrompt].
  const SpeechLanguagePrompt({required this._repository, required this._changeLanguage});

  final LanguagePreferenceRepository _repository;
  final ChangeAppLanguage _changeLanguage;

  /// `true` kalau belum ada pilihan tersimpan. Gagal membaca dianggap tidak
  /// perlu bertanya: merekam tidak boleh terhalang oleh penyimpanan.
  Future<bool> isPending() async => switch (await _repository.load()) {
    Right(value: null) => true,
    _ => false,
  };

  /// Menyimpan [locale] sebagai bahasa aplikasi (tampilan + ucapan).
  Future<Either<Failure, Unit>> choose(AppLocale locale) => _changeLanguage(locale);
}
