import 'package:flutter/widgets.dart';
import 'package:saldough/core/presentation/spotlight/spotlight_host.dart';
import 'package:saldough/core/presentation/spotlight/spotlight_key.dart';

/// Menandai [child] sebagai target [spotlightKey] (ADR-021 §3.3).
///
/// Tanpa `SpotlightHost` di atasnya (mis. di uji), widget ini hanya
/// meneruskan [child].
class SpotlightTarget extends StatefulWidget {
  /// Membuat [SpotlightTarget].
  const SpotlightTarget({required this.spotlightKey, required this.child, super.key});

  /// Kunci target.
  final SpotlightKey spotlightKey;

  /// Widget yang disorot.
  final Widget child;

  @override
  State<SpotlightTarget> createState() => _SpotlightTargetState();
}

class _SpotlightTargetState extends State<SpotlightTarget> {
  final GlobalKey _key = GlobalKey();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    SpotlightHost.maybeOf(context, listen: false)?.register(widget.spotlightKey, _key);
  }

  @override
  void didUpdateWidget(SpotlightTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spotlightKey != widget.spotlightKey) {
      SpotlightHost.maybeOf(context, listen: false)
        ?..unregister(oldWidget.spotlightKey, _key)
        ..register(widget.spotlightKey, _key);
    }
  }

  @override
  void deactivate() {
    SpotlightHost.maybeOf(context, listen: false)?.unregister(widget.spotlightKey, _key);
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    SpotlightHost.maybeOf(context, listen: false)?.register(widget.spotlightKey, _key);
  }

  @override
  Widget build(BuildContext context) => KeyedSubtree(key: _key, child: widget.child);
}
