import 'dart:async';

import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/features/record/domain/capture/speech_transcriber.dart';
import 'package:saldough/shared/capture/capture.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

part 'voice_capture_event.dart';
part 'voice_capture_state.dart';

/// Bloc lembar rekam Catat Cerdas (ADR-027): menunggu pengguna menekan rekam,
/// mendengarkan, menafsirkan transkrip, lalu menyusun [RecordDraft]. Tidak
/// pernah menyimpan transaksi — drafnya dibuka di formulir CATAT.
///
/// Rekaman tidak pernah mulai sendiri: lembar dibuka di tahap
/// [VoiceCapturePhase.idle], dan mikrofon baru dibuka oleh
/// [VoiceCaptureStarted] dari tombol rekam.
final class VoiceCaptureBloc extends Bloc<VoiceCaptureEvent, VoiceCaptureState> {
  /// Membuat [VoiceCaptureBloc].
  VoiceCaptureBloc({
    required this._transcriber,
    required this._composer,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(const VoiceCaptureState()) {
    on<VoiceCaptureStarted>(_onStarted);
    on<_SpeechUpdated>(_onSpeechUpdated);
  }

  final SpeechTranscriber _transcriber;
  final CaptureDraftComposer _composer;
  final DateTime Function() _clock;
  StreamSubscription<SpeechUpdate>? _subscription;
  List<Wallet> _wallets = const [];
  List<Category> _categories = const [];
  String _languageCode = '';

  void _onStarted(VoiceCaptureStarted event, Emitter<VoiceCaptureState> emit) {
    _wallets = event.wallets;
    _categories = event.categories;
    _languageCode = event.languageCode;
    emit(const VoiceCaptureState(phase: VoiceCapturePhase.starting));
    unawaited(_subscription?.cancel());
    _subscription = _transcriber
        .listen(localeId: event.localeId, phrases: [for (final w in event.wallets) w.name])
        .listen((update) => add(_SpeechUpdated(update)));
  }

  Future<void> _onSpeechUpdated(_SpeechUpdated event, Emitter<VoiceCaptureState> emit) async {
    switch (event.update) {
      case SpeechListening():
        if (state.phase == VoiceCapturePhase.starting) emit(state.copyWith(phase: VoiceCapturePhase.listening));
      case SpeechLevel(:final level):
        if (state.phase == VoiceCapturePhase.starting || state.phase == VoiceCapturePhase.listening) {
          emit(state.copyWith(phase: VoiceCapturePhase.listening, level: level));
        }
      case SpeechPartial(:final text):
        emit(state.copyWith(phase: VoiceCapturePhase.listening, heardText: text));
      case SpeechFailed(:final reason):
        emit(state.copyWith(phase: VoiceCapturePhase.failed, failure: reason));
      case SpeechFinal(:final text):
        emit(state.copyWith(phase: VoiceCapturePhase.interpreting, heardText: text, level: 0));
        final evidence = CaptureEvidence(
          source: CaptureSource.voice,
          text: text,
          capturedAt: _clock(),
          languageCode: _languageCode,
        );
        // Penyusun tidak pernah gagal: tanpa hasil tafsir, formulir tetap
        // terbuka dengan transkrip terlihat (ADR-029 §3.4).
        final draft = await _composer.compose(
          evidence,
          wallets: _wallets,
          categories: _categories,
          currencyCode: ActiveCurrency.value.code,
        );
        emit(state.copyWith(phase: VoiceCapturePhase.done, draft: draft));
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await _transcriber.cancel();
    return super.close();
  }
}
