import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/record/data/capture/rule_based_transaction_interpreter.dart';
import 'package:saldough/features/record/domain/capture/capture_draft_composer.dart';
import 'package:saldough/features/record/domain/capture/speech_transcriber.dart';
import 'package:saldough/features/record/presentation/capture/bloc/voice_capture_bloc.dart';
import 'package:saldough/features/record/presentation/capture/voice_capture_sheet.dart';
import 'package:state_management/state_management.dart';

/// Pengenal ucapan palsu: memutar ulang [updates] lalu selesai.
final class _FakeTranscriber implements SpeechTranscriber {
  _FakeTranscriber(this.updates);

  final List<SpeechUpdate> updates;
  int listens = 0;

  @override
  Stream<SpeechUpdate> listen({required String localeId, List<String> phrases = const []}) {
    listens++;
    return Stream.fromIterable(updates);
  }

  @override
  Future<void> cancel() async {}
}

void main() {
  const start = VoiceCaptureStarted(localeId: 'id_ID', languageCode: 'id', wallets: [], categories: []);

  Future<_FakeTranscriber> pumpSheet(WidgetTester tester, List<SpeechUpdate> updates) async {
    final transcriber = _FakeTranscriber(updates);
    final bloc = VoiceCaptureBloc(
      transcriber: transcriber,
      composer: CaptureDraftComposer(
        ruleInterpreterFor: (language) =>
            RuleBasedTransactionInterpreter(language: language, categories: () => const []),
      ),
    );
    addTearDown(bloc.close);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider.value(value: bloc, child: const VoiceCaptureSheet(start: start)),
        ),
      ),
    );
    return transcriber;
  }

  AppButtonVariant typeInsteadVariant(WidgetTester tester) =>
      tester.widget<AppButton>(find.byKey(const ValueKey('voice-type-instead'))).variant;

  String textOf(WidgetTester tester, String key) => tester.widget<Text>(find.byKey(ValueKey(key))).data!;

  testWidgets('lembar dibuka siap; "Ketik saja" tombol sekunder', (tester) async {
    await pumpSheet(tester, const []);

    expect(textOf(tester, 'voice-primary-text'), t.record.voice.idleHint);
    expect(textOf(tester, 'voice-secondary-text'), t.record.voice.example);
    // Label tombol tidak diulang sebagai teks; petunjuk utama sudah cukup.
    expect(find.text(t.record.voice.startAction), findsNothing);
    expect(typeInsteadVariant(tester), AppButtonVariant.secondary);
  });

  testWidgets('teks berjenjang: yang tertangkap jadi pesan utama, petunjuk jadi keterangan kecil', (tester) async {
    await pumpSheet(tester, const [SpeechListening(), SpeechPartial('makan siang')]);

    await tester.tap(find.byKey(const ValueKey('voice-record-button')));
    await tester.pump(const Duration(milliseconds: 50));

    expect(textOf(tester, 'voice-primary-text'), '“makan siang”');
    expect(textOf(tester, 'voice-secondary-text'), t.record.voice.autoStopHint);
    expect(find.text(t.record.voice.example), findsNothing);
    expect(find.text(t.record.voice.listening), findsNothing);
  });

  testWidgets('selama merekam tombol tidak menghentikan rekaman: berhenti sendiri', (tester) async {
    final transcriber = await pumpSheet(tester, const [SpeechListening()]);

    await tester.tap(find.byKey(const ValueKey('voice-record-button')));
    await tester.pump(const Duration(milliseconds: 50));
    expect(textOf(tester, 'voice-primary-text'), t.record.voice.listening);
    expect(textOf(tester, 'voice-secondary-text'), t.record.voice.autoStopHint);

    await tester.tap(find.byKey(const ValueKey('voice-record-button')));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text(t.record.voice.listening), findsOneWidget);
    expect(transcriber.listens, 1);
  });

  testWidgets('gagal karena jaringan: pesan butuh internet, "Ketik saja" jadi tombol utama', (tester) async {
    await pumpSheet(tester, const [SpeechFailed(SpeechFailure.network)]);

    await tester.tap(find.byKey(const ValueKey('voice-record-button')));
    await tester.pump(const Duration(milliseconds: 50));

    expect(textOf(tester, 'voice-primary-text'), t.record.voice.failure.network);
    expect(find.byKey(const ValueKey('voice-secondary-text')), findsNothing);
    expect(find.text(t.record.voice.retryAction), findsOneWidget);
    expect(typeInsteadVariant(tester), AppButtonVariant.primary);
  });

  testWidgets('paket bahasa luring belum ada: pesan khusus, "Ketik saja" jadi tombol utama', (tester) async {
    await pumpSheet(tester, const [SpeechFailed(SpeechFailure.languageOffline)]);

    await tester.tap(find.byKey(const ValueKey('voice-record-button')));
    await tester.pump(const Duration(milliseconds: 50));

    expect(textOf(tester, 'voice-primary-text'), t.record.voice.failure.languageOffline);
    expect(typeInsteadVariant(tester), AppButtonVariant.primary);
  });

  testWidgets('tidak ada ucapan tertangkap: rekam ulang tetap jalan utama', (tester) async {
    await pumpSheet(tester, const [SpeechFailed(SpeechFailure.noMatch)]);

    await tester.tap(find.byKey(const ValueKey('voice-record-button')));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text(t.record.voice.failure.noMatch), findsOneWidget);
    expect(typeInsteadVariant(tester), AppButtonVariant.secondary);
  });
}
