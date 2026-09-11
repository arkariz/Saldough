import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
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

  /// Path rute `home` (shell navigasi utama, `MainShellPage`) — satu-
  /// satunya rute yang dibangun langsung sebagai `GoRoute` di sini, di
  /// luar `RouteRegistry`, karena bukan milik satu fitur (lihat
  /// `MainShellPage`).
  static const homePath = '/home';

  /// Membangun [GoRouter] dari [registry], dimulai dari [initialLocation].
  /// [homeBuilder] membangun layar untuk [homePath].
  static GoRouter build({
    required RouteRegistry registry,
    required String initialLocation,
    required WidgetBuilder homeBuilder,
  }) {
    final routes = [
      GoRoute(path: homePath, name: 'home', builder: (context, state) => homeBuilder(context)),
      ...registry.registeredNodes.map((node) => node.toGoRoute(_pathFor(node.keyId))),
    ];

    return GoRouter(
      initialLocation: initialLocation,
      debugLogDiagnostics: kDebugMode,
      routes: routes,
    );
  }

  static String _pathFor(String keyId) => '/${keyId.replaceAll('.', '/')}';
}
