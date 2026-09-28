import 'package:flutter/widgets.dart';
import 'package:saldough/core/presentation/spotlight/spotlight_controller.dart';
import 'package:saldough/core/presentation/spotlight/spotlight_overlay.dart';
import 'package:saldough/core/tutorial/tutorial.dart';

/// Pemegang [SpotlightController] dan lapisan tur (ADR-021 §3.3).
///
/// Dipasang di `MaterialApp.builder`, di atas `Navigator`, sehingga lapisan
/// tur juga menutupi lembar modal. Tombol kembali selama tur ditangani rute
/// penahan milik `SpotlightController.maybeStart`: ia menutup tur (dan
/// menandai langkahnya dilihat), bukan layar di bawahnya.
class SpotlightHost extends StatefulWidget {
  /// Membuat [SpotlightHost] di atas [repository].
  const SpotlightHost({required this.repository, required this.child, super.key});

  /// Penyimpanan progres tutorial.
  final TutorialProgressRepository repository;

  /// Isi aplikasi.
  final Widget child;

  /// Controller host terdekat, atau null kalau tidak ada host (mis. di uji
  /// lama). [listen] true membangun ulang pemanggil saat tur berubah.
  static SpotlightController? maybeOf(BuildContext context, {bool listen = true}) {
    if (listen) return context.dependOnInheritedWidgetOfExactType<_SpotlightScope>()?.notifier;
    return context.getInheritedWidgetOfExactType<_SpotlightScope>()?.notifier;
  }

  @override
  State<SpotlightHost> createState() => _SpotlightHostState();
}

class _SpotlightHostState extends State<SpotlightHost> {
  late final SpotlightController _controller = SpotlightController(repository: widget.repository);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SpotlightScope(
      notifier: _controller,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          widget.child,
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => _controller.isActive
                ? Positioned.fill(child: SpotlightOverlay(controller: _controller))
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _SpotlightScope extends InheritedNotifier<SpotlightController> {
  const _SpotlightScope({required super.notifier, required super.child});
}
