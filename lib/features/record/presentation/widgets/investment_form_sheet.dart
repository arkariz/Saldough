import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/plan/active_plan.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/core/utils/formatters/money_input.dart';
import 'package:saldough/features/premium/presentation/navigation/premium_route_keys.dart';
import 'package:saldough/features/record/presentation/bloc/record_bloc.dart';
import 'package:saldough/features/record/presentation/widgets/record_amount_controller.dart';
import 'package:saldough/features/record/presentation/widgets/record_amount_field.dart';
import 'package:saldough/features/record/presentation/widgets/record_date_field.dart';
import 'package:saldough/features/record/presentation/widgets/record_form_frame.dart';
import 'package:saldough/features/record/presentation/widgets/record_note_field.dart';
import 'package:saldough/shared/investment/investment.dart';
import 'package:saldough/shared/investment/investment_presentation.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:saldough/shared/wallet/wallet_presentation.dart';

/// Jumlah sesudah tombol papan angka [key] pada isian [text] (rupa B-97
/// §4.4): angka ditambahkan, desimal sekali (bila [decimals] > 0, paling
/// banyak [decimals] angka), hapus membuang satu karakter, hapus semua
/// mengosongkan; operator diabaikan.
String quantityAfterKey(String text, String key, {required int decimals}) {
  final sep = MoneySeparators.decimal;
  if (key == moneyKeyBackspace) return text.isEmpty ? text : text.substring(0, text.length - 1);
  if (key == RecordFormFrame.frameClearKey) return '';
  if (key == moneyKeyDecimal) {
    if (decimals == 0 || text.contains(sep)) return text;
    return '${text.isEmpty ? '0' : text}$sep';
  }
  final digits = key == '000' ? (decimals > 0 ? '00' : '000') : key;
  if (!RegExp(r'^\d+$').hasMatch(digits)) return text;
  final next = text == '0' ? digits : '$text$digits';
  final fraction = next.contains(sep) ? next.split(sep).last : '';
  if (fraction.length > decimals || next.replaceAll(sep, '').length > 12) return text;
  return next;
}

/// Formulir CATAT jenis Investasi (rupa B-97 §4, ADR-049 §3.3, §3.7):
/// Pembelian atau Penjualan, dompet, instrumen (atau instrumen baru), jumlah
/// yang diisi papan angka, tanggal, dan catatan. [initial] = menyunting.
class InvestmentFormSheet extends StatefulWidget {
  /// Membuat [InvestmentFormSheet].
  const InvestmentFormSheet({
    required this.wallets,
    required this.instruments,
    required this.trades,
    this.kindSwitcher,
    this.initial,
    this.initialSide,
    this.initialInstrumentId,
    this.initialWalletId,
    super.key,
  });

  /// Dompet yang boleh dipakai (aktif, bukan milik tujuan).
  final List<Wallet> wallets;

  /// Instrumen yang ada.
  final List<InstrumentSummary> instruments;

  /// Semua transaksi investasi (jumlah dimiliki pada tanggal).
  final List<InvestmentTransaction> trades;

  /// Pengalih jenis CATAT.
  final Widget? kindSwitcher;

  /// Catatan yang disunting, atau `null`.
  final InvestmentTransaction? initial;

  /// Sisi awal.
  final InvestmentSide? initialSide;

  /// Instrumen awal.
  final String? initialInstrumentId;

  /// Dompet awal.
  final String? initialWalletId;

  @override
  State<InvestmentFormSheet> createState() => _InvestmentFormSheetState();
}

class _InvestmentFormSheetState extends State<InvestmentFormSheet> {
  final _amountController = RecordAmountController();
  final _noteController = TextEditingController();
  final _newName = TextEditingController();
  late InvestmentSide _side = widget.initial?.side ?? widget.initialSide ?? InvestmentSide.buy;
  String? _walletId;
  String? _instrumentId;
  bool _newInstrument = false;
  InstrumentType? _newType;
  String _quantityText = '';
  bool _quantityActive = false;
  bool _autoActivated = false;
  DateTime _date = DateTime.now();

