import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:navigation/navigation.dart';

/// Mengubah [RouteNode] (framework-agnostic dari `package:navigation`) jadi
/// [GoRoute] yang sungguhan dipahami `go_router`.
///
/// `package:navigation` sengaja tidak mengimpor `go_router` — adapter ini
/// adalah satu-satunya tempat kedua dunia itu bertemu, sesuai ADR-0004.
extension RouteNodeGoRouterExt on RouteNode {
  /// Membangun [GoRoute] untuk path [path] dari node ini.
  ///
  /// [RouteInput] diambil dari `state.extra` (navigasi internal lewat efek
  /// bloc) atau, kalau tidak ada (misalnya route dibuka dari deep link),
  /// jatuh ke [RouteNode.defaultInput]. Kalau keduanya tidak ada, melempar
  /// [StateError] yang jelas — sesuai dokumentasi [RouteNode.defaultInput].
  GoRoute toGoRoute(String path) {
    return GoRoute(
      path: path,
      name: keyId,
      pageBuilder: (context, state) {
        final input = state.extra as RouteInput? ?? defaultInput;
        if (input == null) {
          throw StateError(
            'Rute "$keyId" dibuka tanpa RouteInput (tidak ada `extra` dan '
            'tidak ada defaultInput terdaftar). Sertakan input lewat efek '
            'navigasi, atau daftarkan defaultInput kalau rute ini harus bisa '
            'dibuka lewat deep link.',
          );
        }
        final child = buildWidget(context, input);
        return _pageFor(transition, state, child);
      },
    );
  }

  Page<void> _pageFor(RouteTransition transition, GoRouterState state, Widget child) {
    switch (transition) {
      case RouteTransition.material:
        // Transisi platform-adaptif bawaan — `MaterialPage` memakai
        // `pageTransitionsTheme` dari `ThemeData` secara otomatis, tidak
        // perlu transitionsBuilder kustom.
        return MaterialPage<void>(key: state.pageKey, child: child);
      case RouteTransition.fadeIn:
        return CustomTransitionPage<void>(
          key: state.pageKey,
          child: child,
          transitionsBuilder: (_, animation, _, c) => FadeTransition(opacity: animation, child: c),
        );
      case RouteTransition.slideFromRight:
        return CustomTransitionPage<void>(
          key: state.pageKey,
          child: child,
          transitionsBuilder: (_, animation, _, c) => SlideTransition(
            position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(animation),
            child: c,
          ),
        );
      case RouteTransition.slideFromBottom:
        return CustomTransitionPage<void>(
          key: state.pageKey,
          child: child,
          transitionsBuilder: (_, animation, _, c) => SlideTransition(
            position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(animation),
            child: c,
          ),
        );
      case RouteTransition.none:
        return CustomTransitionPage<void>(
          key: state.pageKey,
          child: child,
          transitionsBuilder: (_, _, _, c) => c,
        );
    }
  }
}
