import 'package:flutter/widgets.dart';

/// Menjalankan [action] sekali, saat widget ini pertama kali dipasang --
/// mis. memicu `*Started` bloc milik rute (ADR-030 §3.3) tanpa membuat
/// halamannya sendiri menjadi `StatefulWidget`.
class RunOnce extends StatefulWidget {
  /// Membuat [RunOnce].
  const RunOnce({required this.action, required this.child, super.key});

  /// Dijalankan sekali di `initState`.
  final VoidCallback action;

  /// Subtree yang dibungkus.
  final Widget child;

  @override
  State<RunOnce> createState() => _RunOnceState();
}

class _RunOnceState extends State<RunOnce> {
  @override
  void initState() {
    super.initState();
    widget.action();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
