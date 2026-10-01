import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/voice_capture/data/system_speech_transcriber.dart';
import 'package:saldough/features/voice_capture/domain/speech_transcriber.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Pengenal palsu yang meniru `SpeechToText`: singleton, dan `initialize`
/// hanya memasang pendengar pada panggilan pertama.
final class _FakeSpeech extends Fake implements SpeechToText {
  bool _initialized = false;
  Exception? listenError;
  Completer<void> listened = Completer<void>();

  @override
  SpeechErrorListener? errorListener;

  @override
  SpeechStatusListener? statusListener;

  @override
  Future<bool> initialize({
    SpeechErrorListener? onError,
    SpeechStatusListener? onStatus,
    dynamic debugLogging = false,
    Duration finalTimeout = SpeechToText.defaultFinalTimeout,
    List<SpeechConfigOption>? options,
  }) async {
    if (!_initialized) {
      errorListener = onError;
      statusListener = onStatus;
      _initialized = true;
    }
    return true;
  }

  @override
  Future<bool> get hasPermission async => true;

  @override
  Future<dynamic> listen({
    SpeechResultListener? onResult,
    Duration? listenFor,
    Duration? pauseFor,
    String? localeId,
    SpeechSoundLevelChange? onSoundLevelChange,
    dynamic cancelOnError = false,
    dynamic partialResults = true,
    dynamic onDevice = false,
    ListenMode listenMode = ListenMode.confirmation,
    dynamic sampleRate = 0,
    SpeechListenOptions? listenOptions,
  }) async {
    listened.complete();
    if (listenError case final error?) throw error;
  }

  @override
  Future<void> cancel() async {}
}

Matcher _failedWith(SpeechFailure reason) => isA<SpeechFailed>().having((f) => f.reason, 'reason', reason);

/// Pemetaan kode galat mentah `speech_to_text` ke [SpeechFailure], dan daur
/// hidup sesi (verifikasi M2, G2 dan G3).
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

  test('instance baru di atas pengenal yang sudah diinisialisasi tetap menerima status "done"', () async {
    final speech = _FakeSpeech();
    final first = SystemSpeechTranscriber(speech: speech, reportError: (_) {});
    final firstUpdates = first.listen(localeId: 'id_ID').toList();
    await speech.listened.future;
    speech.statusListener!(SpeechToText.doneStatus);
    expect((await firstUpdates).last, _failedWith(SpeechFailure.noMatch));

    // Mis. `RecordScope` dibuat ulang: instance lain, singleton yang sama.
    speech.listened = Completer<void>();
    final second = SystemSpeechTranscriber(speech: speech, reportError: (_) {});
    final secondUpdates = second.listen(localeId: 'id_ID').toList();
    await speech.listened.future;
    speech.statusListener!(SpeechToText.doneStatus);
    expect((await secondUpdates).last, _failedWith(SpeechFailure.noMatch));
  });

  test('listen melempar: sesi gagal dan kodenya dilaporkan', () async {
    final reported = <String>[];
    final speech = _FakeSpeech()..listenError = PlatformException(code: 'busy');
    final updates = await SystemSpeechTranscriber(
      speech: speech,
      reportError: (e) => reported.add(e.code),
    ).listen(localeId: 'id_ID').toList();
    expect(updates.single, _failedWith(SpeechFailure.other));
    expect(reported, ['listen_failed']);
  });

  test('pengenal tidak pernah mulai: sesi gagal sesudah batas tunggu', () async {
    final reported = <String>[];
    final updates = await SystemSpeechTranscriber(
      speech: _FakeSpeech(),
      reportError: (e) => reported.add(e.code),
      startTimeout: const Duration(milliseconds: 30),
    ).listen(localeId: 'id_ID').toList();
    expect(updates.single, _failedWith(SpeechFailure.other));
    expect(reported, ['listen_not_started']);
  });
}