  bool get _editing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _walletId = initial.walletId;
      _instrumentId = initial.instrumentId;
      _date = initial.date;
      _noteController.text = initial.note;
      _amountController.text = formatMoneyInput(initial.amount);
      final type = _summaryOf(initial.instrumentId)?.instrument.type ?? InstrumentType.other;
      _quantityText = quantityInputText(type, initial.quantity);
      _autoActivated = true;
    } else {
      _walletId = widget.wallets.any((w) => w.id == widget.initialWalletId)
          ? widget.initialWalletId
          : widget.wallets.firstOrNull?.id;
      final start = widget.initialInstrumentId;
      if (start != null && _selectable.any((s) => s.instrument.id == start)) _instrumentId = start;
      if (widget.instruments.isEmpty && _side == InvestmentSide.buy) _newInstrument = true;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _newName.dispose();
    super.dispose();
  }

  InstrumentSummary? _summaryOf(String? id) =>
      id == null ? null : widget.instruments.where((s) => s.instrument.id == id).firstOrNull;

  /// Instrumen yang boleh dipilih: Penjualan hanya yang masih dipegang.
  List<InstrumentSummary> get _selectable => _side == InvestmentSide.buy
      ? widget.instruments
      : widget.instruments.where((s) => s.position.quantity > 0 || s.instrument.id == widget.initial?.instrumentId).toList();

  InstrumentType? get _type => _newInstrument ? _newType : _summaryOf(_instrumentId)?.instrument.type;

  int? get _amountSen => parseMoneyInput(_amountController.text);

  int? get _quantity {
    final type = _type;
    if (type == null) return null;
    return type.usesNominal ? parseMoneyInput(_quantityText) : parseScaled(_quantityText);
  }

  /// Jumlah dimiliki pada tanggal formulir, tanpa catatan yang disunting.
  int? get _ownedOnDate {
    final summary = _summaryOf(_instrumentId);
    if (summary == null) return null;
    final others = [for (final t in widget.trades) if (t.id != widget.initial?.id) t];
    return InstrumentPosition.replay(summary.instrument, others, asOf: _date).quantity;
  }

  bool get _overSell =>
      _side == InvestmentSide.sell && _quantity != null && _ownedOnDate != null && _quantity! > _ownedOnDate!;

  bool get _instrumentReady => _newInstrument ? _newName.text.trim().isNotEmpty && _newType != null : _instrumentId != null;

  bool get _canSubmit =>
      _walletId != null && _instrumentReady && (_quantity ?? 0) > 0 && (_amountSen ?? 0) > 0 && !_overSell;

  void _onQuantityKey(String key) {
    final type = _type;
    if (type == null) return;
    setState(() => _quantityText = quantityAfterKey(_quantityText, key, decimals: quantityDecimals(type)));
  }

  void _activateQuantity(bool on) {
    if (_quantityActive == on) return;
    setState(() => _quantityActive = on);
    unawaited(
      SemanticsService.sendAnnouncement(
      View.of(context),
      on ? t.assets.invest.qtyActive : t.assets.invest.amountActive,
      Directionality.of(context),
      ),
    );
  }

  /// Sesudah instrumen dipilih dan jumlah masih kosong, papan angka pindah
  /// ke jumlah sekali (rupa B-97 §4.4).
  void _afterInstrumentChosen() {
    if (!_autoActivated && _quantityText.isEmpty) {
      _autoActivated = true;
      _activateQuantity(true);
    }
  }

  void _setSide(InvestmentSide side) => setState(() {
    _side = side;
    if (side == InvestmentSide.sell) {
      _newInstrument = false;
      if (!_selectable.any((s) => s.instrument.id == _instrumentId)) _instrumentId = null;
    }
  });

  Future<void> _pickInstrument() async {
    const newValue = '__new__';
    final s = t.assets.invest;
    final active = _selectable.where((i) => i.position.isActive).toList();
    final closed = _selectable.where((i) => !i.position.isActive).toList();
    final picked = await showOptionSheet<String>(
      context,
      title: s.pickTitle,
      current: _instrumentId,
      options: [
        for (final i in [...active, ...closed])
          OptionSheetItem(
            key: ValueKey('instrument-option-${i.instrument.id}'),
            value: i.instrument.id,
            label: i.instrument.name,
            detail: i.position.isActive
                ? s.ownedHint(qty: formatQuantity(i.instrument.type, i.position.quantity))
                : s.closedBadge,
            leading: instrumentTile(i.instrument.type, size: DsIconTileSize.sm),
          ),
        if (_side == InvestmentSide.buy && !_editing)
          OptionSheetItem(
            key: const ValueKey('instrument-option-new'),
            value: newValue,
            label: s.newInstrument,
            leading: const DsIconTile(icon: Symbols.add_rounded, size: DsIconTileSize.sm),
          ),
      ],
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (picked == newValue) {
        _newInstrument = true;
        _instrumentId = null;
      } else {
        _newInstrument = false;
        _instrumentId = picked;
        _quantityText = '';
      }
    });
    if (picked != newValue) _afterInstrumentChosen();
  }

  /// Instrumen baru, atau membeli lagi instrumen Selesai, melewati batas
  /// Gratis membuka P12; isian tetap di formulir (ADR-049 §3.12).
  bool get _hitsLimit {
    if (_editing || _side != InvestmentSide.buy || ActivePlan.isPlus) return false;
    final limit = ActivePlan.limits.value.freeInstruments;
    final reopening = _newInstrument || !(_summaryOf(_instrumentId)?.position.isActive ?? true);
    return reopening && activeInstrumentCount(widget.instruments) >= limit;
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    if (_hitsLimit) {
      await context.pushRoute(PremiumRouteKeys.paywall, const PaywallInput(PaywallTrigger.instrumentLimit));
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop(
      InvestmentRecorded(
        walletId: _walletId!,
        side: _side,
        quantity: _quantity!,
        amount: _amountSen!,
        date: _date,
        note: _noteController.text.trim(),
        instrumentId: _newInstrument ? null : _instrumentId,
        newInstrumentName: _newInstrument ? _newName.text.trim() : null,
        newInstrumentType: _newInstrument ? _newType : null,
        activeLimit: ActivePlan.isPlus ? null : ActivePlan.limits.value.freeInstruments,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final s = t.assets.invest;
    final type = _type;
    final summary = _summaryOf(_instrumentId);
    final buying = _side == InvestmentSide.buy;
    return RecordFormFrame(
      kindSwitcher: _editing ? null : widget.kindSwitcher,
      kind: TransactionKind.transfer,
      title: _editing ? t.transaction.editSheetTitle : t.appShell.recordAction,
      isEditing: _editing,
      onBack: () => Navigator.of(context).pop(),
      amountController: _amountController,
      onAmountChanged: () => setState(() {}),
      submitLabel: _editing ? t.transaction.saveChangesAction : (buying ? s.recordBuy : s.recordSell),
      onSubmit: _canSubmit ? _submit : null,
      onKeyOverride: _quantityActive && type != null ? _onQuantityKey : null,
      keypadDecimal: _quantityActive && type != null && !type.usesNominal,
      bottomStatus: _status(context),
      children: [
        SegmentedButton<InvestmentSide>(
          key: const ValueKey('investment-side'),
          segments: [
            ButtonSegment(value: InvestmentSide.buy, label: Text(s.sideBuy), enabled: !_editing || buying),
            ButtonSegment(value: InvestmentSide.sell, label: Text(s.sideSell), enabled: !_editing || !buying),
          ],
          selected: {_side},
          showSelectedIcon: false,
          // Kontrol sekunder bernada tema, bukan pengalih jenis kedua (rupa B-97 §4.2).
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected) ? c.actionPrimary.withValues(alpha: 0.14) : c.surfaceCard,
            ),
            foregroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected) ? c.actionPrimary : c.textSecondary,
            ),
            side: WidgetStatePropertyAll(BorderSide(color: c.outlineSubtle)),
          ),
          onSelectionChanged: _editing ? null : (value) => _setSide(value.first),
        ),
        if (_editing) Text(s.sideLocked, style: ds.typography.bodySm.copyWith(color: c.textMuted)),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _quantityActive ? () => _activateQuantity(false) : null,
          child: RecordAmountField(
            controller: _amountController,
            kind: TransactionKind.transfer,
            onChanged: () => setState(() {}),
          ),
        ),
        // Arti nominal, menempel di bawah angkanya (poles B-97).
        Center(
          child: AnimatedSwitcher(
            duration: DsMotion.reduced(context) ? Duration.zero : const Duration(milliseconds: 200),
            child: DsPill(
              key: ValueKey(_side),
              icon: buying ? Symbols.shopping_bag_rounded : Symbols.savings_rounded,
              label: buying ? s.amountBuyCaption : s.amountSellCaption,
            ),
          ),
        ),
        DsFieldGroup(
          children: [
            if (widget.wallets.isEmpty)
              DsFieldRow(icon: Icons.account_balance_wallet_outlined, label: buying ? s.fromWallet : s.toWallet, title: s.noWallet)
            else
              WalletSelectField(
                useDs: true,
                label: buying ? s.fromWallet : s.toWallet,
                wallets: widget.wallets,
                selectedId: _walletId,
                onSelected: (id) => setState(() => _walletId = id),
                previewAmountSen: _amountSen,
                previewIsCredit: !buying,
              ),
            if (_newInstrument) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(s.newNameLabel, style: ds.typography.labelMd.copyWith(color: c.textMuted)),
                    const SizedBox(height: 6),
                    AppFormTextField(
                      key: const ValueKey('investment-new-name'),
                      controller: _newName,
                      hint: s.nameHint,
                      maxLength: 60,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    InstrumentTypeChips(
                      selected: _newType,
                      onSelected: (value) {
                        setState(() {
                          _newType = value;
                          _quantityText = '';
                        });
                        _afterInstrumentChosen();
                      },
                    ),
                    if (_newType case final t?) ...[
                      const SizedBox(height: 4),
                      Text(instrumentTypeHelp(t), style: ds.typography.bodySm.copyWith(color: c.textMuted)),
                    ],
                    if (widget.instruments.isNotEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: DsInlineAction(
                          label: s.pickExisting,
                          dense: true,
                          onPressed: () => setState(() => _newInstrument = false),
                        ),
                      ),
                  ],
                ),
              ),
            ] else if (!buying && _selectable.isEmpty)
              DsFieldRow(
                icon: Symbols.monitoring_rounded,
                label: t.assets.invest.instrumentLabel,
                title: s.noneToSell,
                trailing: DsInlineAction(label: s.switchToBuy, dense: true, onPressed: () => _setSide(InvestmentSide.buy)),
              )
            else
              DsFieldRow(
                key: const ValueKey('investment-instrument'),
                icon: type == null ? Symbols.monitoring_rounded : instrumentTypeIcon(type),
                leading: type == null ? null : instrumentTile(type, size: DsIconTileSize.sm),
                label: t.assets.invest.instrumentLabel,
                title: summary?.instrument.name ?? s.pickTitle,
                placeholder: summary == null,
                chevron: true,
                onTap: _pickInstrument,
              ),
            if (type != null)
              DsFieldRow(
                key: const ValueKey('investment-quantity'),
                icon: Symbols.tag_rounded,
                label: type.usesNominal ? s.nominal : s.quantity,
                title: type == InstrumentType.stock && (_quantity ?? 0) > 0
                    ? s.shares(n: formatShares(_quantity!))
                    : (type.usesNominal ? s.nominal : quantityUnit(type)),
                trailing: _QuantityBox(
                  text: _quantityText,
                  unit: type.usesNominal ? null : quantityUnit(type),
                  money: type.usesNominal,
                  active: _quantityActive,
                  semanticsLabel: type.usesNominal ? s.nominal : '${s.quantity}, ${quantityUnit(type)}',
                  onTap: () => _activateQuantity(true),
                ),
              ),
            RecordDateField(date: _date, kind: TransactionKind.transfer, onChanged: (date) => setState(() => _date = date)),
            RecordNoteField(controller: _noteController, kind: TransactionKind.transfer),
          ],
        ),
        ?_summary(context),
      ],
    );
  }

  /// Kartu Ringkasan (poles B-97): jumlah dimiliki, harga terakhir, saran
  /// nominal, dan perkiraan harga per satuan, masing-masing sebagai baris
  /// label–nilai dengan tanggal di bawah labelnya. Saran memakai valuasi
  /// terakhir (manual, atau nanti Google Sheet B-101); hanya saran, tidak
  /// disimpan.
  Widget? _summary(BuildContext context) {
    final s = t.assets.invest;
    final type = _type;
    if (type == null) return null;
    final summary = _summaryOf(_instrumentId);
    final valuation = _newInstrument ? null : summary?.valuation;
    final quantity = _quantity;
    final amount = _amountSen;
    final owned = _ownedOnDate;
    final suggested = valuation == null || quantity == null || quantity <= 0
        ? null
        : marketValueOf(type, quantity, valuation.unitPrice);
    final ds = context.ds;
    final c = ds.colors;
    final date = CycleMonthFormatter.formatDate(_date);
    final stats = <Widget>[
      if (!_newInstrument && owned != null)
        _SummaryStat(
          key: const ValueKey('investment-owned'),
          label: s.ownedLabel,
          value: formatQuantity(type, owned),
          // Jumlah dimiliki bergantung tanggal catatan, jadi tanggalnya ditulis.
          caption: date,
        ),
      if (valuation != null)
        _SummaryStat(
          key: const ValueKey('investment-last-price'),
          label: s.lastPrice,
          value: formatUnitPrice(type, valuation.unitPrice),
          caption: CycleMonthFormatter.formatDate(valuation.date),
        ),
    ];
    final estimate = quantity != null && quantity > 0 && amount != null && amount > 0
        ? formatUnitPrice(type, unitPriceFor(type, quantity, amount))
        : null;
    final showSuggestion = suggested != null && suggested > 0 && suggested != amount;
    final empty = stats.isEmpty && !showSuggestion && estimate == null;
    return AnimatedSize(
      duration: DsMotion.reduced(context) ? Duration.zero : const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: empty
          ? const SizedBox(width: double.infinity)
          : Column(
              key: const ValueKey('investment-summary'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DsSectionHeader(title: s.summaryHeading),
                DsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Keadaan instrumen: dua kotak sama lebar.
                      if (stats.isNotEmpty)
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final (i, stat) in stats.indexed) ...[
                                if (i > 0) const SizedBox(width: 8),
                                Expanded(child: stat),
                              ],
                            ],
                          ),
                        ),
                      // 2. Saran nominal dari harga terakhir.
                      if (showSuggestion) ...[
                        if (stats.isNotEmpty) const SizedBox(height: 10),
                        DecoratedBox(
                          key: const ValueKey('investment-price-suggestion'),
                          decoration: BoxDecoration(
                            color: c.actionPrimary.withValues(alpha: 0.08),
                            borderRadius: DsRadius.mdAll,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(s.suggestTotal, style: ds.typography.labelMd.copyWith(color: c.textSecondary)),
                                      const SizedBox(height: 2),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          AppMoneyFormatter.format(suggested),
                                          style: ds.typography.titleMd.copyWith(
                                            fontFeatures: const [FontFeature.tabularFigures()],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(s.suggestCaption, style: ds.typography.labelMd.copyWith(color: c.textMuted)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                DsButton.secondary(
                                  key: const ValueKey('investment-use-suggestion'),
                                  label: s.use,
                                  onPressed: () => setState(() {
                                    _amountController.text = formatMoneyInput(suggested);
                                    _quantityActive = false;
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      // 3. Perkiraan harga per satuan dari isian.
                      if (estimate != null) ...[
                        if (stats.isNotEmpty || showSuggestion) const SizedBox(height: 10),
                        Row(
                          key: const ValueKey('investment-est-price'),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.estPrice, style: ds.typography.bodySm.copyWith(color: c.textSecondary)),
                                  Text(
                                    _side == InvestmentSide.buy ? s.estPriceBuyCaption : s.estPriceSellCaption,
                                    style: ds.typography.labelMd.copyWith(color: c.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '≈ $estimate',
                              style: ds.typography.bodyMd.copyWith(
                                fontWeight: FontWeight.w700,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  /// Status bawah: hanya galat jual melebihi yang dimiliki, supaya selalu
  /// terlihat di atas tombol simpan.
  Widget? _status(BuildContext context) {
    final type = _type;
    if (type == null || !_overSell) return null;
    final ds = context.ds;
    final s = t.assets.invest;
    return DecoratedBox(
      key: const ValueKey('investment-oversell'),
      decoration: BoxDecoration(color: ds.colors.errorContainer, borderRadius: DsRadius.lgAll),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Icon(Icons.error_outline, size: 18, color: ds.colors.onErrorContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                s.statusOverSell(date: CycleMonthFormatter.formatDate(_date), qty: formatQuantity(type, _ownedOnDate!)),
                style: ds.typography.bodySm.copyWith(color: ds.colors.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kotak kecil Ringkasan: label, angka besar, keterangan (tanggal atau
/// lembar). Angka mengecil sendiri bila tidak muat, tidak pernah terpotong.
class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.label, required this.value, required this.caption, super.key});

  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    return DecoratedBox(
      decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: DsRadius.mdAll),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: ds.typography.labelMd.copyWith(color: c.textSecondary)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: ds.typography.titleMd.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ),
            const SizedBox(height: 2),
            Text(caption, style: ds.typography.labelMd.copyWith(color: c.textMuted)),
          ],
        ),
      ),
    );
  }
}

/// Kotak Jumlah yang diisi papan angka Catat (rupa B-97 §4.4), pola kotak
/// persen mode bagi.
class _QuantityBox extends StatelessWidget {
  const _QuantityBox({
    required this.text,
    required this.unit,
    required this.money,
    required this.active,
    required this.semanticsLabel,
    required this.onTap,
  });

  final String text;
  final String? unit;
  final bool money;
  final bool active;
  final String semanticsLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final empty = text.isEmpty;
    final shown = money ? AppMoneyFormatter.format(parseMoneyInput(text) ?? 0) : (empty ? '0' : text);
    return Semantics(
      button: true,
      selected: active,
      label: semanticsLabel,
      value: unit == null ? shown : '$shown $unit',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: DsMotion.reduced(context) ? Duration.zero : const Duration(milliseconds: 150),
          constraints: const BoxConstraints(minWidth: 120, minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: active ? c.surfaceCard : c.surfaceSunken,
            borderRadius: DsRadius.mdAll,
            border: Border.all(color: active ? c.actionPrimary : c.outlineSubtle, width: active ? 2 : 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(shown, style: ds.typography.titleMd.copyWith(fontSize: 16, color: empty ? c.textMuted : null)),
              if (unit case final u?) ...[
                const SizedBox(width: 4),
                Text(u, style: ds.typography.bodySm.copyWith(color: c.textMuted)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
