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
            child: Row(
              children: [
                _Radio(selected: selected),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: ds.typography.titleMd),
                      if (tag != null) ...[const SizedBox(height: 4), DsBadge(label: tag!, tone: DsBadgeTone.income)],
                      Text(subtitle, style: ds.typography.bodySm.copyWith(color: c.textSecondary)),
                    ],
                  ),
                ),
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
                          if (regularPriceText != null)
                            Text(
                              regularPriceText!,
                              style: ds.typography.bodySm.copyWith(
                                color: c.textMuted,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          Text(priceText!, style: ds.typography.titleMd),
                          if (unit != null) Text(unit!, style: ds.typography.bodySm.copyWith(color: c.textSecondary)),
                        ],
                      ),
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
