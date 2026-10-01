import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/presentation/widgets/full_screen_sheet.dart';

/// Membuka rute fitur lewat kuncinya (ADR-030 §3.3): satu-satunya cara fitur
/// membuka layar fitur lain, karena fitur lain hanya boleh mengimpor
/// `<fitur>_route_keys.dart`.
///
/// Pasangan kunci–input dicek saat kompilasi (`RouteKey<TInput>`). Rute
/// dibangun dari [RouteNode] yang sama dengan yang didaftarkan ke
/// `go_router` (`RouteNodeGoRouterExt`), lalu didorong ke Navigator akar
/// seperti `Navigator.push` biasa, jadi `Future`-nya selesai dengan hasil
/// `pop` rute itu.
extension RouteNavigation on BuildContext {
  /// Membuka rute [key] dengan [input] dan menunggu hasilnya.
  Future<T?> pushRoute<TInput extends RouteInput, T extends Object?>(RouteKey<TInput> key, TInput input) {
    final navigator = Navigator.of(this, rootNavigator: true);
    // Registri ada di kontainer akar; `ScopeProvider` terdekat dari `this`
    // bisa saja kontainer scope fitur yang tidak membawanya.
    final node = ScopeProvider.of(navigator.context)<RouteRegistry>().resolve(key);
    if (node == null) throw StateError('Rute "${key.id}" belum didaftarkan di RouteRegistry.');
    return navigator.push<T>(
      node.toRoute<T>(input, capturedThemes: InheritedTheme.capture(from: this, to: navigator.context)),
    );
  }
}

/// Mengubah [RouteNode] menjadi `Route` Flutter untuk [RouteNavigation].
extension RouteNodeRouteExt on RouteNode {
  /// Membangun rute untuk [input]. [capturedThemes] (tema pemanggil) hanya
  /// dipakai lembar, sama seperti `showModalBottomSheet`: wadah lembar
  /// dibangun di luar [RouteNode.buildWidget], jadi tanpanya penimpaan tema
  /// lokal di pemanggil tidak terbawa. Tema aplikasinya sendiri global
  /// (ADR-031 §3.5).
  Route<T> toRoute<T>(RouteInput input, {required CapturedThemes capturedThemes}) {
    final settings = RouteSettings(name: keyId, arguments: input);
    Widget page(BuildContext context) => buildWidget(context, input);
    return switch (transition) {
      RouteTransition.material => MaterialPageRoute<T>(settings: settings, builder: page),
      // Di Saldough, `slideFromBottom` berarti lembar modal setinggi layar
      // (ADR-030 §3.3 butir 4), bukan halaman yang meluncur dari bawah.
      RouteTransition.slideFromBottom => ModalBottomSheetRoute<T>(
        settings: settings,
        builder: page,
        capturedThemes: capturedThemes,
        isScrollControlled: true,
        useSafeArea: true,
        shape: fullScreenSheetShape,
      ),
      RouteTransition.fadeIn => PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, _, _) => page(context),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
      ),
      RouteTransition.slideFromRight => PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, _, _) => page(context),
        transitionsBuilder: (_, animation, _, child) => SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(animation),
          child: child,
        ),
      ),
      // Di Saldough, `none` berarti rute alur transparan: tak terlihat, layar
      // pemanggil tetap tampil, dan alurnya membuka lembar/dialognya sendiri
      // (ADR-030 §3.3, mis. CATAT).
      RouteTransition.none => PageRouteBuilder<T>(
        settings: settings,
        opaque: false,
        pageBuilder: (context, _, _) => page(context),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    };
  }
}
