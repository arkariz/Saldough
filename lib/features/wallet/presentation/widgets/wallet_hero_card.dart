import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/wallet/presentation/wallet_shares.dart';
import 'package:saldough/features/wallet/presentation/widgets/asset_layer.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:saldough/shared/wealth/wealth.dart';

/// Kartu hero tab Dompet: **Total aset** (ADR-050 Revisi 2). Tanpa ubin per
/// lapis; sebaran antarlapis (batang proporsi dan persen) ada di kaki hero,
/// dan mengetuk satu lapis memilih segmennya di bawah.
class WalletHeroCard extends StatelessWidget {
  /// Membuat [WalletHeroCard].
  const WalletHeroCard({required this.layers, required this.selected, required this.onLayerSelected, super.key});

  /// Total aset per lapis.
  final WealthLayers layers;

  /// Segmen yang sedang dipilih (ditandai di legenda).
  final AssetLayer selected;

  /// Dipanggil saat satu lapis di legenda diketuk.
  final ValueChanged<AssetLayer> onLayerSelected;

  @override
  Widget build(BuildContext context) {
    final symbol = ActiveCurrency.value.symbol;
    final total = layers.total;
    final shown = shownLayers(layers);
    return DsCountUp(
      value: total,
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, shown_) => DsHeroBalanceCard(
        label: t.assets.totalAssets.toUpperCase(),
        currencySymbol: symbol,
        semanticAmount: AppMoneyFormatter.formatRevealed(total),
        mascot: SvgPicture.asset(ClayIcons.mascot),
        coin: SvgPicture.asset(ClayIcons.tierCoin, width: 24, height: 24),
        amount: AppMoneyFormatter.formatRevealed(shown_).replaceFirst(symbol, ''),
        hidden: AmountVisibility.hidden,
        toggleLabel: AmountVisibility.hidden ? t.home.showAmounts : t.home.hideAmounts,
        onToggleHidden: AmountVisibility.toggle,
        caption: shown.length > 1 ? null : t.wallet.activeBadge(count: layers.operationalCount),
        footer: shown.length > 1
            ? _LayerSpread(layers: layers, shown: shown, selected: selected, onSelected: onLayerSelected)
            : null,
      ),
    );
  }
}

/// Sebaran antarlapis di kaki hero: batang proporsi dan legenda persen yang
/// bisa diketuk.
class _LayerSpread extends StatelessWidget {
  const _LayerSpread({required this.layers, required this.shown, required this.selected, required this.onSelected});

  final WealthLayers layers;
  final List<AssetLayer> shown;
  final AssetLayer selected;
  final ValueChanged<AssetLayer> onSelected;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final colors = heroLayerColors(ds.colors);
    // Persen dihitung sama dengan kartu sebaran (bulat setengah ke atas).
    final shares = walletShares([
      for (final layer in shown)
        Wallet(id: layer.name, name: '', iconKey: '', initialBalance: 0, currentBalance: layerAmount(layers, layer)),
    ]);
    final positive = [for (final layer in shown) (layer, layerAmount(layers, layer))].where((e) => e.$2 > 0).toList();
    final sum = positive.fold(0, (a, e) => a + e.$2);
    return Column(
      key: const ValueKey('hero-layer-spread'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (sum > 0)
          ExcludeSemantics(
            child: ClipRRect(
              borderRadius: DsRadius.fullAll,
              child: SizedBox(
                height: 8,
                child: Row(
                  // Tanpa stretch, ColoredBox tanpa anak setinggi 0.
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 2,
                  children: [
                    for (final (layer, amount) in positive)
                      Expanded(
                        flex: (amount * 1000 ~/ sum).clamp(1, 1000),
                        child: ColoredBox(color: colors[layer]!),
                      ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 10),
        // Satu baris per lapis: label dan persen di kiri, nominal di kanan
        // (nominal panjang tetap terbaca; tiga kolom sempit memotongnya).
        Column(
          children: [
            for (final layer in shown)
              _LayerLegend(
                  key: ValueKey('hero-layer-${layer.name}'),
                  label: layerLabel(layer),
                  percent: shares[layer.name]?.text ?? '0%',
                  amount: AppMoneyText.format(layerAmount(layers, layer), MoneyKind.balance),
                  color: colors[layer]!,
                  selected: layer == selected,
                  onTap: () => onSelected(layer),
              ),
          ],
        ),
      ],
    );
  }
}

class _LayerLegend extends StatelessWidget {
  const _LayerLegend({
    required this.label,
    required this.percent,
    required this.amount,
    required this.color,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final String percent;
  final String amount;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label $percent, $amount',
      excludeSemantics: true,
      child: DsPressable(
        onPressed: onTap,
        builder: (context, _) => AnimatedContainer(
          duration: DsMotion.reduced(context) ? Duration.zero : DsMotion.standard,
          constraints: const BoxConstraints(minHeight: 44),
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: selected ? 0.32 : 0.18),
            borderRadius: DsRadius.mdAll,
            border: Border.all(color: selected ? color.withValues(alpha: 0.9) : Colors.transparent),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(label, style: ds.typography.labelMd.copyWith(color: Colors.white)),
              const SizedBox(width: 6),
              Text(percent, style: ds.typography.labelMd.copyWith(color: Colors.white.withValues(alpha: 0.7))),
              const SizedBox(width: 12),
              // Nominal panjang mengecil sedikit, tidak dipotong.
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(amount, maxLines: 1, style: ds.typography.labelMd.copyWith(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
