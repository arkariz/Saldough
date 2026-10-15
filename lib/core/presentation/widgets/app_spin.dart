import 'package:flutter/material.dart';

/// Memutar [child] terus-menerus (ikon "sedang berjalan", design system
/// `tk-icon--spin`: satu putaran per detik). Diam bila pengguna meminta
/// mengurangi gerak (`MediaQuery.disableAnimations`).
class AppSpin extends StatefulWidget {
  /// Membuat [AppSpin].
  const AppSpin({required this.child, super.key});

  /// Yang diputar, biasanya `AppIcon(IconKey.progressActivity)`.
  final Widget child;

  @override
  State<AppSpin> createState() => _AppSpinState();
}

class _AppSpinState extends State<AppSpin> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller
        ..stop()
        ..value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RotationTransition(turns: _controller, child: widget.child);
}
