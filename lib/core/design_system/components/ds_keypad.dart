import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saldough/core/design_system/ds_theme.dart';
import 'package:saldough/core/design_system/tokens/ds_motion.dart';
import 'package:saldough/core/design_system/tokens/ds_radius.dart';

/// Satu tombol [DsKeypad]. [value] dikirim ke `onKey`; [label] teks tampil
/// (atau [icon]); [semanticLabel] bila teksnya tidak cukup bagi pembaca
/// layar (operator, hapus).
@immutable
class DsKeypadKey {
  /// Membuat tombol.
  const DsKeypadKey({required this.value, this.label, this.icon, this.semanticLabel, this.muted = false});

  /// Nilai yang dikirim saat ditekan; juga membentuk kunci `keypad-<value>`.
  final String value;

  /// Teks tombol; bawaan [value].
  final String? label;

  /// Ikon pengganti teks (mis. hapus).
  final IconData? icon;

  /// Label pembaca layar; bawaan [label].
  final String? semanticLabel;

  /// Gaya tombol sekunder (latar putih, teks lebih redup): operator, "000".
  final bool muted;
}

/// Papan angka v2: tombol bersudut 8 berlatar `surfaceContainerLow` dengan
/// garis rambut, angka tabular, getar ringan, dan mengecil .91 saat ditekan
/// (acuan Catat). Susunannya diberikan pemanggil ([rows]); tekan lama tombol
/// bernilai [clearValue] memanggil `onClear`. Tombol tampak setinggi
/// [keyHeight] tetapi area sentuhnya 44 (jarak antarbaris ikut terhitung).
class DsKeypad extends StatelessWidget {
  /// Membuat papan angka.
  const DsKeypad({
    required this.rows,
    required this.onKey,
    required this.onClear,
    this.clearValue,
    this.keyHeight = 40,
    super.key,
  });

  /// Baris tombol, dari atas ke bawah; tiap baris sama banyak.
  final List<List<DsKeypadKey>> rows;

  /// Dipanggil dengan nilai tombol yang ditekan.
  final ValueChanged<String> onKey;

  /// Tekan lama tombol [clearValue].
  final VoidCallback onClear;

  /// Nilai tombol yang menghapus semuanya saat ditekan lama.
  final String? clearValue;

  /// Tinggi tampak tombol.
  final double keyHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in rows)
          Row(
            children: [
              for (final (j, key) in row.indexed) ...[
                if (j > 0) const SizedBox(width: 6),
                Expanded(
                  child: _Key(
                    data: key,
                    height: keyHeight,
                    onKey: onKey,
                    onLongPress: key.value == clearValue ? onClear : null,
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }
}

class _Key extends StatefulWidget {
  const _Key({required this.data, required this.height, required this.onKey, required this.onLongPress});

  final DsKeypadKey data;
  final double height;
  final ValueChanged<String> onKey;
  final VoidCallback? onLongPress;

  @override
  State<_Key> createState() => _KeyState();
}

class _KeyState extends State<_Key> with SingleTickerProviderStateMixin {
  bool _pressed = false;

  /// Membal sekali tiap ketukan, selesai walau jari diangkat cepat.
  late final AnimationController _bounce = AnimationController(vsync: this, duration: const Duration(milliseconds: 340));
  static final Animatable<double> _bounceScale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween<double>(begin: 1, end: 0.88).chain(CurveTween(curve: Curves.easeOut)), weight: 22),
    TweenSequenceItem(tween: Tween<double>(begin: 0.88, end: 1.08).chain(CurveTween(curve: Curves.easeOut)), weight: 38),
    TweenSequenceItem(tween: Tween<double>(begin: 1.08, end: 1).chain(CurveTween(curve: Curves.easeInOut)), weight: 40),
  ]);

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final key = widget.data;
    void tap() {
      unawaited(HapticFeedback.selectionClick());
      if (!DsMotion.reduced(context)) _bounce.forward(from: 0);
      widget.onKey(key.value);
    }

    final gap = ((44 - widget.height) / 2).clamp(0.0, double.infinity);
    final label = key.label ?? key.value;
    final reduced = DsMotion.reduced(context);
    return Semantics(
      button: true,
      label: key.semanticLabel ?? label,
      // `excludeSemantics` membuang aksi ketuk `GestureDetector`; dipasang di sini.
      onTap: tap,
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('keypad-${key.value}'),
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: tap,
        onLongPress: widget.onLongPress == null
            ? null
            : () {
                unawaited(HapticFeedback.mediumImpact());
                widget.onLongPress!();
              },
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: gap),
          child: ScaleTransition(
            scale: _bounce.drive(_bounceScale),
            child: AnimatedContainer(
              duration: reduced ? Duration.zero : DsMotion.standard,
              height: widget.height,
              decoration: BoxDecoration(
                color: _pressed
                    ? c.primaryFixed.withValues(alpha: 0.5)
                    : (key.muted ? c.surfaceCard : c.surfaceSunken),
                borderRadius: DsRadius.mdAll,
                border: Border.all(color: c.outlineSubtle),
              ),
              child: Center(
                child: key.icon != null
                    ? Icon(key.icon, size: 20, color: c.textSecondary)
                    : Text(
                        label,
                        style: ds.typography.amountSm.copyWith(
                          fontSize: key.muted ? 14 : 17,
                          fontWeight: FontWeight.w600,
                          fontVariations: const [FontVariation.weight(600)],
                          color: key.muted ? c.textSecondary : c.textPrimary,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
