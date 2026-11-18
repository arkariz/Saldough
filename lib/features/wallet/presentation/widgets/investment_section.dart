import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/investment/presentation/navigation/investment_route_keys.dart';
import 'package:saldough/features/record/presentation/navigation/record_route_keys.dart';
import 'package:saldough/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:saldough/features/wallet/presentation/wallet_shares.dart';
import 'package:saldough/features/wallet/presentation/widgets/wallet_card.dart';
import 'package:saldough/features/wallet/presentation/widgets/wallet_spread_card.dart';
import 'package:saldough/shared/investment/investment.dart';
import 'package:saldough/shared/investment/investment_presentation.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

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
  const InvestmentSection({required this.active, required this.closed, required this.failed, super.key});

  /// Instrumen Aktif, nilai pasar terbesar dulu.
  final List<InstrumentSummary> active;

  /// Instrumen Selesai.
  final List<InstrumentSummary> closed;

  /// Pembacaan investasi gagal.
  final bool failed;

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
          Row(
            children: [
              Expanded(
                child: DsButton(
                  key: const ValueKey('investment-buy'),
                  label: s.recordBuy,
                  icon: Symbols.add_rounded,
                  expand: true,
                  onPressed: () => _buy(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DsButton.secondary(
                  key: const ValueKey('investment-update-values'),
                  label: s.updateValues,
                  icon: Symbols.update_rounded,
                  expand: true,
                  onPressed: () => openInvestmentValues(context),
                ),
              ),
            ],
          ),
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
  const InstrumentCard({required this.summary, required this.today, this.onTap, super.key});

  /// Ringkasan instrumen.
  final InstrumentSummary summary;

  /// Hari ini, untuk kesegaran.
  final DateTime today;

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
                            Text(
                              AppMoneyText.format(summary.marketValue, MoneyKind.balance),
                              style: ds.typography.titleMd.copyWith(fontSize: 15),
                            )
                          else
                            Text(s.soldOut, style: ds.typography.bodySm.copyWith(color: c.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (active) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Text(subtitle, style: ds.typography.bodySm.copyWith(color: c.textMuted)),
                            ),
                            if (!summary.neverValued) InvestmentGainPill(amount: summary.unrealized, base: position.cost),
                          ],
                        ),
                        const SizedBox(height: 6),
                        InvestmentFreshness(summary: summary, today: today),
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
