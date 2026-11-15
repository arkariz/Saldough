import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';

/// Balon Tanuki yang mengetik [message] per huruf (16 ms per huruf).
class TanukiBubble extends StatefulWidget {
  /// Membuat [TanukiBubble].
  const TanukiBubble({required this.message, super.key});

  /// Kalimat yang diketik.
  final String message;

  @override
  State<TanukiBubble> createState() => _TanukiBubbleState();
}

class _TanukiBubbleState extends State<TanukiBubble> {
  Timer? _timer;
  int _shown = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_timer == null && _shown == 0) _restart();
  }

  @override
  void didUpdateWidget(TanukiBubble old) {
    super.didUpdateWidget(old);
    if (old.message != widget.message) _restart();
  }

  void _restart() {
    _timer?.cancel();
    if (DsMotion.reduced(context)) {
      _shown = widget.message.length;
      return;
    }
    _shown = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted) return;
      setState(() => _shown = math.min(_shown + 1, widget.message.length));
      if (_shown >= widget.message.length) timer.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    return Semantics(
      liveRegion: true,
      label: widget.message,
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
        decoration: BoxDecoration(
          color: c.surfaceCard,
          border: Border.all(color: c.outlineSubtle),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.stamps.kaya.mascot.toUpperCase(),
              style: ds.typography.pixelCaption.copyWith(color: c.actionPrimary),
            ),
            const SizedBox(height: 2),
            // Satu `Text.rich`: huruf yang sudah diketik tampil, sisanya transparan,
            // sehingga tinggi balon tetap dan tidak melompat saat mengetik.
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: widget.message.substring(0, _shown.clamp(0, widget.message.length))),
                  TextSpan(
                    text: widget.message.substring(_shown.clamp(0, widget.message.length)),
                    style: const TextStyle(color: Colors.transparent),
                  ),
                ],
              ),
              style: ds.typography.bodyMd,
            ),
          ],
        ),
      ),
    );
  }
}
