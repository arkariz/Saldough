import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/investment/presentation/navigation/investment_route_keys.dart';
import 'package:saldough/features/premium/presentation/navigation/premium_route_keys.dart';
import 'package:saldough/features/record/presentation/navigation/record_route_keys.dart';
import 'package:saldough/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:saldough/features/wallet/presentation/bloc/wallet_state.dart';
import 'package:saldough/features/wallet/presentation/wallet_shares.dart';
import 'package:saldough/features/wallet/presentation/widgets/wallet_card.dart';
import 'package:saldough/features/wallet/presentation/widgets/wallet_spread_card.dart';
import 'package:saldough/shared/investment/investment.dart';
import 'package:saldough/shared/investment/investment_presentation.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';
import 'package:url_launcher/url_launcher.dart';

/// Membuka rute [key] lalu memuat ulang tab Dompet.
Future<void> _open<T extends RouteInput>(BuildContext context, RouteKey<T> key, T input) async {
  final bloc = context.read<WalletBloc>();
  await context.pushRoute(key, input);
  bloc.add(const WalletRefreshed());
}

/// Membuka Perbarui nilai untuk semua instrumen Aktif (rupa B-97 §5).
Future<void> openInvestmentValues(BuildContext context) =>
    _open(context, InvestmentRouteKeys.values, const InvestmentValuesInput());

/// Baris catatan kedaluwarsa di bawah hero (rupa B-97 §1.1): tampil bila ada
/// instrumen Aktif yang nilainya ≥ 30 hari.
class InvestmentStaleNote extends StatelessWidget {
  /// Membuat [InvestmentStaleNote].
  const InvestmentStaleNote({required this.count, super.key});

  /// Banyak instrumen kedaluwarsa.
  final int count;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        key: const ValueKey('investment-stale-note'),
        children: [
          Icon(Symbols.schedule_rounded, size: 16, color: ds.colors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              t.assets.invest.staleNote(n: count),
              style: ds.typography.bodySm.copyWith(color: ds.colors.textSecondary),
            ),
          ),
          DsInlineAction(label: t.assets.invest.update, dense: true, onPressed: () => openInvestmentValues(context)),
        ],
      ),
    );
  }
}

/// Isi segmen Investasi di tab Dompet (rupa B-97 §1.2–§1.3, ADR-049 §3.10).
class InvestmentSection extends StatelessWidget {
  /// Membuat [InvestmentSection].
  const InvestmentSection({
    required this.active,
    required this.closed,
    required this.failed,
    this.sheetFetchedAt,
    this.staleCount = 0,
    this.sheetCard,
    super.key,
  });

  /// Banyak instrumen Aktif yang nilainya kedaluwarsa; baris catatan tampil
  /// di atas daftar (bukan lagi di bawah hero).
  final int staleCount;

  /// Kartu Google Sheet harga (ADR-051), atau `null` bila tidak tersedia.
  final Widget? sheetCard;

  /// Instrumen Aktif, nilai pasar terbesar dulu.
  final List<InstrumentSummary> active;

  /// Instrumen Selesai.
  final List<InstrumentSummary> closed;

  /// Pembacaan investasi gagal.
  final bool failed;

  /// Kapan harga terakhir diambil dari Google Sheet.
  final DateTime? sheetFetchedAt;

  void _buy(BuildContext context) => _open(
    context,
    RecordRouteKeys.sheet,
    const RecordSheetInput(initialChoice: RecordChoice.investment, investmentSide: InvestmentSide.buy),
  );

  void _add(BuildContext context) => _open(context, InvestmentRouteKeys.form, const InvestmentFormInput());

