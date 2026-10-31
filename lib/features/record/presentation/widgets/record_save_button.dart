import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';

/// Tombol simpan Catat dengan animasi berhasil: saat diketuk, ikon daun
/// berganti centang yang membal, teksnya menjadi "Tersimpan", dan serpihan
/// daun menyebar dari tombol; sekitar setengah detik kemudian [onPressed]
/// dijalankan (menyimpan dan menutup lembar). Tanpa animasi saat gerak
/// dikurangi: [onPressed] langsung. Nonaktif selama [onPressed] `null`.
class RecordSaveButton extends StatefulWidget {
  /// Membuat [RecordSaveButton].
  const RecordSaveButton({required this.label, required this.onPressed, super.key});

  /// Teks tombol, menyebut jenisnya ("Simpan Pengeluaran").
  final String label;

  /// Dipanggil sesudah animasi; `null` menonaktifkan tombol.
  final VoidCallback? onPressed;

  /// Lama animasi sebelum menyimpan.
  static const Duration celebration = Duration(milliseconds: 520);

  @override
  State<RecordSaveButton> createState() => _RecordSaveButtonState();
}

class _RecordSaveButtonState extends State<RecordSaveButton> {
  bool _saved = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tap() {
    final action = widget.onPressed;
    if (action == null || _saved) return;
    if (DsMotion.reduced(context)) {
      action();
      return;
    }
    final box = context.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      DsCelebration.burst(context, origin: box.localToGlobal(box.size.center(Offset.zero)), count: 16);
    }
    setState(() => _saved = true);
    _timer = Timer(RecordSaveButton.celebration, action);
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final enabled = widget.onPressed != null;
    final reduced = DsMotion.reduced(context);
    final labelStyle = ds.typography.titleMd.copyWith(color: c.onActionPrimary, fontSize: 15);
    return Semantics(
      button: true,
      enabled: enabled,
      label: _saved ? t.record.savedLabel : widget.label,
      excludeSemantics: true,
      onTap: enabled ? _tap : null,
      child: Opacity(
        opacity: enabled ? 1 : DsOpacity.disabled,
        child: DsPressable(
          onPressed: enabled ? _tap : null,
          pressedScale: 0.97,
          dimWhenDisabled: false,
          builder: (context, _) => AnimatedContainer(
            duration: reduced ? Duration.zero : DsMotion.standard,
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _saved ? c.actionPrimaryPressed : c.actionPrimary,
              borderRadius: DsRadius.lgAll,
              boxShadow: [BoxShadow(color: c.actionPrimary.withValues(alpha: 0.28), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DsBounce(
                  trigger: _saved ? 1 : 0,
                  child: Icon(_saved ? Icons.check_circle : Icons.eco, size: 20, color: c.onActionPrimary),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _saved ? t.record.savedLabel : widget.label,
                    style: labelStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
