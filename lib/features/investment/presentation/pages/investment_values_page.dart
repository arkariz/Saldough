import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_input.dart';
import 'package:saldough/features/investment/presentation/bloc/investment_bloc.dart';
import 'package:saldough/shared/investment/investment.dart';
import 'package:saldough/shared/investment/investment_presentation.dart';
import 'package:state_management/state_management.dart';

/// Perbarui nilai (rupa B-97 §5, ADR-049 §3.11): satu tanggal untuk semua,
/// satu kolom harga per instrumen Aktif; yang kosong tidak berubah. [onlyId]
/// = satu instrumen dari Rincian. Nanti juga pratinjau B-101.
class InvestmentValuesPage extends StatefulWidget {
  /// Membuat [InvestmentValuesPage].
  const InvestmentValuesPage({this.onlyId, super.key});

  /// Satu instrumen saja, atau `null` untuk semua yang Aktif.
  final String? onlyId;

  @override
  State<InvestmentValuesPage> createState() => _InvestmentValuesPageState();
}

class _InvestmentValuesPageState extends State<InvestmentValuesPage> {
  final _controllers = <String, TextEditingController>{};
  final _totalMode = <String>{};
  DateTime _date = DateTime.now();

  TextEditingController _controller(String id) => _controllers.putIfAbsent(id, TextEditingController.new);

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<InstrumentSummary> _rows(InvestmentState state) {
    final today = DateTime.now();
    final rows = widget.onlyId == null
        ? state.active
        : [?state.summaryOf(widget.onlyId!)];
    // Kedaluwarsa dan belum pernah diperbarui dulu.
    int rank(InstrumentSummary s) => s.neverValued || s.isStale(today) ? 0 : 1;
    return [...rows]..sort((a, b) => rank(a).compareTo(rank(b)));
  }

