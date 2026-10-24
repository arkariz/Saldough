import 'package:flutter/material.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';

/// Kartu pilihan paket di paywall (`tk-plan`, komponen PlanCard): seperti
/// radio, dengan nama paket, keterangan satu baris, dan harga dari toko di
/// kanan. Terpilih = `brandSoft` dengan garis `brand` 2px.
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
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final enabled = onTap != null;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      enabled: enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.6,
        child: AppChoiceBox(
          selected: selected,
          onTap: onTap ?? () {},
          padding: const EdgeInsets.all(AppSpacing.space4),
          constraints: const BoxConstraints(minHeight: 72),
          child: Row(
            children: [
              _Radio(selected: selected),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: textTheme.titleMedium),
                    if (tag != null) ...[
                      const SizedBox(height: AppSpacing.space1),
                      AppBadge(tag!, tone: AppTone.brand, icon: IconKey.plus),
                    ],
                    Text(
                      subtitle,
                      style: textTheme.bodyMedium?.copyWith(color: colors.ink2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              if (priceText == null)
                const AppSkeleton(width: 84, height: 20)
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (regularPriceText != null)
                      Text(
                        regularPriceText!,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.ink2,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    Text(priceText!, style: textTheme.titleMedium),
                    if (unit != null)
                      Text(
                        unit!,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.ink2,
                        ),
                      ),
                  ],
                ),
            ],
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
    final colors = context.appColors;
    return ExcludeSemantics(
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? colors.brand : Colors.transparent,
          border: Border.all(
            color: selected ? colors.brand : colors.lineStrong,
            width: 2,
          ),
        ),
        child: selected
            ? Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.onBrand,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
