import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/investment/presentation/bloc/investment_bloc.dart';
import 'package:saldough/features/investment/presentation/navigation/investment_route_keys.dart';
import 'package:saldough/features/record/presentation/navigation/record_route_keys.dart';
import 'package:saldough/features/transaction/presentation/navigation/transaction_route_keys.dart';
import 'package:saldough/shared/investment/investment.dart';
import 'package:saldough/shared/investment/investment_presentation.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/transaction/transaction_presentation.dart';
import 'package:state_management/state_management.dart';

/// Banyaknya nilai terbaru sebelum "Tampilkan semua".
const _valuesLimit = 10;

/// Rincian instrumen (rupa B-97 §2): nilai pasar, posisi, catatan beli dan
/// jual, riwayat nilai, dan tindakan.
class InvestmentDetailPage extends StatefulWidget {
  /// Membuat [InvestmentDetailPage].
  const InvestmentDetailPage({required this.instrumentId, super.key});

  /// Instrumen yang ditampilkan.
  final String instrumentId;

  @override
  State<InvestmentDetailPage> createState() => _InvestmentDetailPageState();
}

class _InvestmentDetailPageState extends State<InvestmentDetailPage> {
  bool _allValues = false;

  Future<void> _push<T extends RouteInput>(RouteKey<T> key, T input) async {
    final bloc = context.read<InvestmentBloc>();
    await context.pushRoute(key, input);
    bloc.add(const InvestmentStarted());
  }

  void _record(InvestmentSide side) => _push(
    RecordRouteKeys.sheet,
    RecordSheetInput(
      initialChoice: RecordChoice.investment,
      investmentSide: side,
      initialInstrumentId: widget.instrumentId,
    ),
  );

  void _deleteValue(InstrumentValuation valuation) {
    final bloc = context.read<InvestmentBloc>()..add(ValuationDeleted(valuation));
    final date = CycleMonthFormatter.formatDate(valuation.date);
    ScaffoldMessenger.of(context).showAppSnackBar(
      actionSnackBar(
        context,
        content: Text(t.assets.invest.valueDeleted(date: date)),
        action: SnackBarAction(
          label: t.assets.invest.undo,
          onPressed: () => bloc.add(ValuationsSaved([valuation], restore: true)),
        ),
      ),
    );
  }