  void _detail(BuildContext context, String id) =>
      _open(context, InvestmentRouteKeys.detail, InvestmentDetailInput(id));

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final s = t.assets.invest;
    if (failed) {
      return DsErrorState(
        title: s.loadError,
        retryLabel: t.common.retry,
        onRetry: () => context.read<WalletBloc>().add(const WalletRefreshed()),
      );
    }
    final today = DateTime.now();
    // Sebaran memakai kartu sebaran dompet: tiap instrumen jadi satu irisan.
    final slices = [
      for (final i in active)
        if (i.marketValue > 0)
          Wallet(
            id: i.instrument.id,
            name: i.instrument.name,
            iconKey: 'categoryInvestment',
            initialBalance: i.marketValue,
            currentBalance: i.marketValue,
          ),
    ];
    final shares = walletShares(slices);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (active.isEmpty)
          _Empty(compact: closed.isNotEmpty, onAdd: () => _add(context), onBuy: () => _buy(context))
        else ...[
          if (shares.length > 1) ...[
            WalletSpreadCard(
              wallets: slices,
              shares: shares,
              colors: walletColorsDs(ds.colors, slices),
              total: investmentLayerValue(active),
              activeCount: slices.length,
              title: s.spreadTitle,
              totalLabel: t.assets.layerInvestment,
              countLabel: s.count(n: active.length),
              onSelected: (_) {},
            ),
            const SizedBox(height: 16),
          ],
          // Berdampingan bila muat; di layar sempit atau teks besar menumpuk
          // (rupa B-97 §1.2), supaya label tidak terpotong.
          LayoutBuilder(
            builder: (context, constraints) {
              final buy = DsButton(
                key: const ValueKey('investment-buy'),
                label: s.recordBuy,
                icon: Symbols.add_rounded,
                expand: true,
                onPressed: () => _buy(context),
              );
              final update = DsButton.secondary(
                key: const ValueKey('investment-update-values'),
                label: s.updateValues,
                icon: Symbols.update_rounded,
                expand: true,
                onPressed: () => openInvestmentValues(context),
              );
              final wide = constraints.maxWidth >= 360 && MediaQuery.textScalerOf(context).scale(14) <= 16;
              if (!wide) return Column(children: [buy, const SizedBox(height: 8), update]);
              return Row(
                children: [
                  Expanded(child: buy),
                  const SizedBox(width: 8),
                  Expanded(child: update),
                ],
              );
            },
          ),
          // Satu strip sumber harga (Sheet) di antara aksi dan daftar.
          if (sheetCard != null) ...[const SizedBox(height: 12), sheetCard!],
          if (staleCount > 0) InvestmentStaleNote(count: staleCount),
          const SizedBox(height: 16),
          DsSectionHeader(title: s.activeHeading),
          const SizedBox(height: 8),
          for (final i in active)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InstrumentCard(
                key: ValueKey('instrument-card-${i.instrument.id}'),
                summary: i,
                today: today,
                sheetFetchedAt: sheetFetchedAt,
                onTap: () => _detail(context, i.instrument.id),
              ),
            ),
        ],
        if (closed.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(s.doneHeading, style: ds.typography.labelMd.copyWith(color: ds.colors.textMuted)),
          const SizedBox(height: 8),
          for (final i in closed)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InstrumentCard(
                key: ValueKey('instrument-card-${i.instrument.id}'),
                summary: i,
                today: today,
                onTap: () => _detail(context, i.instrument.id),
              ),
            ),
        ],
        // Saat kosong, kartu kosong sudah menawarkan Tambah investasi.
        if (active.isNotEmpty) ...[
          const SizedBox(height: 16),
          DsDashedButton(
            key: const ValueKey('investment-add'),
            label: s.add,
            icon: Symbols.add_rounded,
            onPressed: () => _add(context),
          ),
        ],
      ],
    );
  }
}

/// Kartu satu instrumen (rupa B-97 §1.2 butir 4–5): Aktif menampilkan nilai
/// pasar, untung/rugi, dan kesegaran; Selesai redup dengan untung/rugi
/// terwujud.
class InstrumentCard extends StatelessWidget {
  /// Membuat [InstrumentCard].
  const InstrumentCard({required this.summary, required this.today, this.sheetFetchedAt, this.onTap, super.key});

  /// Ringkasan instrumen.
  final InstrumentSummary summary;

  /// Hari ini, untuk kesegaran.
  final DateTime today;

  /// Kapan harga terakhir diambil dari Google Sheet.
  final DateTime? sheetFetchedAt;

