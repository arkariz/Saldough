import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/grocery/domain/entities/grocery_item.dart';
import 'package:saldough/features/grocery/presentation/bloc/grocery_bloc.dart';
import 'package:saldough/features/grocery/presentation/bloc/grocery_state.dart';
import 'package:state_management/state_management.dart';

/// Layar rencana belanja mingguan dan bulanan — FR-GROC-001 sampai
/// FR-GROC-003.
class GroceryPage extends StatelessWidget {
  /// Membuat [GroceryPage].
  const GroceryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t.grocery.pageTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.credit_card),
            tooltip: t.grocery.cardEntryPointLabel,
            onPressed: () => context.read<GroceryBloc>().add(const CardEntryPointTapped()),
          ),
        ],
      ),
      body: EffectListener<GroceryBloc, GroceryState>(
        child: BlocBuilder<GroceryBloc, GroceryState>(
          builder: (context, state) {
            if (state.isLoading) return const Center(child: CircularProgressIndicator());
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                AppCard(
                  child: Row(
                    mainAxisAlignment: .spaceBetween,
                    children: [
                      Text(t.grocery.rollUpTotal, style: Theme.of(context).textTheme.titleMedium),
                      AppMoneyText(sen: state.rollUpAmount, style: Theme.of(context).textTheme.headlineSmall),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _WeeksPerMonthField(weeksPerMonth: state.plan.weeksPerMonth),
                const SizedBox(height: AppSpacing.lg),
                _ItemSection(title: t.grocery.weeklyTitle, items: state.plan.weeklyItems, isWeekly: true),
                const SizedBox(height: AppSpacing.lg),
                _ItemSection(title: t.grocery.monthlyTitle, items: state.plan.monthlyItems, isWeekly: false),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: t.grocery.cardEntryPointLabel,
                  icon: Icons.credit_card,
                  onPressed: () => context.read<GroceryBloc>().add(const CardEntryPointTapped()),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WeeksPerMonthField extends StatefulWidget {
  const _WeeksPerMonthField({required this.weeksPerMonth});

  final int weeksPerMonth;

  @override
  State<_WeeksPerMonthField> createState() => _WeeksPerMonthFieldState();
}

class _WeeksPerMonthFieldState extends State<_WeeksPerMonthField> {
  late final _controller = TextEditingController(text: widget.weeksPerMonth.toString());
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Menulis [value] ke bloc kalau valid. Dipanggil baik lewat debounce
  /// (mengetik lalu berhenti) maupun `onSubmitted` (menekan enter) — dua
  /// jalur komit yang sama, supaya pengali tersimpan walau pemilik cuma
  /// scroll menjauh tanpa menekan enter (laporan pemilik, UX-04: sebelumnya
  /// field menampilkan nilai baru tapi yang tersimpan masih nilai lama).
  void _commit(String value) {
    final weeks = int.tryParse(value);
    if (weeks != null && weeks > 0) {
      context.read<GroceryBloc>().add(WeeksPerMonthChanged(weeks));
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: .number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: t.grocery.weeksPerMonthFieldHint),
      onChanged: (value) {
        _debounce?.cancel();
        _debounce = Timer(AppDurations.debounce, () => _commit(value));
      },
      onSubmitted: (value) {
        _debounce?.cancel();
        _commit(value);
      },
    );
  }
}

class _ItemSection extends StatelessWidget {
  const _ItemSection({required this.title, required this.items, required this.isWeekly});

  final String title;
  final List<GroceryItem> items;
  final bool isWeekly;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<GroceryBloc>();
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        if (items.isEmpty) Text(t.grocery.emptyItems),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppCard(
              child: InkWell(
                onTap: () async {
                  final result = await _GroceryItemEditSheet.show(context, initial: item);
                  if (result != null) {
                    bloc.add(GroceryItemSaved(
                      isWeekly: isWeekly,
                      id: item.id,
                      name: result.name,
                      quantity: result.quantity,
                      unitPrice: result.unitPrice,
                      amountOverride: result.amountOverride,
                    ));
                  }
                },
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: .start,
                        children: [
                          Text(item.name),
                          Text(
                            '${item.quantity} × ${AppMoneyFormatter.format(item.unitPrice)}'
                            '${item.isOverridden ? ' (${t.grocery.overriddenBadge})' : ''}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    AppMoneyText(sen: item.amount, style: Theme.of(context).textTheme.titleMedium),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        final confirmed = await showConfirmDelete(
                          context,
                          title: t.grocery.confirmDeleteItemTitle(name: item.name),
                          message: t.grocery.confirmDeleteItemMessage,
                        );
                        if (confirmed) {
                          bloc.add(GroceryItemRemoved(isWeekly: isWeekly, id: item.id));
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: t.grocery.addItemButton,
          icon: Icons.add,
          onPressed: () async {
            final result = await _GroceryItemEditSheet.show(context);
            if (result != null) {
              bloc.add(GroceryItemSaved(
                isWeekly: isWeekly,
                name: result.name,
                quantity: result.quantity,
                unitPrice: result.unitPrice,
                amountOverride: result.amountOverride,
              ));
            }
          },
        ),
      ],
    );
  }
}

class _GroceryItemEditSheet extends StatefulWidget {
  const _GroceryItemEditSheet({this.initial});

  final GroceryItem? initial;

  static Future<GroceryItem?> show(BuildContext context, {GroceryItem? initial}) {
    return showModalBottomSheet<GroceryItem>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _GroceryItemEditSheet(initial: initial),
    );
  }

  @override
  State<_GroceryItemEditSheet> createState() => _GroceryItemEditSheetState();
}

class _GroceryItemEditSheetState extends State<_GroceryItemEditSheet> {
  late final _nameController = TextEditingController(text: widget.initial?.name ?? '');
  late final _quantityController = TextEditingController(text: (widget.initial?.quantity ?? 1).toString());
  late final _unitPriceController = TextEditingController(
    text: widget.initial == null ? '' : (widget.initial!.unitPrice ~/ 100).toString(),
  );
  late final _overrideController = TextEditingController(
    text: widget.initial?.amountOverride == null ? '' : (widget.initial!.amountOverride! ~/ 100).toString(),
  );
  late bool _isOverridden = widget.initial?.isOverridden ?? false;

  /// Gerbang tombol Simpan -- dinonaktifkan (bukan diam-diam menolak submit)
  /// saat nama/jumlah/harga satuan belum valid (UX-03). Sengaja tidak ikut
  /// mensyaratkan `_overrideController` terisi saat [_isOverridden] aktif --
  /// `_submit()` sendiri sudah memperlakukan override kosong sebagai "tidak
  /// ditimpa", bukan gagal simpan, jadi gerbang ini tidak mengubah perilaku
  /// itu.
  bool get _canSubmit {
    final name = _nameController.text.trim();
    final quantity = int.tryParse(_quantityController.text.trim());
    final unitPrice = int.tryParse(_unitPriceController.text.trim());
    return name.isNotEmpty && quantity != null && unitPrice != null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _overrideController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final quantity = int.tryParse(_quantityController.text.trim());
    final unitPrice = int.tryParse(_unitPriceController.text.trim());
    if (name.isEmpty || quantity == null || unitPrice == null) return;
    final override = _isOverridden ? int.tryParse(_overrideController.text.trim()) : null;
    Navigator.of(context).pop(GroceryItem(
      id: widget.initial?.id ?? '',
      name: name,
      quantity: quantity,
      unitPrice: unitPrice * 100,
      amountOverride: override == null ? null : override * 100,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: AppSpacing.md + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          children: [
            Text(
              widget.initial == null ? t.grocery.addItemButton : t.grocery.editItemTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(labelText: t.grocery.itemNameFieldHint),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: .number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(labelText: t.grocery.quantityFieldHint),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: _unitPriceController,
                    keyboardType: .number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(labelText: t.grocery.unitPriceFieldHint),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(t.grocery.overridePriceLabel),
              value: _isOverridden,
              onChanged: (value) => setState(() => _isOverridden = value),
            ),
            if (_isOverridden)
              TextField(
                controller: _overrideController,
                keyboardType: .number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(labelText: t.grocery.overrideAmountFieldHint),
              ),
            const SizedBox(height: AppSpacing.md),
            AppButton(label: t.common.save, onPressed: _canSubmit ? _submit : null),
          ],
        ),
      ),
    );
  }
}
