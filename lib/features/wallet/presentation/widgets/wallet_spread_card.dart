import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/wallet/presentation/wallet_shares.dart';
import 'package:saldough/features/wallet/presentation/widgets/wallet_card.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Kartu Sebaran saldo di tab Dompet (komponen BalanceSpread,
/// `docs/03-design/design-system/components/BalanceSpread/README.md`).
///
/// Ringkas secara bawaan (bar proporsi + kunci warna); mengetuk kepala
/// membukanya menjadi [AppDonutChart] dengan legenda dua kolom. Memilih
/// dompet lewat irisan atau legenda memberi tahu pemanggil lewat
/// [onSelected] supaya baris dompetnya di daftar ditandai. Keadaan terbuka
/// dan pilihan tidak disimpan: meninggalkan layar mengembalikannya ke
/// ringkas.
///
/// Pemanggil hanya memasangnya bila ada dua dompet aktif atau lebih.
class WalletSpreadCard extends StatefulWidget {
  /// Membuat [WalletSpreadCard].
  const WalletSpreadCard({
    required this.wallets,
    required this.shares,
    required this.colors,
    required this.total,
    required this.activeCount,
    required this.onSelected,
    super.key,
  });

  /// Dompet aktif, urutan tampil. Hanya yang punya [shares] menjadi irisan.
  final List<Wallet> wallets;

  /// Bagian saldo per `id` dompet dari [walletShares].
  final Map<String, WalletShare> shares;

  /// Warna per `id` dompet dari [walletColors].
  final Map<String, Color> colors;

  /// Total saldo dompet aktif, untuk tengah donat.
  final int total;

  /// Jumlah dompet aktif ("4 dompet aktif" di tengah donat).
  final int activeCount;

  /// Dipanggil dengan `id` dompet terpilih, atau `null` saat pilihan kosong.
  final ValueChanged<String?> onSelected;

  @override
  State<WalletSpreadCard> createState() => _WalletSpreadCardState();
}

class _WalletSpreadCardState extends State<WalletSpreadCard> {
  bool _open = false;
  String? _selected;

  List<Wallet> get _shown => [
    for (final w in widget.wallets)
      if (widget.shares.containsKey(w.id)) w,
  ];

  void _setSelected(String? id) {
    setState(() => _selected = id);
    widget.onSelected(id);
  }

  void _toggle() {
    setState(() => _open = !_open);
    if (_selected != null) _setSelected(null);
  }

  void _pick(String id) {
    if (!_open) setState(() => _open = true);
    _setSelected(_selected == id ? null : id);
  }

  String _semantics(List<Wallet> shown) => t.wallet.spreadSemantics(
    list: shown.map((w) => '${w.name} ${widget.shares[w.id]!.text}').join(', '),
  );

