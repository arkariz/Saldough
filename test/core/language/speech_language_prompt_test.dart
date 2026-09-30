import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/language/language.dart';

/// Pertanyaan bahasa ucapan sekali untuk pengguna lama (ADR-028 §3.8).
void main() {
  tearDown(() async {
    await LocaleSettings.setLocale(AppLocale.id);
    ActiveLanguage.notifier.value = AppLocale.id;
  });

  test('belum pernah memilih: ditanya; sesudah memilih: tidak lagi', () async {
    final repository = LanguagePreferenceRepositoryImpl(storage: InMemoryKeyValueStorage());
    final prompt = SpeechLanguagePrompt(
      repository: repository,
      changeLanguage: ChangeAppLanguage(repository: repository),
    );

    expect(await prompt.isPending(), isTrue);
    await prompt.choose(AppLocale.en);
    expect(await prompt.isPending(), isFalse);
    expect(ActiveLanguage.value, AppLocale.en);
  });

  test('memilih bahasa yang sama dengan sekarang tetap tersimpan', () async {
    final repository = LanguagePreferenceRepositoryImpl(storage: InMemoryKeyValueStorage());
    final prompt = SpeechLanguagePrompt(
      repository: repository,
      changeLanguage: ChangeAppLanguage(repository: repository),
    );

    await prompt.choose(ActiveLanguage.value);
    expect(await prompt.isPending(), isFalse);
  });
}
