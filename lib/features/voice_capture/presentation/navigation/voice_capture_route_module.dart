import 'package:di/di.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/foundation/navigation/flow_runner.dart';
import 'package:saldough/core/language/language.dart';
import 'package:saldough/features/voice_capture/di/voice_capture_scope.dart';
import 'package:saldough/features/voice_capture/presentation/bloc/voice_capture_bloc.dart';
import 'package:saldough/features/voice_capture/presentation/navigation/voice_capture_route_keys.dart';
import 'package:saldough/features/voice_capture/presentation/open_voice_capture.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Modul rute fitur `voice_capture` (ADR-030 §3.3, ADR-033 §3.2): alur
/// transparan yang memasang `VoiceCaptureScope`-nya sendiri.
final class VoiceCaptureRouteModule extends FeatureRouteModule {
  /// Membuat [VoiceCaptureRouteModule].
  const VoiceCaptureRouteModule();

  @override
  List<RouteNode> get routes => [
    RouteNode.typed<EmptyInput>(
      key: VoiceCaptureRouteKeys.capture,
      transition: RouteTransition.none,
      defaultInput: () => const EmptyInput(),
      builder: (context, _) {
        final parentContainer = ScopeProvider.of(context);
        return ScopeWidget<VoiceCaptureScope>(
          create: () => VoiceCaptureScope(parentContainer: parentContainer),
          builder: (context, scope) {
            final c = scope.container;
            return FlowRunner(
              run: (context) => openVoiceCapture(
                context,
                walletRepository: c<WalletRepository>(),
                newBloc: c.get<VoiceCaptureBloc>,
                languagePrompt: c.isRegistered<SpeechLanguagePrompt>() ? c<SpeechLanguagePrompt>() : null,
              ),
            );
          },
        );
      },
    ),
  ];
}
