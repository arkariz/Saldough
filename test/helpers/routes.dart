import 'package:navigation/navigation.dart';
import 'package:saldough/app/di/root_module.dart';

/// Registri rute yang sama dengan aplikasi (ADR-030 §3.3). Daftarkan di
/// kontainer akar uji yang membuka layar fitur lewat `pushRoute`.
RouteRegistry appRouteRegistry() => RouteRegistry.fromModules(RootModule.featureModules);
