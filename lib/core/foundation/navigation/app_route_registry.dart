import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show NavigatorObserver;
import 'package:go_router/go_router.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/foundation/navigation/route_node_go_router_ext.dart';

/// Membangun [GoRouter] dari satu [RouteRegistry].
///
/// Path URL tiap rute diturunkan dari [RouteNode.keyId] dengan mengganti
/// `.` jadi `/` (`'cycle.detail'` → `/cycle/detail`), supaya tidak perlu
/// mendaftarkan path secara manual dan terpisah dari key.
abstract final class AppRouteRegistry {
  AppRouteRegistry._();

  /// Path rute `home` (shell navigasi utama, `AppShellPage`) — satu-
  /// satunya rute yang dibangun langsung sebagai `GoRoute` di sini, di
  /// luar `RouteRegistry`, karena bukan milik satu fitur (lihat
  /// `AppShellPage`).
  static const homePath = '/home';

  /// Path rute onboarding (ADR-021 §3.2) — dibangun langsung di sini seperti
  /// [homePath], karena ia gerbang aplikasi, bukan milik satu fitur modul
  /// rute.
  static const onboardingPath = '/onboarding';

  /// Membangun [GoRouter] dari [registry], dimulai dari [initialLocation].
  /// [homeBuilder] membangun layar untuk [homePath], [onboardingBuilder]
  /// untuk [onboardingPath]; keduanya menerima [GoRouterState] supaya bisa
  /// membaca `extra`.
  static GoRouter build({
    required RouteRegistry registry,
    required String initialLocation,
    required GoRouterWidgetBuilder homeBuilder,
    required GoRouterWidgetBuilder onboardingBuilder,
    List<NavigatorObserver> observers = const [],
  }) {
    final routes = [
      GoRoute(path: homePath, name: 'home', builder: homeBuilder),
      GoRoute(path: onboardingPath, name: 'onboarding', builder: onboardingBuilder),
      ...registry.registeredNodes.map((node) => node.toGoRoute(_pathFor(node.keyId))),
    ];

    return GoRouter(
      initialLocation: initialLocation,
      debugLogDiagnostics: kDebugMode,
      routes: routes,
      observers: observers,
    );
  }

  static String _pathFor(String keyId) => '/${keyId.replaceAll('.', '/')}';
}
