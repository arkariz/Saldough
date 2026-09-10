import 'package:go_router/go_router.dart';
import 'package:state_management/state_management.dart';

/// Mendaftarkan penangan untuk keempat efek navigasi dari
/// `package:state_management` ke [GoRouter] lewat navigasi bernama —
/// `GoRoute.name` diisi `RouteNode.keyId` oleh `RouteNodeGoRouterExt`,
/// sehingga penangan ini tidak perlu tahu apa-apa soal path URL.
void registerNavigationEffectHandlers(EffectRegistry registry) {
  registry
    ..register<NavigateGoEffect>((context, effect) {
      context.goNamed(effect.keyId, extra: effect.input);
    })
    ..register<NavigatePushEffect>((context, effect) async {
      final result = await context.pushNamed<Object?>(effect.keyId, extra: effect.input);
      effect.onResult?.call(result);
    })
    ..register<NavigateReplaceEffect>((context, effect) {
      context.pushReplacementNamed(effect.keyId, extra: effect.input);
    })
    ..register<NavigatePopEffect>((context, effect) {
      context.pop(effect.result);
    });
}
