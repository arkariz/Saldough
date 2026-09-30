import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/record/data/capture/rule_based_transaction_interpreter.dart';
import 'package:saldough/features/record/domain/capture/capture_draft_composer.dart';
import 'package:saldough/features/record/domain/capture/interpreted_transaction.dart';
import 'package:saldough/features/record/domain/capture/record_draft.dart';
import 'package:saldough/features/record/domain/capture/speech_transcriber.dart';
import 'package:saldough/features/record/presentation/capture/bloc/voice_capture_bloc.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Pengenal ucapan palsu: memutar ulang [updates] lalu selesai.
final class _FakeTranscriber implements SpeechTranscriber {
  _FakeTranscriber(this.updates);

  final List<SpeechUpdate> updates;
  String? localeId;
  List<String> phrases = const [];
  bool cancelled = false;

  @override
  Stream<SpeechUpdate> listen({required String localeId, List<String> phrases = const []}) {
    this.localeId = localeId;
    this.phrases = phrases;
    return Stream.fromIterable(updates);
  }

  @override
  Future<void> cancel() async => cancelled = true;
}

void main() {
  const wallets = [Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 0, currentBalance: 0)];
  const food = Category(id: 'food', kind: CategoryKind.expense, name: 'Makan', builtInKey: 'food');
  const start = VoiceCaptureStarted(localeId: 'id_ID', languageCode: 'id', wallets: wallets, categories: [food]);
  final now = DateTime(2026, 9, 30, 12);

  VoiceCaptureBloc build(_FakeTranscriber transcriber) => VoiceCaptureBloc(
    transcriber: transcriber,
    composer: CaptureDraftComposer(
      ruleInterpreterFor: (language) =>
          RuleBasedTransactionInterpreter(language: language, categories: () => const [food]),
    ),
    clock: () => now,
  );

  blocTest<VoiceCaptureBloc, VoiceCaptureState>(
    'transkrip akhir menjadi draf lewat interpreter dan resolver; nama dompet dikirim ke pengenal',
    build: () => build(
      _FakeTranscriber(const [SpeechPartial('makan siang'), SpeechFinal('makan siang 35 ribu pakai BCA')]),
    ),
    act: (bloc) => bloc.add(start),
    wait: const Duration(milliseconds: 10),
    verify: (bloc) {
      expect(bloc.state.phase, VoiceCapturePhase.done);
      final draft = bloc.state.draft!;
      expect(draft.kind, DraftKind.expense);
      expect(draft.amountSen, 3500000);
      expect(draft.walletId, 'bca');
      expect(draft.categoryId, 'food');
      expect(draft.sourceText, 'makan siang 35 ribu pakai BCA');
    },
  );

  blocTest<VoiceCaptureBloc, VoiceCaptureState>(
    'bahasa tanpa paket aturan dan tanpa cloud: formulir tetap terbuka dengan transkrip (ADR-029 §3.4)',
    build: () => build(_FakeTranscriber(const [SpeechFinal('コーヒー 500円')])),
    act: (bloc) => bloc.add(
      const VoiceCaptureStarted(localeId: 'ja_JP', languageCode: 'ja', wallets: wallets, categories: [food]),
    ),
    wait: const Duration(milliseconds: 10),
    verify: (bloc) {
      expect(bloc.state.phase, VoiceCapturePhase.done);
      final draft = bloc.state.draft!;
      expect(draft.sourceText, 'コーヒー 500円');
      expect(draft.amountSen, isNull);
      expect(draft.issues, {DraftIssue.amountMissing});
    },
  );

  blocTest<VoiceCaptureBloc, VoiceCaptureState>(
    'teks sementara ditampilkan selama mendengarkan',
    build: () => build(_FakeTranscriber(const [SpeechPartial('tadi ngopi')])),
    act: (bloc) => bloc.add(start),
    wait: const Duration(milliseconds: 10),
    expect: () => [
      const VoiceCaptureState(phase: VoiceCapturePhase.starting),
      const VoiceCaptureState(phase: VoiceCapturePhase.listening, heardText: 'tadi ngopi'),
    ],
  );

  blocTest<VoiceCaptureBloc, VoiceCaptureState>(
    'mikrofon terbuka dan level suara menjadikan tahap merekam',
    build: () => build(_FakeTranscriber(const [SpeechListening(), SpeechLevel(0.6)])),
    act: (bloc) => bloc.add(start),
    wait: const Duration(milliseconds: 10),
    expect: () => [
      const VoiceCaptureState(phase: VoiceCapturePhase.starting),
      const VoiceCaptureState(phase: VoiceCapturePhase.listening),
      const VoiceCaptureState(phase: VoiceCapturePhase.listening, level: 0.6),
    ],
  );

  test('lembar dibuka tanpa merekam: mikrofon baru dibuka setelah VoiceCaptureStarted', () async {
    final transcriber = _FakeTranscriber(const []);
    final bloc = build(transcriber);
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.phase, VoiceCapturePhase.idle);
    expect(transcriber.localeId, isNull);
    await bloc.close();
  });

  blocTest<VoiceCaptureBloc, VoiceCaptureState>(
    'izin ditolak: tahap gagal dengan alasannya, tanpa draf',
    build: () => build(_FakeTranscriber(const [SpeechFailed(SpeechFailure.permissionDenied)])),
    act: (bloc) => bloc.add(start),
    wait: const Duration(milliseconds: 10),
    verify: (bloc) {
      expect(bloc.state.phase, VoiceCapturePhase.failed);
      expect(bloc.state.failure, SpeechFailure.permissionDenied);
      expect(bloc.state.draft, isNull);
    },
  );

  test('menutup bloc membatalkan sesi pengenal', () async {
    final transcriber = _FakeTranscriber(const []);
    final bloc = build(transcriber)..add(start);
    await Future<void>.delayed(Duration.zero);
    await bloc.close();
    expect(transcriber.cancelled, isTrue);
    expect(transcriber.phrases, ['BCA']);
    expect(transcriber.localeId, 'id_ID');
  });
}