  /// Membuka rincian.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final s = t.assets.invest;
    final instrument = summary.instrument;
    final position = summary.position;
    final active = position.isActive;
    final subtitle = [
      formatQuantity(instrument.type, position.quantity),
      instrument.code ?? instrumentTypeLabel(instrument.type),
    ].join(' · ');
    return Opacity(
      opacity: active ? 1 : 0.6,
      child: Semantics(
        button: onTap != null,
        label: instrument.name,
        child: DsPressable(
          onPressed: onTap,
          builder: (context, _) => DsCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                instrumentTile(instrument.type),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              instrument.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: ds.typography.titleMd.copyWith(fontSize: 15),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (active)
                            // Nilai baru dari Sheet masuk dengan hitung naik (ADR-051 §3.4).
                            DsCountUp(
                              value: summary.marketValue,
                              fromZero: false,
                              builder: (context, value) => Text(
                                AppMoneyText.format(value, MoneyKind.balance),
                                style: ds.typography.titleMd.copyWith(fontSize: 15),
                              ),
                            )
                          else
                            Text(s.soldOut, style: ds.typography.bodySm.copyWith(color: c.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (active) ...[
                        Builder(
                          builder: (context) {
                            final subtitleText = Text.rich(
                              TextSpan(
                                text: subtitle,
                                children: [
                                  if (summary.valuation?.source == ValuationSource.sheetEstimate)
                                    TextSpan(text: ' · ${s.sheet.estimateTag}'),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: ds.typography.bodySm.copyWith(color: c.textMuted),
                            );
                            final pill = summary.neverValued
                                ? null
                                : InvestmentGainPill(amount: summary.unrealized, base: position.cost);
                            // Teks besar: untung/rugi turun ke baris sendiri
                            // supaya jumlah dan kode tidak terpotong.
                            if (MediaQuery.textScalerOf(context).scale(14) > 18) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [subtitleText, if (pill != null) ...[const SizedBox(height: 4), pill]],
                              );
                            }
                            return Row(children: [Expanded(child: subtitleText), ?pill]);
                          },
                        ),
                        // Kesegaran hanya bila perlu perhatian (belum pernah
                        // divaluasi atau kedaluwarsa); sumber dan jam ada di
                        // strip Sheet, tidak diulang di tiap kartu.
                        if (summary.neverValued || summary.isStale(today)) ...[
                          const SizedBox(height: 6),
                          InvestmentFreshness(summary: summary, today: today, sheetFetchedAt: sheetFetchedAt),
                        ],
                      ] else
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                position.realized < 0 ? s.realizedLoss : s.realizedGain,
                                style: ds.typography.bodySm.copyWith(color: c.textMuted),
                              ),
                            ),
                            InvestmentGainPill(amount: position.realized),
                          ],
                        ),
                    ],
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

class _Empty extends StatelessWidget {
  const _Empty({required this.compact, required this.onAdd, required this.onBuy});

  final bool compact;
  final VoidCallback onAdd;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final s = t.assets.invest;
    return DsCard(
      key: const ValueKey('investment-empty'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!compact) ...[
            const Center(child: DsEmptyHero(asset: ClayIcons.chart, size: 96)),
            const SizedBox(height: 12),
          ],
          Text(s.emptyTitle, style: ds.typography.titleMd, textAlign: compact ? TextAlign.start : TextAlign.center),
          const SizedBox(height: 4),
          Text(
            s.emptyBody,
            style: ds.typography.bodySm.copyWith(color: ds.colors.textSecondary),
            textAlign: compact ? TextAlign.start : TextAlign.center,
          ),
          const SizedBox(height: 16),
          DsButton(key: const ValueKey('investment-add-empty'), label: s.add, expand: true, onPressed: onAdd),
          const SizedBox(height: 8),
          DsButton.secondary(key: const ValueKey('investment-buy-empty'), label: s.recordBuy, expand: true, onPressed: onBuy),
          const SizedBox(height: 8),
          Text(s.emptyHint, style: ds.typography.bodySm.copyWith(color: ds.colors.textMuted)),
        ],
      ),
    );
  }
}

/// Kartu Google Sheet harga di segmen Investasi (ADR-051 §3.2, §3.5, §3.6):
/// ajakan Hubungkan bila belum, baris status bila sudah, dan ajakan
/// menghubungkan lagi bila izin dicabut. Hanya untuk yang masuk dengan Google.
class PriceSheetCard extends StatelessWidget {
  /// Membuat [PriceSheetCard].
  const PriceSheetCard({
    required this.linked,
    required this.problem,
    required this.connecting,
    required this.isPlus,
    required this.onConnect,
    required this.onDisconnect,
    required this.onRefresh,
    this.refreshing = false,
    this.sheetId,
    this.fetchedAt,
    this.stocksWithoutCode = const [],
    super.key,
  });

  /// Nama saham Aktif tanpa kode bursa: harganya tidak bisa diambil otomatis.
  final List<String> stocksWithoutCode;

  /// Sudah terhubung.
  final bool linked;

  /// Masalah terakhir.
  final PriceSheetProblem problem;

  /// Alur Hubungkan berjalan.
  final bool connecting;

  /// Plus aktif; Gratis membuka paywall.
  final bool isPlus;

  /// ID Sheet, untuk Buka di Google Sheets.
  final String? sheetId;

  /// Kapan harga terakhir diambil.
  final DateTime? fetchedAt;

  /// Hubungkan (atau hubungkan lagi).
  final VoidCallback onConnect;

  /// Putuskan.
  final VoidCallback onDisconnect;

  /// Segarkan sekarang.
  final VoidCallback onRefresh;

