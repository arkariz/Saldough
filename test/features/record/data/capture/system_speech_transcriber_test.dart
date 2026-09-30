import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/record/data/capture/system_speech_transcriber.dart';
import 'package:saldough/features/record/domain/capture/speech_transcriber.dart';

/// Pemetaan kode galat mentah `speech_to_text` ke [SpeechFailure].
void main() {
  test('paket bahasa luring belum ada (mode pesawat) dibedakan dari tanpa pengenal', () {
    expect(speechFailureFor('error_language_unavailable'), SpeechFailure.languageOffline);
    expect(speechFailureFor('error_language_not_supported'), SpeechFailure.unavailable);
    expect(speechFailureFor('error_client'), SpeechFailure.unavailable);
  });

  test('kode lain', () {
    expect(speechFailureFor('error_network'), SpeechFailure.network);
    expect(speechFailureFor('error_speech_timeout'), SpeechFailure.noMatch);
    expect(speechFailureFor('error_permission'), SpeechFailure.permissionDenied);
    expect(speechFailureFor('error_busy'), SpeechFailure.other);
  });

  test('galat yang dilaporkan hanya berisi kode dan bahasa', () {
    const error = SpeechRecognizerError(code: 'error_language_unavailable', localeId: 'en_US', permanent: true);
    expect(error.toString(), 'SpeechRecognizerError(error_language_unavailable, en_US, permanent: true)');
  });
}
