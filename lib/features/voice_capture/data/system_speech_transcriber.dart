import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:saldough/core/foundation/analytics/app_bootstrap_firebase.dart';
import 'package:saldough/features/voice_capture/domain/speech_transcriber.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// [SpeechTranscriber] di atas pengenal ucapan bawaan Android/iOS lewat paket
/// `speech_to_text` (riset §4). Mode server diizinkan pemilik (30 Sep 2026):
/// bahasa Indonesia luring tidak terjamin di semua perangkat, jadi
/// `onDevice` tidak dipaksa.
final class SystemSpeechTranscriber implements SpeechTranscriber {
  /// Membuat [SystemSpeechTranscriber]. [reportError] menerima kode galat
  /// mentah pengenal (bawaan: non-fatal Crashlytics), supaya pemetaan ke
  /// [SpeechFailure] bisa dicocokkan dengan perangkat nyata.
  /// [startTimeout] membatasi tunggu sampai pengenal benar-benar mulai.
  SystemSpeechTranscriber({
    SpeechToText? speech,
    void Function(SpeechRecognizerError error)? reportError,
    this._startTimeout = const Duration(seconds: 5),
  }) : _speech = speech ?? SpeechToText(),
       _reportError = reportError ?? _reportToCrashlytics;

  final SpeechToText _speech;
  final void Function(SpeechRecognizerError error) _reportError;
  final Duration _startTimeout;

  /// Pengenal sudah memberi kabar (status, suara, atau hasil) di sesi ini.
  bool _started = false;
  String _localeId = '';
  StreamController<SpeechUpdate>? _controller;
  String _lastWords = '';

  /// Galat terakhir sesi ini; status "done" bisa datang lebih dulu darinya.
  SpeechFailure? _errorReason;

  /// Jeda sebelum menyimpulkan "tidak ada ucapan" dari status "done",
  /// memberi kesempatan galat yang menyusul (mis. layanan pengenal tidak ada)
  /// menjadi alasan yang dilaporkan.
  static const _errorGrace = Duration(milliseconds: 400);

  /// Batas diam sebelum sesi dianggap selesai; satu transaksi diucapkan
  /// dalam satu napas.
  static const _pauseFor = Duration(seconds: 3);

  /// Batas panjang satu sesi.
  static const _listenFor = Duration(seconds: 20);

  @override
  Stream<SpeechUpdate> listen({required String localeId, List<String> phrases = const []}) {
    unawaited(_controller?.close());
    final controller = StreamController<SpeechUpdate>();
    _controller = controller;
    _lastWords = '';
    _errorReason = null;
    _started = false;
    _localeId = localeId;
    unawaited(_start(controller, localeId, phrases));
    return controller.stream;
  }

  Future<void> _start(StreamController<SpeechUpdate> controller, String localeId, List<String> phrases) async {
    bool available;
    try {
      available = await _speech.initialize(onError: _onError, onStatus: _onStatus);
    } on Object {
      available = false;
    }
    if (!available) {
      final permitted = await _speech.hasPermission;
      _finish(SpeechFailed(permitted ? SpeechFailure.unavailable : SpeechFailure.permissionDenied));
      return;
    }
    // `SpeechToText` adalah singleton dan `initialize` hanya memasang
    // pendengar di panggilan pertama per proses. Pasang ulang setiap sesi,
    // supaya instance ini (mis. sesudah `RecordScope` dibuat ulang) tetap
    // menerima status "done" dan galat.
    _speech
      ..errorListener = _onError
      ..statusListener = _onStatus;
    try {
      await _speech.listen(
        onResult: _onResult,
        onSoundLevelChange: _onSoundLevel,
        listenOptions: SpeechListenOptions(
          localeId: localeId,
          pauseFor: _pauseFor,
          listenFor: _listenFor,
          cancelOnError: true,
          contextualPhrases: phrases.isEmpty ? null : phrases,
        ),
      );
    } on Object {
      _failToStart(controller, 'listen_failed');
      return;
    }
    // Pengenal yang tidak mulai tidak mengirim kabar apa pun; tanpa batas
    // ini lembar rekam tertahan di tahap "memulai".
    unawaited(
      Future<void>.delayed(_startTimeout, () {
        if (!_started) _failToStart(controller, 'listen_not_started');
      }),
    );
  }

  /// Menutup sesi [controller] (bila masih sesi ini) karena pengenal gagal
  /// mulai, dan melaporkan [code].
  void _failToStart(StreamController<SpeechUpdate> controller, String code) {
    if (!identical(controller, _controller)) return;
    _reportError(SpeechRecognizerError(code: code, localeId: _localeId, permanent: false));
    unawaited(_speech.cancel().catchError((_) {}));
    _finish(const SpeechFailed(SpeechFailure.other));
  }

