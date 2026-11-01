import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';

/// Kartu pilihan paket di paywall (komponen PlanCard): seperti radio, dengan
/// nama paket, keterangan satu baris, dan harga dari toko di kanan. Terpilih =
/// latar `actionPrimary` tipis dengan garis `actionPrimary` 2px.
///
/// Harga selalu string dari toko; widget ini tidak pernah menulis "Rp".
/// [priceText] `null` menampilkan kerangka (harga sedang dimuat).
class PlanCard extends StatelessWidget {
  /// Membuat [PlanCard].
  const PlanCard({
    required this.name,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.priceText,
    this.unit,
    this.regularPriceText,
    this.tag,
    super.key,
  });

  /// Nama paket ("Tahunan").
  final String name;

  /// Keterangan satu baris.
  final String subtitle;

  /// Harga dari toko; `null` = sedang dimuat.
  final String? priceText;

  /// Satuan ("/tahun").
  final String? unit;

  /// Harga biasa yang dicoret di samping [priceText].
  final String? regularPriceText;

  /// Lencana kecil ("Harga Pendiri").
  final String? tag;

  /// Paket sedang dipilih.
  final bool selected;

  /// Dipanggil saat diketuk; `null` = nonaktif (diproses atau menunggu).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final enabled = onTap != null;
    final reduced = DsMotion.reduced(context);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      enabled: enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.6,
        child: DsPressable(
          onPressed: onTap,
          pressedScale: 0.99,
          dimWhenDisabled: false,
          builder: (context, _) => AnimatedContainer(
            duration: reduced ? Duration.zero : DsMotion.standard,
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: selected ? c.actionPrimary.withValues(alpha: 0.06) : c.surfaceCard,
              borderRadius: DsRadius.lgAll,
              border: Border.all(color: selected ? c.actionPrimary : c.outlineSubtle, width: selected ? 2 : 1),
              boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 14, offset: Offset(0, 5))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (tag != null) ...[
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: _TagPill(label: tag!),
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    _Radio(selected: selected),
                    const SizedBox(width: 12),
                    Expanded(child: Text(name, style: ds.typography.titleMd.copyWith(fontSize: 16))),
                    const SizedBox(width: 12),
                    if (priceText == null)
                      const DsSkeleton(width: 84, height: 20)
                    else
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerEnd,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(priceText!, style: ds.typography.titleMd.copyWith(fontSize: 19)),
                                  if (unit != null) ...[
                                    const SizedBox(width: 2),
                                    Text(unit!, style: ds.typography.bodySm.copyWith(color: c.textSecondary)),
                                  ],
                                ],
                              ),
                              if (regularPriceText != null)
                                Text(
                                  regularPriceText!,
                                  style: ds.typography.bodySm.copyWith(
                                    color: c.textMuted,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 34),
                  child: Text(subtitle, style: ds.typography.bodySm.copyWith(color: c.textSecondary)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pita penawaran khusus ("Harga Pendiri"): pil `actionPrimary` pekat dengan
/// bintang, supaya terbaca sebagai sorotan, bukan keterangan.
class _TagPill extends StatelessWidget {
  const _TagPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    return DecoratedBox(
      decoration: BoxDecoration(color: c.actionPrimary, borderRadius: DsRadius.fullAll),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded, size: 14, color: c.onActionPrimary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: ds.typography.labelMd.copyWith(color: c.onActionPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.ds.colors;
    return ExcludeSemantics(
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? c.actionPrimary : Colors.transparent,
          border: Border.all(color: selected ? c.actionPrimary : c.outline, width: 2),
        ),
        child: selected
            ? Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: c.onActionPrimary),
                ),
              )
            : null,
      ),
    );
  }
}
