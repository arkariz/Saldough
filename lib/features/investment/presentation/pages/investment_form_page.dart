import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/plan/active_plan.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_input.dart';
import 'package:saldough/features/investment/presentation/bloc/investment_bloc.dart';
import 'package:saldough/features/premium/presentation/navigation/premium_route_keys.dart';
import 'package:saldough/shared/investment/investment.dart';
import 'package:saldough/shared/investment/investment_presentation.dart';
import 'package:state_management/state_management.dart';

/// Formulir Tambah/Ubah investasi (rupa B-97 §3, ADR-049 §3.7 pintu 1).
/// Tidak menyentuh dompet. Batas Gratis diperiksa saat menyimpan: isian
/// disimpan sebagai draf lalu paywall P12 dibuka (§3.12).
class InvestmentFormPage extends StatefulWidget {
  /// Membuat [InvestmentFormPage]. [initial] `null` = instrumen baru.
  const InvestmentFormPage({required this.draftStore, this.initial, super.key});

  /// Instrumen yang diubah, atau `null`.
  final Instrument? initial;

  /// Penyimpan draf P12.
  final InstrumentDraftStore draftStore;

  @override
  State<InvestmentFormPage> createState() => _InvestmentFormPageState();
}

class _InvestmentFormPageState extends State<InvestmentFormPage> {
  final _name = TextEditingController();
  final _code = TextEditingController();
  final _quantity = TextEditingController();
  final _cost = TextEditingController();
  late String _id;
  late DateTime _createdAt;
  InstrumentType? _type;
  bool _owned = true;
  DateTime _since = DateTime.now();
  bool _fromDraft = false;