  @override
  Widget build(BuildContext context) {
    final shown = _shown;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final c = context.ds.colors;
    return Container(
      key: const ValueKey('wallet-spread'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.surfaceCard,
        borderRadius: DsRadius.xlAll,
        border: Border.all(color: c.outlineSubtle),
        boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 14, offset: Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Head(open: _open, reduceMotion: reduceMotion, count: shown.length, onTap: _toggle),
          if (!_open) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
              child: Semantics(
                label: _semantics(shown),
                image: true,
                child: WalletSpreadBar(wallets: shown, colors: widget.colors),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space4,
                AppSpacing.space2,
                AppSpacing.space4,
                AppSpacing.space4,
              ),
              child: ExcludeSemantics(
                child: _Keys(wallets: shown, shares: widget.shares, colors: widget.colors),
              ),
            ),
          ] else
            _FadeIn(
              enabled: !reduceMotion,
              child: _body(context, shown),
            ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, List<Wallet> shown) {
    final colors = context.ds.colors;
    final selectedIndex = shown.indexWhere((w) => w.id == _selected);
    final selected = selectedIndex < 0 ? null : shown[selectedIndex];
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.outlineSubtle)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.space1, bottom: AppSpacing.space2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.space3),
            Center(
              child: AppDonutChart(
                slices: [
                  for (final w in shown) DonutSlice(value: w.currentBalance, color: widget.colors[w.id]!),
                ],
                selected: selected == null ? null : selectedIndex,
                onSelect: (index) => _pick(shown[index].id),
                semanticsLabel: _semantics(shown),
                center: _Center(
                  label: selected?.name ?? t.home.balanceLabel,
                  sen: selected?.currentBalance ?? widget.total,
                  caption: selected == null
                      ? t.wallet.activeBadge(count: widget.activeCount)
                      : t.wallet.spreadOfTotal(percent: widget.shares[selected.id]!.text),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
              child: _Legend(
                wallets: shown,
                shares: widget.shares,
                colors: widget.colors,
                selected: _selected,
                onPick: _pick,
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space1),
              child: Row(
                children: [
                  if (selected != null)
                    DsButton.ghost(label: t.wallet.spreadSeeTotal, onPressed: () => _setSelected(null)),
                  const Spacer(),
                  DsButton.ghost(
                    key: const ValueKey('wallet-spread-hide'),
                    label: t.wallet.spreadHide,
                    icon: Icons.expand_less,
                    onPressed: _toggle,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kepala kartu: tombol penuh lebar dengan tile grafik clay, judul dan lencana
/// jumlah alokasi, subjudul buka/tutup, dan chevron yang berputar 180° saat
/// terbuka.
class _Head extends StatelessWidget {
  const _Head({required this.open, required this.reduceMotion, required this.count, required this.onTap});

  final bool open;
  final bool reduceMotion;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final sub = open ? t.wallet.spreadTapClose : t.wallet.spreadTapOpen;
    return Semantics(
      button: true,
      expanded: open,
      label: '${t.wallet.spreadTitle}. $sub',
      excludeSemantics: true,
      child: DsPressable(
        key: const ValueKey('wallet-spread-head'),
        onPressed: onTap,
        pressedScale: 0.99,
        dimWhenDisabled: false,
        builder: (context, _) => ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: Row(
              children: [
                DsIconTile.asset(asset: ClayIcons.chart, tone: DsIconTileTone.income),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(t.wallet.spreadTitle, style: ds.typography.titleMd),
                          DsBadge(label: '$count', tone: DsBadgeTone.neutral),
                        ],
                      ),
                      Text(sub, style: ds.typography.bodySm.copyWith(color: c.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedRotation(
                  turns: open ? 0.5 : 0,
                  duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: Icon(Icons.expand_more, color: c.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Kunci warna versi ringkas: "■ BCA 54%" yang boleh membungkus.
class _Keys extends StatelessWidget {
  const _Keys({required this.wallets, required this.shares, required this.colors});

  final List<Wallet> wallets;
  final Map<String, WalletShare> shares;
  final Map<String, Color> colors;

  @override
  Widget build(BuildContext context) {
    final style = context.ds.typography.labelMd.copyWith(color: context.ds.colors.textSecondary);
    return Wrap(
      spacing: AppSpacing.space3,
      runSpacing: AppSpacing.space1,
      children: [
        for (final w in wallets)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              WalletSwatch(colors[w.id]!),
              const SizedBox(width: 6),
              Text('${w.name} ${shares[w.id]!.text}', style: style),
            ],
          ),
      ],
    );
  }
}

/// Legenda donat dua kolom (`tk-legchip`): penanda, nama, persen.
class _Legend extends StatelessWidget {
  const _Legend({
    required this.wallets,
    required this.shares,
    required this.colors,
    required this.selected,
    required this.onPick,
  });

  final List<Wallet> wallets;
  final Map<String, WalletShare> shares;
  final Map<String, Color> colors;
  final String? selected;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < wallets.length; i += 2) {
      if (i > 0) rows.add(const SizedBox(height: AppSpacing.space2));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _chip(wallets[i])),
              const SizedBox(width: AppSpacing.space2),
              Expanded(child: i + 1 < wallets.length ? _chip(wallets[i + 1]) : const SizedBox.shrink()),
            ],
          ),
        ),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }

  Widget _chip(Wallet w) => _LegendChip(
    key: ValueKey('wallet-legend-${w.id}'),
    wallet: w,
    share: shares[w.id]!,
    color: colors[w.id]!,
    selected: selected == w.id,
    onTap: () => onPick(w.id),
  );
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.wallet,
    required this.share,
    required this.color,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final Wallet wallet;
  final WalletShare share;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final weight = selected ? FontWeight.w700 : FontWeight.w500;
    return Semantics(
      button: true,
      selected: selected,
      label: '${wallet.name}, ${share.text}',
      excludeSemantics: true,
      child: DsPressable(
        onPressed: onTap,
        pressedScale: 0.97,
        dimWhenDisabled: false,
        builder: (context, _) => AnimatedContainer(
          duration: DsMotion.reduced(context) ? Duration.zero : DsMotion.standard,
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? c.actionPrimary.withValues(alpha: 0.08) : Colors.transparent,
            borderRadius: DsRadius.mdAll,
            border: Border.all(color: selected ? c.actionPrimary : c.outlineSubtle),
          ),
          child: Row(
            children: [
              WalletSwatch(color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  wallet.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ds.typography.bodyMd.copyWith(fontWeight: weight, fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                share.text,
                style: ds.typography.bodyMd.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 13,
                  color: selected ? c.textPrimary : c.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Isi lubang donat: label, nominal (ikut sembunyikan nominal), keterangan.
class _Center extends StatelessWidget {
  const _Center({required this.label, required this.sen, required this.caption});

  final String label;
  final int sen;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final small = ds.typography.bodySm.copyWith(color: ds.colors.textSecondary);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: small),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: AppMoneyText(sen, size: MoneySize.large),
        ),
        Text(caption, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: small),
      ],
    );
  }
}

/// Pudar masuk 200ms saat diagram dibuka; langsung bila [enabled] `false`
/// (kurangi gerakan).
class _FadeIn extends StatelessWidget {
  const _FadeIn({required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(opacity: value, child: child),
      child: child,
    );
  }
}
