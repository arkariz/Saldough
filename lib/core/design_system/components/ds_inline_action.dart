import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/components/ds_pressable.dart';
import 'package:saldough/core/design_system/ds_theme.dart';
import 'package:saldough/core/design_system/tokens/ds_radius.dart';
import 'package:saldough/core/design_system/tokens/ds_spacing.dart';

/// Nada [DsInlineAction].
enum DsInlineActionTone {
  /// Isi `actionPrimary`: tindakan utama kartu (satu per baris aksi).
  primary,

  /// Permukaan cekung bergaris rambut: tindakan pendamping.
  tonal,
}

/// Aksi di dalam kartu atau baris daftar: tinggi tampak 36, huruf label 13
/// sama untuk semua nada, sudut 12, area sentuh 44. Dipakai lewat
/// [DsInlineActions] supaya lebar dan tinggi seragam.
class DsInlineAction extends StatelessWidget {
  /// Membuat [DsInlineAction].
  const DsInlineAction({
    required this.label,
    required this.onPressed,
    this.tone = DsInlineActionTone.tonal,
    this.icon,
    super.key,
  });

  /// Teks aksi; mengecil bila tidak muat, tidak pernah terpotong.
  final String label;

  /// Dipanggil saat ditekan; `null` menonaktifkan.
  final VoidCallback? onPressed;

  /// Nada.
  final DsInlineActionTone tone;

  /// Ikon opsional di depan [label] (16).
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final primary = tone == DsInlineActionTone.primary;
    final ink = primary ? c.onActionPrimary : c.textPrimary;
    return DsPressable(
      onPressed: onPressed,
      pressedScale: 0.97,
      builder: (context, pressed) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: DsSpacing.minTapTarget),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: primary
                  ? (pressed ? c.actionPrimaryPressed : c.actionPrimary)
                  : (pressed ? c.surfaceContainerHigh : c.surfaceSunken),
              borderRadius: DsRadius.mdAll,
              border: primary ? null : Border.all(color: c.outlineSubtle),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[Icon(icon, size: 16, color: ink), const SizedBox(width: 6)],
                  Text(
                    label,
                    maxLines: 1,
                    style: ds.typography.labelMd.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: ink),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Deretan [DsInlineAction] selebar sama dengan jarak 8; sejajar penuh dengan
/// isi kartu di atasnya.
class DsInlineActions extends StatelessWidget {
  /// Membuat [DsInlineActions].
  const DsInlineActions({required this.actions, super.key});

  /// Aksi, dari kiri ke kanan; yang utama terakhir.
  final List<DsInlineAction> actions;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final (i, action) in actions.indexed) ...[
        if (i > 0) const SizedBox(width: 8),
        Expanded(child: action),
      ],
    ],
  );
}