  /// Pengambilan harga sedang berjalan (ikon segarkan jadi indikator).
  final bool refreshing;

  Future<void> _connect(BuildContext context) async {
    if (!isPlus) {
      await context.pushRoute(PremiumRouteKeys.paywall, const PaywallInput(PaywallTrigger.sheetPrices));
      return;
    }
    onConnect();
  }

  /// Plus berakhir: tautan tetap, mengambil harga membuka paywall (ADR-051 §3.5).
  Future<void> _refresh(BuildContext context) async {
    if (!isPlus) {
      await context.pushRoute(PremiumRouteKeys.paywall, const PaywallInput(PaywallTrigger.sheetPrices));
      return;
    }
    onRefresh();
  }

  Future<void> _options(BuildContext context) async {
    final s = t.assets.invest.sheet;
    final picked = await showOptionSheet<String>(
      context,
      title: s.optionsTitle,
      current: null,
      options: [
        OptionSheetItem(value: 'open', label: s.open, leading: const Icon(Symbols.open_in_new_rounded)),
        OptionSheetItem(value: 'refresh', label: s.refresh, leading: const Icon(Symbols.update_rounded)),
        OptionSheetItem(value: 'guide', label: s.guideAction, leading: const Icon(Symbols.help_outline_rounded)),
        OptionSheetItem(value: 'disconnect', label: s.disconnect, leading: const Icon(Symbols.link_off_rounded)),
      ],
    );
    switch (picked) {
      case 'open' when sheetId != null:
        await launchUrl(Uri.parse('https://docs.google.com/spreadsheets/d/$sheetId'), mode: LaunchMode.externalApplication);
      case 'refresh' when context.mounted:
        await _refresh(context);
      case 'guide' when context.mounted:
        await showPriceSheetGuide(context);
      case 'disconnect':
        onDisconnect();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = t.assets.invest.sheet;
    if (linked && problem != PriceSheetProblem.notAuthorized) {
      final time = fetchedAt;
      final ds = context.ds;
      // Satu strip: status dan jam di kiri, segarkan di kanan; catatan (saham
      // tanpa kode) satu baris di bawahnya. Penjelasan ada di Cara kerja, yang
      // dibuka dari menu strip (ketuk).
      return DsCard(
        key: const ValueKey('price-sheet-linked'),
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        onTap: () => _options(context),
        child: Row(
          children: [
            DsIconTile.asset(asset: ClayIcons.priceRefresh, size: DsIconTileSize.sm),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.linkedTitle, style: ds.typography.labelSm.copyWith(color: ds.colors.textSecondary)),
                  Text(
                    time == null ? s.linkedNever : s.linkedStatus(time: formatClock(time)),
                    style: ds.typography.bodyMd.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (stocksWithoutCode.isNotEmpty)
                    Padding(
                      key: const ValueKey('price-sheet-missing-code'),
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          Icon(Symbols.info_rounded, size: 14, color: ds.colors.warning),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              s.missingCodeShort(names: stocksWithoutCode.join(', ')),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: ds.typography.bodySm.copyWith(color: ds.colors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (refreshing)
              const SizedBox(
                width: 48,
                height: 48,
                child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5))),
              )
            else
              DsIconButton(
                key: const ValueKey('price-sheet-refresh'),
                icon: Symbols.update_rounded,
                label: s.refresh,
                onPressed: () => _refresh(context),
              ),
          ],
        ),
      );
    }
    // Ringkas: satu baris (umpan balik pemilik 18 Nov 2026). Penjelasan dan
    // tombol Hubungkan ada di lembar Cara kerja.
    final reconnect = problem != PriceSheetProblem.none;
    return DsFieldGroup(
      key: const ValueKey('price-sheet-connect'),
      children: [
        DsFieldRow(
          key: const ValueKey('price-sheet-connect-button'),
          icon: Symbols.add_link_rounded,
          leading: DsIconTile.asset(asset: ClayIcons.priceRefresh, size: DsIconTileSize.sm),
          label: s.connectTitle,
          title: connecting
              ? s.connecting
              : switch (problem) {
                  PriceSheetProblem.notAuthorized => s.reconnectShort,
                  PriceSheetProblem.notFound => s.reconnectShort,
                  PriceSheetProblem.none => s.connect,
                },
          trailing: isPlus ? null : const DsBadge(label: 'Plus'),
          chevron: true,
          onTap: connecting
              ? null
              : () => showPriceSheetGuide(
                  context,
                  actionLabel: reconnect ? s.reconnectShort : s.connect,
                  onAction: () => _connect(context),
                ),
        ),
      ],
    );
  }
}