  Future<void> _delete(InstrumentSummary summary, int records) async {
    final s = t.assets.invest;
    final bloc = context.read<InvestmentBloc>();
    if (records > 0) {
      // Tombol tetap aktif supaya alasannya terlihat (rupa B-97 §2); catatan
      // dihapus dari daftar di atas atau di Riwayat.
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(s.deleteBlockedTitle, style: dialogContext.ds.typography.headlineMd.copyWith(fontSize: 20)),
          content: Text(
            s.deleteBlockedBody(n: records, name: summary.instrument.name),
            style: dialogContext.ds.typography.bodyMd.copyWith(color: dialogContext.ds.colors.textSecondary),
          ),
          actions: [DsButton.ghost(label: s.close, onPressed: () => Navigator.of(dialogContext).pop())],
        ),
      );
      return;
    }
    final confirmed = await showConfirmDelete(context, title: s.deleteConfirmTitle, message: s.deleteConfirmBody);
    if (confirmed) bloc.add(InstrumentDeleted(widget.instrumentId));
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final s = t.assets.invest;
    return BlocListener<InvestmentBloc, InvestmentState>(
      // Hapus berhasil menutup rincian.
      listenWhen: (a, b) => a.saveCount != b.saveCount && b.summaryOf(widget.instrumentId) == null,
      listener: (context, _) => Navigator.of(context).maybePop(),
      child: Scaffold(
        body: SafeArea(
          child: BlocBuilder<InvestmentBloc, InvestmentState>(
            builder: (context, state) {
              if (state.isLoading) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    spacing: 16,
                    children: [
                      DsSkeleton(height: 48, radius: DsRadius.fullAll),
                      DsSkeleton(height: 180, radius: DsRadius.lgAll),
                      DsSkeleton(height: 120, radius: DsRadius.lgAll),
                    ],
                  ),
                );
              }
              if (state.loadFailed) {
                return DsErrorState(
                  title: s.detailLoadError,
                  retryLabel: t.common.retry,
                  onRetry: () => context.read<InvestmentBloc>().add(const InvestmentStarted()),
                );
              }
              final summary = state.summaryOf(widget.instrumentId);
              if (summary == null) {
                return Center(child: Text(s.notFound, style: ds.typography.bodyMd));
              }
              final instrument = summary.instrument;
              final position = summary.position;
              final type = instrument.type;
              final active = position.isActive;
              final today = DateTime.now();
              final trades = state.tradesOf(instrument.id);
              final valuations = state.valuationsOf(instrument.id);
              final shownValues = _allValues ? valuations : valuations.take(_valuesLimit).toList();
              final walletsById = {for (final w in state.wallets) w.id: w};
              final valuation = summary.valuation;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  SizedBox(
                    height: 48,
                    child: Row(
                      children: [
                        DsIconButton(
                          icon: Icons.arrow_back,
                          label: t.transaction.detailBackLabel,
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Kartu ringkasan gelap (poles B-97): nilai pasar berhitung naik,
                  // bilah = bagian nilai perolehan dari nilai pasar, ilustrasi clay.
                  DsReveal(
                    child: DsSummaryHero(
                      label: instrument.name,
                      badge: [instrumentTypeLabel(type), ?instrument.code].join(' · '),
                      amount: active ? summary.marketValue : position.realized,
                      format: (v) => active ? AppMoneyFormatter.format(v) : formatSignedMoney(v),
                      negative: !active && position.realized < 0,
                      ratio: summary.marketValue <= 0 ? 0 : position.cost / summary.marketValue,
                      asset: instrumentClayAsset(type),
                      semanticLabel: active
                          ? '${s.marketValue} ${AppMoneyFormatter.format(summary.marketValue)}'
                          : '${position.realized < 0 ? s.realizedLoss : s.realizedGain} ${formatSignedMoney(position.realized)}',
                      stats: [
                        DsSummaryStat(
                          label: active ? s.cost : s.closedBadge,
                          value: active ? AppMoneyFormatter.format(position.cost) : s.soldOut,
                        ),
                        DsSummaryStat(
                          label: active ? s.unrealized : s.realized,
                          value: active
                              ? (summary.neverValued ? '—' : _gainText(summary.unrealized, position.cost))
                              : formatSignedMoney(position.realized),
                        ),
                      ],
                    ),
                  ),
                  if (active) ...[
                    const SizedBox(height: 12),
                    DsReveal(
                      index: 1,
                      child: DsCard(
                        child: Row(
                          children: [
                            Expanded(child: InvestmentFreshness(summary: summary, today: today)),
                            const SizedBox(width: 8),
                            DsInlineAction(
                              key: const ValueKey('instrument-update-value'),
                              label: s.updateValues,
                              icon: Symbols.update_rounded,
                              dense: true,
                              onPressed: () =>
                                  _push(InvestmentRouteKeys.values, InvestmentValuesInput(onlyId: instrument.id)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  DsReveal(
                    index: 2,
                    child: Row(
                      children: [
                        Expanded(
                          child: DsButton(
                            key: const ValueKey('instrument-record-buy'),
                            label: s.recordBuy,
                            icon: Symbols.add_rounded,
                            expand: true,
                            onPressed: () => _record(InvestmentSide.buy),
                          ),
                        ),
                        if (active && position.quantity > 0) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: DsButton.secondary(
                              key: const ValueKey('instrument-record-sell'),
                              label: s.recordSell,
                              icon: Symbols.remove_rounded,
                              expand: true,
                              onPressed: () => _record(InvestmentSide.sell),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  DsReveal(
                    index: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DsSectionHeader(title: s.positionHeading, icon: Symbols.analytics_rounded),
                        DsListCard(
                          children: [
                            InvestmentInfoRow(
                              icon: Symbols.tag_rounded,
                              label: type.usesNominal ? s.nominal : s.quantity,
                              value: formatQuantity(type, position.quantity),
                              caption: type == InstrumentType.stock && position.quantity > 0
                                  ? s.shares(n: formatShares(position.quantity))
                                  : null,
                            ),
                            InvestmentInfoRow(
                              icon: Symbols.payments_rounded,
                              label: s.cost,
                              value: AppMoneyFormatter.format(position.cost),
                            ),
                            if (position.quantity > 0 && position.cost > 0)
                              InvestmentInfoRow(
                                icon: Symbols.balance_rounded,
                                label: s.avgPrice,
                                value: formatUnitPrice(type, unitPriceFor(type, position.quantity, position.cost)),
                              ),
                            InvestmentInfoRow(
                              icon: Symbols.sell_rounded,
                              label: s.lastPrice,
                              caption: valuation == null ? null : CycleMonthFormatter.formatDate(valuation.date),
                              value: valuation == null ? s.neverUpdated : formatUnitPrice(type, valuation.unitPrice),
                            ),
                            if (active && !summary.neverValued)
                              InvestmentInfoRow(
                                icon: Symbols.trending_up_rounded,
                                label: s.unrealized,
                                value: _gainText(summary.unrealized, position.cost),
                                valueColor: _gainColor(c, summary.unrealized),
                              ),
                            if (trades.any((tx) => tx.side == InvestmentSide.sell))
                              InvestmentInfoRow(
                                icon: Symbols.done_all_rounded,
                                label: s.realized,
                                value: formatSignedMoney(position.realized),
                                valueColor: _gainColor(c, position.realized),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(s.positionNote, style: ds.typography.bodySm.copyWith(color: c.textMuted)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  DsSectionHeader(title: s.recordsHeading, icon: Symbols.receipt_long_rounded),
                  if (trades.isEmpty && instrument.opening == null)
                    Text(s.recordsEmpty, style: ds.typography.bodySm.copyWith(color: c.textSecondary))
                  else
                    DsListCard(
                      children: [
                        for (final tx in trades)
                          TransactionLedgerRow(
                            transaction: tx,
                            walletsById: walletsById,
                            onTap: () => _push(TransactionRouteKeys.detail, TransactionDetailInput(tx)),
                          ),
                        if (instrument.opening case final opening?)
                          DsPressable(
                            onPressed: () => _push(InvestmentRouteKeys.form, InvestmentFormInput(instrument: instrument)),
                            builder: (context, _) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Row(
                                children: [
                                  const DsIconTile(icon: Symbols.inventory_2_rounded),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(s.openingRow, style: ds.typography.bodyMd.copyWith(fontWeight: FontWeight.w700)),
                                        Text(
                                          CycleMonthFormatter.formatDate(opening.date),
                                          style: ds.typography.bodySm.copyWith(color: c.textMuted),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(formatQuantity(type, opening.quantity), style: ds.typography.bodyMd),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  DsSectionHeader(title: s.valuesHeading, icon: Symbols.history_rounded),
                  if (valuations.isEmpty)
                    Text(s.valuesEmpty, style: ds.typography.bodySm.copyWith(color: c.textSecondary))
                  else ...[
                    DsListCard(
                      children: [
                        for (final v in shownValues)
                          Padding(
                            key: ValueKey('value-row-${v.date.toIso8601String()}'),
                            padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(CycleMonthFormatter.formatDate(v.date), style: ds.typography.bodyMd),
                                      Text(
                                        formatUnitPrice(type, v.unitPrice),
                                        style: ds.typography.bodySm.copyWith(color: c.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                // Nilai pasar pada tanggal itu; tanpa angka bila saat itu
                                // tidak ada yang dipegang (mis. sesudah jual habis).
                                Builder(
                                  builder: (context) {
                                    final held = InstrumentPosition.replay(instrument, trades, asOf: v.date).quantity;
                                    return Text(
                                      held == 0
                                          ? '—'
                                          : AppMoneyText.format(marketValueOf(type, held, v.unitPrice), MoneyKind.balance),
                                      style: ds.typography.bodyMd,
                                    );
                                  },
                                ),
                                DsIconButton(
                                  icon: Icons.delete_outline,
                                  label: s.deleteValueLabel(date: CycleMonthFormatter.formatDate(v.date)),
                                  onPressed: () => _deleteValue(v),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    if (!_allValues && valuations.length > _valuesLimit)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: DsInlineAction(
                          label: s.showAll,
                          dense: true,
                          onPressed: () => setState(() => _allValues = true),
                        ),
                      ),
                  ],
                  const SizedBox(height: 24),
                  DsButton.secondary(
                    key: const ValueKey('instrument-edit'),
                    label: s.edit,
                    expand: true,
                    onPressed: () => _push(InvestmentRouteKeys.form, InvestmentFormInput(instrument: instrument)),
                  ),
                  const SizedBox(height: 8),
                  DsButton.danger(
                    key: const ValueKey('instrument-delete'),
                    label: s.delete,
                    expand: true,
                    onPressed: () => _delete(summary, trades.length),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

String _gainText(int amount, int cost) {
  final percent = formatSignedPercent(amount, cost);
  return percent == null ? formatSignedMoney(amount) : '${formatSignedMoney(amount)} · $percent';
}

Color _gainColor(DsColorScheme c, int amount) => amount > 0 ? c.income : (amount < 0 ? c.error : c.textPrimary);