  /// Harga per satuan dari isian baris [s], atau `null` bila kosong.
  int? _priceOf(InstrumentSummary s) {
    final text = _controllers[s.instrument.id]?.text ?? '';
    final type = s.instrument.type;
    if (_totalMode.contains(s.instrument.id)) {
      final total = parseMoneyInput(text);
      if (total == null || s.position.quantity <= 0) return null;
      return unitPriceFor(type, s.position.quantity, total);
    }
    return parseUnitPriceInput(type, text);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(now.year - 50), lastDate: now);
    if (picked != null) setState(() => _date = picked);
  }

  void _save(List<InstrumentSummary> rows) {
    final valuations = [
      for (final s in rows)
        if (_priceOf(s) case final price?)
          InstrumentValuation(instrumentId: s.instrument.id, date: _date, unitPrice: price),
    ];
    if (valuations.isEmpty) return;
    context.read<InvestmentBloc>().add(ValuationsSaved(valuations, single: widget.onlyId != null));
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final s = t.assets.invest;
    return BlocConsumer<InvestmentBloc, InvestmentState>(
      listenWhen: (a, b) => a.saveCount != b.saveCount,
      listener: (context, _) => Navigator.of(context).maybePop(),
      builder: (context, state) {
        final rows = _rows(state);
        final filled = rows.where((r) => _priceOf(r) != null).length;
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      AppFormHeader(title: s.bulk.title),
                      const SizedBox(height: 12),
                      // Kepala bergambar (poles B-97): ilustrasi clay dan penjelasan.
                      DsReveal(
                        child: Row(
                          children: [
                            DsIdleMotion(
                              kind: DsIdleKind.float,
                              child: DsIconTile.asset(asset: ClayIcons.priceRefresh, size: DsIconTileSize.lg),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(s.bulk.intro, style: ds.typography.bodySm.copyWith(color: c.textSecondary)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      DsFieldGroup(
                        children: [
                          DsFieldRow(
                            key: const ValueKey('values-date'),
                            icon: Icons.event_rounded,
                            label: s.bulk.dateLabel,
                            title: CycleMonthFormatter.formatDate(_date),
                            chevron: true,
                            onTap: _pickDate,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (state.isLoading)
                        for (var i = 0; i < 3; i++) ...[
                          const DsSkeleton(height: 120, radius: DsRadius.lgAll),
                          const SizedBox(height: 8),
                        ]
                      else
                        for (final (i, row) in rows.indexed) ...[
                          DsReveal(
                            index: i + 1,
                            child: _ValueCard(
                            key: ValueKey('values-card-${row.instrument.id}'),
                            summary: row,
                            date: _date,
                            existing: state.valuationsOf(row.instrument.id).where((v) => v.date == _day(_date)).firstOrNull,
                            controller: _controller(row.instrument.id),
                            totalMode: _totalMode.contains(row.instrument.id),
                            price: _priceOf(row),
                            onChanged: () => setState(() {}),
                            onToggleMode: () => setState(() {
                              final id = row.instrument.id;
                              if (!_totalMode.remove(id)) _totalMode.add(id);
                              _controllers[id]?.clear();
                            }),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                    ],
                  ),
                ),
                DsStickyBar(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (filled == 0) ...[
                        Text(s.bulk.needOne, style: ds.typography.bodySm.copyWith(color: c.textMuted)),
                        const SizedBox(height: 8),
                      ],
                      DsButton(
                        key: const ValueKey('values-save'),
                        label: widget.onlyId != null || filled <= 1 ? s.bulk.saveOne : s.bulk.save(n: filled),
                        expand: true,
                        onPressed: filled == 0 ? null : () => _save(rows),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

class _ValueCard extends StatelessWidget {
  const _ValueCard({
    required this.summary,
    required this.date,
    required this.existing,
    required this.controller,
    required this.totalMode,
    required this.price,
    required this.onChanged,
    required this.onToggleMode,
    super.key,
  });

  final InstrumentSummary summary;
  final DateTime date;
  final InstrumentValuation? existing;
  final TextEditingController controller;
  final bool totalMode;
  final int? price;
  final VoidCallback onChanged;
  final VoidCallback onToggleMode;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final s = t.assets.invest;
    final instrument = summary.instrument;
    final type = instrument.type;
    final quantity = summary.position.quantity;
    final last = summary.valuation;
    final previewValue = price == null ? null : marketValueOf(type, quantity, price!);
    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              instrumentTile(type),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      instrument.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: ds.typography.titleMd.copyWith(fontSize: 15),
                    ),
                    Text(formatQuantity(type, quantity), style: ds.typography.bodySm.copyWith(color: c.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Harga sebelumnya sebagai baris label–nilai: tanggal di bawah label.
          DecoratedBox(
            decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: DsRadius.mdAll),
            child: existing != null
                ? InvestmentInfoRow(
                    icon: Symbols.swap_horiz_rounded,
                    label: s.bulk.replacesLabel,
                    caption: CycleMonthFormatter.formatDate(existing!.date),
                    value: formatUnitPrice(type, existing!.unitPrice),
                  )
                : last == null
                ? InvestmentInfoRow(icon: Symbols.sell_rounded, label: s.lastPrice, value: s.neverUpdated)
                : InvestmentInfoRow(
                    icon: Symbols.sell_rounded,
                    label: s.lastPrice,
                    caption: CycleMonthFormatter.formatDate(last.date),
                    value: formatUnitPrice(type, last.unitPrice),
                  ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  totalMode
                      ? s.bulk.totalLabel
                      : '${s.bulk.priceLabel} ${type.usesNominal ? s.price.bondPercent : _unitSuffix(type)}',
                  style: ds.typography.labelMd.copyWith(color: c.textMuted),
                ),
              ),
              if (quantity > 0)
                DsInlineAction(
                  key: ValueKey('values-mode-${instrument.id}'),
                  label: totalMode ? s.bulk.fillPrice : s.bulk.fillTotal,
                  dense: true,
                  onPressed: onToggleMode,
                ),
            ],
          ),
          const SizedBox(height: 4),
          if (type.usesNominal && !totalMode)
            AppFormQuantityField(
              key: ValueKey('values-field-${instrument.id}'),
              controller: controller,
              decimals: 4,
              unit: '%',
              hint: '100',
              onChanged: (_) => onChanged(),
            )
          else
            AppFormMoneyField(
              key: ValueKey('values-field-${instrument.id}'),
              controller: controller,
              onChanged: (_) => onChanged(),
            ),
          // Pratinjau muncul dengan geser-pudar begitu harga terisi.
          AnimatedSize(
            duration: DsMotion.reduced(context) ? Duration.zero : const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: previewValue == null || price == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: c.actionPrimary.withValues(alpha: 0.06),
                        borderRadius: DsRadius.mdAll,
                      ),
                      child: Column(
                        children: [
                          if (totalMode)
                            InvestmentInfoRow(label: s.bulk.priceLabel, value: formatUnitPrice(type, price!)),
                          InvestmentInfoRow(
                            label: s.marketValue,
                            value: AppMoneyText.format(previewValue, MoneyKind.balance),
                          ),
                          if (previewValue != summary.position.cost)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: InvestmentGainPill(
                                  amount: previewValue - summary.position.cost,
                                  base: summary.position.cost,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  static String _unitSuffix(InstrumentType type) => switch (type) {
    InstrumentType.stock => t.assets.invest.price.perShare,
    InstrumentType.gold => t.assets.invest.price.perGram,
    InstrumentType.mutualFund || InstrumentType.other || InstrumentType.bond => t.assets.invest.price.perUnit,
  };
}