  bool get _editing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _id = initial?.id ?? DateTime.now().microsecondsSinceEpoch.toString();
    _createdAt = initial?.createdAt ?? DateTime.now();
    if (initial != null) {
      _fill(initial);
    } else {
      unawaited(_loadDraft());
    }
  }

  void _fill(Instrument instrument) {
    _name.text = instrument.name;
    _code.text = instrument.code ?? '';
    _type = instrument.type;
    final opening = instrument.opening;
    _owned = opening != null || !_editing;
    if (opening != null) {
      _since = opening.date;
      _quantity.text = quantityInputText(instrument.type, opening.quantity);
      _cost.text = formatMoneyInput(opening.cost);
    }
  }

  Future<void> _loadDraft() async {
    final draft = (await widget.draftStore.read()).getOrElse((_) => null);
    if (draft == null || !mounted) return;
    setState(() {
      _fill(draft);
      // Draf menyimpan pilihan Sudah punya lewat ada-tidaknya kepemilikan awal.
      _owned = draft.opening != null;
      _fromDraft = true;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _quantity.dispose();
    _cost.dispose();
    super.dispose();
  }

  int? get _quantityValue => _type == null ? null : parseQuantityInput(_type!, _quantity.text);
  int? get _costValue => parseMoneyInput(_cost.text);

  bool get _ownedComplete => !_owned || (_quantityValue != null && _costValue != null);

  bool get _canSave => _name.text.trim().isNotEmpty && _type != null && _ownedComplete;

  /// Jenis terkunci sesudah ada catatan atau riwayat nilai (ADR-049 §3.1).
  bool _typeLocked(InvestmentState state) {
    if (!_editing) return false;
    return widget.initial!.opening != null ||
        state.tradesOf(_id).isNotEmpty ||
        state.valuationsOf(_id).isNotEmpty;
  }

  Instrument get _instrument {
    final code = _code.text.trim().toUpperCase();
    final quantity = _quantityValue;
    final cost = _costValue;
    return Instrument(
      id: _id,
      name: _name.text.trim(),
      type: _type!,
      createdAt: _createdAt,
      code: code.isEmpty ? null : code,
      opening: _owned && quantity != null && cost != null
          ? OpeningHolding(date: _since, quantity: quantity, cost: cost)
          : null,
    );
  }

  Future<void> _save() async {
    if (!_canSave) return;
    final bloc = context.read<InvestmentBloc>();
    final limit = ActivePlan.isPlus ? null : ActivePlan.limits.value.freeInstruments;
    // P12: instrumen Aktif baru ke-3 di Gratis. Isian tidak hilang (§3.12).
    if (!_editing && limit != null && activeInstrumentCount(bloc.state.summaries) >= limit) {
      await widget.draftStore.save(_instrument);
      if (!mounted) return;
      await context.pushRoute(PremiumRouteKeys.paywall, const PaywallInput(PaywallTrigger.instrumentLimit));
      return;
    }
    bloc.add(InstrumentSaved(_instrument, activeLimit: limit));
  }

  Future<void> _discardDraft() async {
    await widget.draftStore.clear();
    if (!mounted) return;
    setState(() {
      _fromDraft = false;
      _name.clear();
      _code.clear();
      _quantity.clear();
      _cost.clear();
      _type = null;
      _owned = true;
      _since = DateTime.now();
    });
  }

  Future<void> _pickSince() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _since.isAfter(now) ? now : _since,
      firstDate: DateTime(now.year - 50),
      lastDate: now,
    );
    if (picked != null) setState(() => _since = picked);
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final s = t.assets.invest;
    void refresh(String _) => setState(() {});
    Widget help(String text, {Color? color}) => Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(text, style: ds.typography.bodySm.copyWith(color: color ?? c.textSecondary)),
    );
    return BlocConsumer<InvestmentBloc, InvestmentState>(
      listenWhen: (a, b) => a.saveCount != b.saveCount,
      listener: (context, _) async {
        if (!_editing) await widget.draftStore.clear();
        if (context.mounted) Navigator.of(context).maybePop();
      },
      builder: (context, state) {
        final locked = _typeLocked(state);
        final type = _type;
        final quantity = _quantityValue;
        final cost = _costValue;
        final tooSmall = state.lastFailure == InvestmentFailures.insufficientQuantity;
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppFormHeader(title: _editing ? s.formTitleEdit : s.formTitleNew),
                        const SizedBox(height: 16),
                        // Pratinjau clay jenis (poles B-97): bergoyang saat jenis berganti.
                        Center(
                          child: DsWiggle(
                            trigger: type.hashCode,
                            child: AnimatedSwitcher(
                              duration: DsMotion.reduced(context) ? Duration.zero : const Duration(milliseconds: 250),
                              transitionBuilder: (child, animation) =>
                                  ScaleTransition(scale: animation, child: FadeTransition(opacity: animation, child: child)),
                              child: KeyedSubtree(
                                key: ValueKey(type),
                                child: type == null
                                    ? DsIconTile.asset(asset: ClayIcons.chart, size: DsIconTileSize.lg)
                                    : instrumentTile(type, size: DsIconTileSize.lg),
                              ),
                            ),
                          ),
                        ),
                        if (_name.text.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            _name.text.trim(),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ds.typography.headlineSm,
                          ),
                        ],
                        if (_fromDraft) ...[
                          const SizedBox(height: 16),
                          DsInlineBanner(
                            icon: Icons.edit_note,
                            message: s.draftResumed,
                            action: DsButton.ghost(label: s.discardDraft, onPressed: _discardDraft),
                          ),
                        ],
                        const SizedBox(height: 16),
                        AppSectionLabel(s.nameLabel, hint: t.wallet.nameRequiredHint),
                        const SizedBox(height: 8),
                        AppFormTextField(
                          key: const ValueKey('instrument-name'),
                          controller: _name,
                          hint: s.nameHint,
                          autofocus: !_editing,
                          maxLength: 60,
                          onChanged: refresh,
                        ),
                        const SizedBox(height: 16),
                        AppSectionLabel(s.typeLabel, hint: t.wallet.nameRequiredHint),
                        const SizedBox(height: 8),
                        InstrumentTypeChips(
                          selected: type,
                          enabled: !locked,
                          onSelected: (value) => setState(() {
                            _type = value;
                            _quantity.clear();
                          }),
                        ),
                        AnimatedSwitcher(
                          duration: DsMotion.reduced(context) ? Duration.zero : const Duration(milliseconds: 200),
                          child: locked
                              ? KeyedSubtree(key: const ValueKey('locked'), child: help(s.typeLocked))
                              : type == null
                              ? const SizedBox.shrink()
                              : KeyedSubtree(key: ValueKey(type), child: help(instrumentTypeHelp(type))),
                        ),
                        const SizedBox(height: 16),
                        AppSectionLabel(s.codeLabel),
                        const SizedBox(height: 8),
                        AppFormTextField(
                          key: const ValueKey('instrument-code'),
                          controller: _code,
                          hint: s.codeHint,
                          maxLength: 12,
                          onChanged: refresh,
                        ),
                        const SizedBox(height: 16),
                        DsSwitchRow(
                          key: const ValueKey('instrument-owned'),
                          title: s.ownedToggle,
                          subtitle: s.ownedToggleBody,
                          value: _owned,
                          onChanged: (value) => setState(() => _owned = value),
                        ),
                        AnimatedSize(
                          duration: DsMotion.reduced(context) ? Duration.zero : const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.topCenter,
                          child: !(_owned && type != null)
                              ? const SizedBox(width: double.infinity)
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                          const SizedBox(height: 12),
                          DsFieldGroup(
                            children: [
                              DsFieldRow(
                                key: const ValueKey('instrument-since'),
                                icon: Icons.event_rounded,
                                label: s.sinceLabel,
                                title: CycleMonthFormatter.formatDate(_since),
                                chevron: true,
                                onTap: _pickSince,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          AppSectionLabel(type.usesNominal ? s.nominal : s.quantity),
                          const SizedBox(height: 8),
                          if (type.usesNominal)
                            AppFormMoneyField(
                              key: const ValueKey('instrument-quantity'),
                              controller: _quantity,
                              onChanged: refresh,
                            )
                          else
                            AppFormQuantityField(
                              key: const ValueKey('instrument-quantity'),
                              controller: _quantity,
                              decimals: quantityDecimals(type),
                              unit: quantityUnit(type),
                              hint: '0',
                              onChanged: refresh,
                            ),
                          if (type == InstrumentType.stock && quantity != null)
                            help(s.shares(n: formatShares(quantity))),
                          if (tooSmall) help(s.openingTooSmall, color: c.error),
                          const SizedBox(height: 12),
                          AppSectionLabel(s.cost),
                          const SizedBox(height: 8),
                          AppFormMoneyField(
                            key: const ValueKey('instrument-cost'),
                            controller: _cost,
                            onChanged: refresh,
                          ),
                          help(s.costHelp),
                          if (quantity != null && cost != null) ...[
                            const SizedBox(height: 10),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: c.actionPrimary.withValues(alpha: 0.06),
                                borderRadius: DsRadius.mdAll,
                              ),
                              child: InvestmentInfoRow(
                                icon: Icons.balance_rounded,
                                label: s.avgPrice,
                                value: formatUnitPrice(type, unitPriceFor(type, quantity, cost)),
                              ),
                            ),
                          ],
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                DsStickyBar(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!_ownedComplete && _type != null) ...[
                        Text(s.ownedMissing, style: ds.typography.bodySm.copyWith(color: c.textMuted)),
                        const SizedBox(height: 8),
                      ],
                      DsButton(
                        key: const ValueKey('instrument-save'),
                        label: s.save,
                        expand: true,
                        onPressed: _canSave ? _save : null,
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
