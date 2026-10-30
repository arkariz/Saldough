import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/ds_theme.dart';
import 'package:saldough/core/design_system/tokens/ds_radius.dart';

/// Nada [DsBadge] (`components.md` bagian Badge dan tag).
enum DsBadgeTone {
  /// Sage pemasukan: "Penghasilan", "84% SEHAT".
  income,

  /// Sampanye hangat: kategori hidup sehari-hari.
  warm,

  /// Kabut bergaris rambut: status netral ("74% TERPAKAI").
  neutral,

  /// Kabut tanpa garis: tag kategori di baris transaksi.
  category,

  /// Kuning perhatian: "Hampir habis", "3 hari lagi".
  warning,

  /// Merah: lewat batas.
  danger,
}

/// Badge dan tag: sudut 6px, huruf piksel (KT-DS4). Tulis [label] kapital
/// di pemanggil bila badge status.
class DsBadge extends StatelessWidget {
  /// Membuat badge.
  const DsBadge({required this.label, this.tone = DsBadgeTone.category, super.key});

  /// Teks badge.
  final String label;

  /// Nada warna.
  final DsBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final (Color fill, Color ink, Color? border) = switch (tone) {
      DsBadgeTone.income => (c.incomeContainer, c.onIncomeContainer, null),
      DsBadgeTone.warm => (c.toneWarmContainer, c.onToneWarmContainer, null),
      DsBadgeTone.neutral => (c.surfaceSunken, c.textSecondary, c.outlineSubtle),
      DsBadgeTone.category => (c.surfaceSunken, c.textSecondary, null),
      DsBadgeTone.warning => (c.warningContainer, c.onWarningContainer, null),
      DsBadgeTone.danger => (c.errorContainer, c.onErrorContainer, null),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: DsRadius.badgeAll,
        border: border == null ? null : Border.all(color: border),
      ),
      child: Text(
        label,
        style: ds.typography.pixelCaption.copyWith(color: ink),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Pil status: titik berdenyut + label piksel ("LVL 12 STEWARD").
class DsStatusPill extends StatefulWidget {
  /// Membuat pil status.
  const DsStatusPill({required this.label, this.pulse = true, super.key});

  /// Teks pil.
  final String label;

  /// Titik berdenyut. Mati otomatis bila animasi dikurangi.
  final bool pulse;

  @override
  State<DsStatusPill> createState() => _DsStatusPillState();
}

class _DsStatusPillState extends State<DsStatusPill> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animate = widget.pulse && !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    if (animate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!animate) {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.surfaceContainer,
        borderRadius: DsRadius.fullAll,
        border: Border.all(color: c.outlineSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: Tween<double>(begin: 1, end: 0.4).animate(_controller),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: c.income, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              widget.label,
              style: ds.typography.pixelLabel.copyWith(color: c.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
