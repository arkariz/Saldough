import 'package:di/di.dart';
import 'package:saldough/core/language/language.dart';
import 'package:saldough/features/voice_capture/data/system_speech_transcriber.dart';
import 'package:saldough/features/voice_capture/domain/speech_transcriber.dart';
import 'package:saldough/features/voice_capture/presentation/bloc/voice_capture_bloc.dart';
import 'package:saldough/shared/capture/capture.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Lingkup dependensi fitur `voice_capture` (ADR-027, ADR-033 §3.2).
final class VoiceCaptureScope extends IsolatedScope {
  /// Membuat [VoiceCaptureScope] dengan kontainer induk [parentContainer].
  VoiceCaptureScope({required super.parentContainer});

  @override
  void bridge(GetIt c) {
    c.registerSingleton<WalletRepository>(parent<WalletRepository>());
    // Opsional: kontainer induk yang tidak menyediakannya (mis. uji) berarti
    // suara dibuka tanpa bertanya bahasa.
    if (parent.isRegistered<SpeechLanguagePrompt>()) {
      c.registerSingleton<SpeechLanguagePrompt>(parent<SpeechLanguagePrompt>());
    }
  }

  @override
  void register(GetIt c) {
    c
      // Aturan per paket bahasa; cloud (Firebase AI, T-11.7) hanya bila draf
      // aturan ragu atau bahasanya tanpa paket (ADR-029 §3.4).
      ..registerLazySingleton<SpeechTranscriber>(SystemSpeechTranscriber.new)
      ..registerLazySingleton<CaptureDraftComposer>(
        () => CaptureDraftComposer(
          ruleInterpreterFor: (language) => RuleBasedTransactionInterpreter(
            language: language,
            categories: () => ActiveCategories.notifier.value,
          ),
          cloudInterpreter: FirebaseAiTransactionInterpreter(),
        ),
      )
      // Satu bloc per lembar rekam; lembarnya yang menutup bloc.
      ..registerFactory<VoiceCaptureBloc>(
        () => VoiceCaptureBloc(transcriber: c<SpeechTranscriber>(), composer: c<CaptureDraftComposer>()),
      );
  }
}
