import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/record/data/capture/rule_based_transaction_interpreter.dart';
import 'package:saldough/features/record/domain/capture/speech_transcriber.dart';
import 'package:saldough/features/record/presentation/capture/bloc/voice_capture_bloc.dart';
import 'package:saldough/features/record/presentation/capture/voice_capture_sheet.dart';
import 'package:state_management/state_management.dart';

/// Pengenal ucapan palsu: memutar ulang [updates] lalu selesai.
final class _FakeTranscriber implements SpeechTranscriber {
  _FakeTranscriber(this.updates);

  final List<SpeechUpdate> updates;

  @override
  Stream<SpeechUpdate> listen({required String localeId, List<String> phrases = const []}) =>
      Stream.fromIterable(updates);

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancel() async {}
}

void main() {
  const start = VoiceCaptureStarted(localeId: 'id_ID', wallets: [], categories: []);

  Future<void> pumpSheet(WidgetTester tester, List<SpeechUpdate> updates) async {
    final bloc = VoiceCaptureBloc(
      transcriber: _FakeTranscriber(updates),
      interpreter: RuleBasedTransactionInterpreter(categories: () => const []),
    );
    addTearDown(bloc.close);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider.value(value: bloc, child: const VoiceCaptureSheet(start: start)),
        ),
      ),
    );
  }

  AppButtonVariant typeInsteadVariant(WidgetTester tester) =>
      tester.widget<AppButton>(find.byKey(const ValueKey('voice-type-instead'))).variant;

  testWidgets('lembar dibuka siap; "Ketik saja" tombol sekunder', (tester) async {
    await pumpSheet(tester, const []);

    expect(find.text(t.record.voice.idleHint), findsOneWidget);
    expect(typeInsteadVariant(tester), AppButtonVariant.secondary);
  });

  testWidgets('gagal karena jaringan: pesan butuh internet, "Ketik saja" jadi tombol utama', (tester) async {
    await pumpSheet(tester, const [SpeechFailed(SpeechFailure.network)]);

    await tester.tap(find.byKey(const ValueKey('voice-record-button')));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text(t.record.voice.failure.network), findsOneWidget);
    expect(find.text(t.record.voice.retryAction), findsOneWidget);
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
