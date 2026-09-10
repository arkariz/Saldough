import 'package:di/di.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/theme/theme.dart';

/// Widget akar Saldough.
///
/// Membungkus `MaterialApp.router` dengan [ScopeProvider] yang mengekspos
/// kontainer akar — setiap modul rute fitur mengambil kontainer induknya
/// lewat `ScopeProvider.of(context)` sebelum memasang `ScopeWidget`-nya
/// sendiri (lihat ARCHITECTURE_OVERVIEW.md bagian "Navigasi").
///
/// Juga memasang tombol menu pengembang (hanya di build debug, T-1.10) lewat
/// `builder:` `MaterialApp.router`, sehingga muncul di atas layar apa pun.
class SaldoughApp extends StatelessWidget {
  /// Membuat [SaldoughApp] dengan [getIt] (kontainer akar) dan [router].
  const SaldoughApp({required this.getIt, required this.router, super.key});

  /// Kontainer DI akar.
  final GetIt getIt;

  /// Router aplikasi, dibangun dari [RouteRegistry] lewat [AppRouteRegistry].
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return ScopeProvider(
      container: getIt,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        routerConfig: router,
        builder: (context, child) => _WithDebugMenu(router: router, registry: getIt<RouteRegistry>(), child: child),
      ),
    );
  }
}

class _WithDebugMenu extends StatelessWidget {
  const _WithDebugMenu({required this.router, required this.registry, required this.child});

  final GoRouter router;
  final RouteRegistry registry;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return child ?? const SizedBox.shrink();

    return Stack(
      children: [
        ?child,
        Positioned(
          right: 12,
          bottom: 12,
          child: FloatingActionButton.small(
            heroTag: 'debug-menu',
            tooltip: 'Menu pengembang',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => DevMenuScreen(
                  registry: registry,
                  onEntryTap: (entry) {
                    Navigator.of(context).pop();
                    router.goNamed(entry.keyId, extra: entry.createInput());
                  },
                ),
              ),
            ),
            child: const Icon(Icons.bug_report),
          ),
        ),
      ],
    );
  }
}
