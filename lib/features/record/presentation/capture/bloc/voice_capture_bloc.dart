import 'dart:async';

import 'package:dependencies/dependencies.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/features/record/domain/capture/capture_draft_resolver.dart';
import 'package:saldough/features/record/domain/capture/capture_evidence.dart';
import 'package:saldough/features/record/domain/capture/record_draft.dart';
import 'package:saldough/features/record/domain/capture/speech_transcriber.dart';
import 'package:saldough/features/record/domain/capture/transaction_interpreter.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

part 'voice_capture_event.dart';
part 'voice_capture_state.dart';

/// Bloc lembar rekam Catat Cerdas (ADR-027): mendengarkan, menafsirkan
/// transkrip, lalu menyusun [RecordDraft]. Tidak pernah menyimpan transaksi —
/// drafnya dibuka di formulir CATAT.
final class VoiceCaptureBloc extends Bloc<VoiceCaptureEvent, VoiceCaptureState> {
  /// Membuat [VoiceCaptureBloc].
  VoiceCaptureBloc({
    required this._transcriber,
    required this._interpreter,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(const VoiceCaptureState()) {
    on<VoiceCaptureStarted>(_onStarted);
    on<VoiceCaptureStopped>((_, _) => _transcriber.stop());
    on<_SpeechUpdated>(_onSpeechUpdated);
  }

  final SpeechTranscriber _transcriber;
  final TransactionInterpreter _interpreter;
  final DateTime Function() _clock;
  StreamSubscription<SpeechUpdate>? _subscription;
  List<Wallet> _wallets = const [];
  List<Category> _categories = const [];

  void _onStarted(VoiceCaptureStarted event, Emitter<VoiceCaptureState> emit) {
    _wallets = event.wallets;
    _categories = event.categories;
    emit(const VoiceCaptureState());
    unawaited(_subscription?.cancel());
    _subscription = _transcriber
        .listen(localeId: event.localeId, phrases: [for (final w in event.wallets) w.name])
        .listen((update) => add(_SpeechUpdated(update)));
  }

  Future<void> _onSpeechUpdated(_SpeechUpdated event, Emitter<VoiceCaptureState> emit) async {
    switch (event.update) {
      case SpeechPartial(:final text):
        emit(state.copyWith(heardText: text));
      case SpeechFailed(:final reason):
        emit(state.copyWith(phase: VoiceCapturePhase.failed, failure: reason));
      case SpeechFinal(:final text):
        emit(state.copyWith(phase: VoiceCapturePhase.interpreting, heardText: text));
        final now = _clock();
        final evidence = CaptureEvidence(source: CaptureSource.voice, text: text, capturedAt: now);
        final context = InterpretationContext(
          walletNames: [for (final w in _wallets) w.name],
          expenseCategoryNames: [
            for (final c in _categories)
              if (c.kind == CategoryKind.expense && !c.isArchived) c.name,
          ],
          incomeCategoryNames: [
            for (final c in _categories)
              if (c.kind == CategoryKind.income && !c.isArchived) c.name,
          ],
          today: now,
        );
        switch (await _interpreter.interpret(evidence, context)) {
          case Left():
            emit(state.copyWith(phase: VoiceCapturePhase.failed, failure: SpeechFailure.other));
          case Right(value: final interpreted):
            final draft = CaptureDraftResolver(
              wallets: _wallets,
              categories: _categories,
              currencyCode: ActiveCurrency.value.code,
            ).resolve(evidence, interpreted);
            emit(state.copyWith(phase: VoiceCapturePhase.done, draft: draft));
        }
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await _transcriber.cancel();
    return super.close();
  }
}