  /// Level mentah plugin kira-kira -2..10 dB (Android) -- dipetakan ke 0..1.
  void _onSoundLevel(double level) {
    _started = true;
    _controller?.add(SpeechLevel(((level + 2) / 12).clamp(0.0, 1.0)));
  }

  void _onResult(SpeechRecognitionResult result) {
    _started = true;
    _lastWords = result.recognizedWords;
    if (result.finalResult) {
      _finishWithWordsOr(SpeechFailure.noMatch);
    } else {
      _controller?.add(SpeechPartial(_lastWords));
    }
  }

  void _onError(SpeechRecognitionError error) {
    _started = true;
    final reason = speechFailureFor(error.errorMsg);
    // Diam dan tidak terdengar adalah pemakaian biasa, bukan galat.
    if (reason != SpeechFailure.noMatch) {
      _reportError(SpeechRecognizerError(code: error.errorMsg, localeId: _localeId, permanent: error.permanent));
    }
    _errorReason = reason;
    // Kata yang sudah tertangkap sebelum galat tetap dipakai.
    _finishWithWordsOr(reason);
  }

  void _onStatus(String status) {
    _started = true;
    if (status == SpeechToText.listeningStatus) _controller?.add(const SpeechListening());
    // "done" tanpa hasil akhir: pakai kata terakhir kalau ada.
    final controller = _controller;
    if (status == SpeechToText.doneStatus && controller != null) {
      unawaited(
        Future<void>.delayed(_errorGrace, () {
          if (identical(controller, _controller)) _finishWithWordsOr(SpeechFailure.noMatch);
        }),
      );
    }
  }

  /// Menutup sesi dengan kata yang sudah tertangkap, atau dengan [reason].
  /// Tanpa kata, izin diperiksa lebih dulu: di Android, izin mikrofon yang
  /// ditolak tampil sebagai sesi "selesai" tanpa hasil, bukan galat izin.
  void _finishWithWordsOr(SpeechFailure reason) {
    if (_lastWords.trim().isNotEmpty) {
      _finish(SpeechFinal(_lastWords));
      return;
    }
    final controller = _controller;
    unawaited(
      _speech.hasPermission.then((permitted) {
        if (identical(controller, _controller)) {
          _finish(SpeechFailed(permitted ? (_errorReason ?? reason) : SpeechFailure.permissionDenied));
        }
      }),
    );
  }

  void _finish(SpeechUpdate update) {
    final controller = _controller;
    if (controller == null || controller.isClosed) return;
    controller.add(update);
    unawaited(controller.close());
    _controller = null;
  }

  @override
  Future<void> cancel() async {
    await _speech.cancel();
    final controller = _controller;
    _controller = null;
    await controller?.close();
  }
}

/// Galat mentah pengenal ucapan untuk dilaporkan. Hanya kode, bahasa, dan
/// sifatnya -- tidak pernah isi ucapan.
final class SpeechRecognizerError implements Exception {
  /// Membuat [SpeechRecognizerError].
  const SpeechRecognizerError({required this.code, required this.localeId, required this.permanent});

  /// Kode dari plugin, mis. `error_language_unavailable`.
  final String code;

  /// Bahasa sesi, mis. `en_US`.
  final String localeId;

  /// Galat permanen menurut plugin.
  final bool permanent;

  @override
  String toString() => 'SpeechRecognizerError($code, $localeId, permanent: $permanent)';
}

void _reportToCrashlytics(SpeechRecognizerError error) =>
    AppBootstrap.recordNonFatal(error, reason: 'SpeechRecognizer');

/// [SpeechFailure] untuk kode galat mentah `speech_to_text` (Android).
@visibleForTesting
SpeechFailure speechFailureFor(String code) => switch (code) {
  'error_no_match' || 'error_speech_timeout' => SpeechFailure.noMatch,
  'error_network' || 'error_network_timeout' || 'error_server' => SpeechFailure.network,
  'error_permission' || 'error_insufficient_permissions' => SpeechFailure.permissionDenied,
  // Bahasa didukung tetapi paket luringnya belum ada dan tidak ada internet
  // (Android 12+, ERROR_LANGUAGE_UNAVAILABLE).
  'error_language_unavailable' => SpeechFailure.languageOffline,
  // Tanpa layanan pengenal terpilih ("no selected voice recognition
  // service") atau bahasa tidak didukung sama sekali.
  'error_client' || 'error_language_not_supported' || 'error_cannot_check_support' => SpeechFailure.unavailable,
  _ => SpeechFailure.other,
};
