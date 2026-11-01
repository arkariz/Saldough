import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saldough/core/design_system/components/ds_pressable.dart';
import 'package:saldough/core/design_system/ds_theme.dart';
import 'package:saldough/core/design_system/tokens/ds_motion.dart';
import 'package:saldough/core/design_system/tokens/ds_radius.dart';

/// Satu pilihan [DsSegmentedPill].
@immutable
class DsSegment<T> {
  /// Membuat pilihan.
  const DsSegment({required this.value, required this.label, this.icon, this.asset});

  /// Nilai pilihan.
  final T value;

  /// Teks.
  final String label;

  /// Ikon kecil di depan teks.
  final IconData? icon;

  /// Ikon clay (SVG) di depan teks; menggantikan [icon].
  final String? asset;
}

/// Pengalih segmen dengan pil hijau yang meluncur ke pilihan aktif (acuan
/// Catat): wadah putih bergaris rambut, segmen sama lebar. Pilihan aktif
/// berteks putih; yang lain abu. Diam (tanpa luncur) saat gerak dikurangi.
class DsSegmentedPill<T> extends StatelessWidget {
  /// Membuat pengalih.
  const DsSegmentedPill({required this.segments, required this.selected, required this.onChanged, super.key});

  /// Pilihan, dua atau lebih.
  final List<DsSegment<T>> segments;

  /// Nilai aktif.
  final T selected;

  /// Dipanggil dengan nilai baru.
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final index = segments.indexWhere((s) => s.value == selected);
    final reduced = DsMotion.reduced(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.surfaceCard,
        borderRadius: DsRadius.lgAll,
        border: Border.all(color: c.outlineSubtle),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth / segments.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: reduced ? Duration.zero : const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                left: width * (index < 0 ? 0 : index),
                top: 0,
                bottom: 0,
                width: width,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.actionPrimary,
                    borderRadius: DsRadius.mdAll,
                    boxShadow: [BoxShadow(color: c.actionPrimary.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                ),
              ),
              Row(
                children: [
                  for (final segment in segments)
                    Expanded(
                      child: _Segment(
                        segment: segment,
                        active: segment.value == selected,
                        onTap: () => onChanged(segment.value),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Segment<T> extends StatelessWidget {
  const _Segment({required this.segment, required this.active, required this.onTap});

  final DsSegment<T> segment;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final color = active ? c.onActionPrimary : c.textSecondary;
    return Semantics(
      selected: active,
      child: DsPressable(
        onPressed: onTap,
        pressedScale: 0.97,
        builder: (context, _) => ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 36),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (segment.asset != null) ...[
                    SvgPicture.asset(segment.asset!, width: 20, height: 20),
                    const SizedBox(width: 4),
                  ] else if (segment.icon != null) ...[
                    Icon(segment.icon, size: 15, color: color),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: Text(
                      segment.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ds.typography.labelMd.copyWith(color: color, fontSize: 12),
                    ),
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
