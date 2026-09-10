import 'package:flutter/foundation.dart';
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

  /// Membangun [GoRouter] dari [registry], dimulai dari [initialLocation].
  static GoRouter build({
    required RouteRegistry registry,
    required String initialLocation,
  }) {
    final routes = registry.registeredNodes
        .map((node) => node.toGoRoute(_pathFor(node.keyId)))
        .toList(growable: false);

    return GoRouter(
      initialLocation: initialLocation,
      debugLogDiagnostics: kDebugMode,
      routes: routes,
    );
  }

  static String _pathFor(String keyId) => '/${keyId.replaceAll('.', '/')}';
}
