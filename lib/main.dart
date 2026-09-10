import 'package:di/di.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:saldough/app.dart';
import 'package:saldough/core/di/di.dart';
import 'package:saldough/core/foundation/effect_handler/app_effect_registry.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:state_management/state_management.dart';

/// Kontainer DI akar. Lihat ARCHITECTURE_OVERVIEW.md bagian "Bootstrap".
final GetIt rootGetIt = GetIt.instance;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Urutan ini dipertahankan dari flutter-architecture-studi-bank (minus
  // jembatan legacy GetX mereka): pasang Bloc.observer -> di.run() ->
  // daftarkan effect handler -> render router -> di.warmUp() setelah
  // frame pertama. Lihat "Dasar keputusan" di ARCHITECTURE_OVERVIEW.md.
  Bloc.observer = AppBlocObserver();

  await LocaleSettings.useDeviceLocale();
  await di.run(rootGetIt);

  registerEffectHandlers();

  final router = rootGetIt<GoRouter>();

  runApp(TranslationProvider(
    child: SaldoughApp(getIt: rootGetIt, router: router),
  ));

  di.warmUp(rootGetIt);
}
