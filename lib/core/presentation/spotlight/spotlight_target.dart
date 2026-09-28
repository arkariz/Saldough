import 'package:flutter/widgets.dart';
import 'package:saldough/core/presentation/spotlight/spotlight_host.dart';
import 'package:saldough/core/tutorial/spotlight_key.dart';

/// Menandai [child] sebagai target [spotlightKey] (ADR-021 §3.3).
///
/// [spotlightKey] null berarti tidak ada yang ditandai — dipakai untuk pola
/// "hanya item pertama daftar yang disorot" tanpa mengubah susunan pohon
/// widget antar-item. Tanpa `SpotlightHost` di atasnya (mis. di uji),
/// widget ini hanya meneruskan [child].
class SpotlightTarget extends StatefulWidget {
  /// Membuat [SpotlightTarget].
  const SpotlightTarget({required this.spotlightKey, required this.child, super.key});

  /// Kunci target, atau null untuk tidak menandai apa pun.
  final SpotlightKey? spotlightKey;

  /// Widget yang disorot.
  final Widget child;

  @override
  State<SpotlightTarget> createState() => _SpotlightTargetState();
}

class _SpotlightTargetState extends State<SpotlightTarget> {
  final GlobalKey _key = GlobalKey();

  void _register(SpotlightKey? key) {
    if (key != null) SpotlightHost.maybeOf(context, listen: false)?.register(key, _key);
  }

  void _unregister(SpotlightKey? key) {
    if (key != null) SpotlightHost.maybeOf(context, listen: false)?.unregister(key, _key);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _register(widget.spotlightKey);
  }

  @override
  void didUpdateWidget(SpotlightTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spotlightKey != widget.spotlightKey) {
      _unregister(oldWidget.spotlightKey);
      _register(widget.spotlightKey);
    }
  }

  @override
  void deactivate() {
    _unregister(widget.spotlightKey);
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    _register(widget.spotlightKey);
  }

  @override
  Widget build(BuildContext context) => KeyedSubtree(key: _key, child: widget.child);
}
