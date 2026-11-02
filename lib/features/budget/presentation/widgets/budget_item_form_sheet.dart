import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/budget/domain/entities/budget_item.dart';
import 'package:saldough/features/budget/domain/entities/budget_item_kind.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Hasil [BudgetItemFormSheet]; `null` berarti dibatalkan.
sealed class BudgetItemFormResult {
  /// Membuat [BudgetItemFormResult].
  const BudgetItemFormResult();
}

/// Pos disimpan.
final class BudgetItemFormSaved extends BudgetItemFormResult {
  /// Membuat [BudgetItemFormSaved].
  const BudgetItemFormSaved(this.item);

  /// Pos hasil formulir.
  final BudgetItem item;
}

/// Pos dihapus dari anggaran.
final class BudgetItemFormDeleted extends BudgetItemFormResult {
  /// Membuat [BudgetItemFormDeleted].
  const BudgetItemFormDeleted();
}

/// Formulir satu pos anggaran (FR-BUD-002, ADR-018): jenis, nama, lalu
/// nominal rencana.
///
/// - Pos **pengeluaran**: nominal diketik langsung ATAU dirinci jadi jumlah ×
///   harga satuan untuk pos berupa daftar belanja.
/// - Pos **transfer**: nominal selalu diketik langsung, ditambah dompet
///   tujuan yang wajib.
///
/// Jenis dikunci ([kindLocked]) kalau pos sudah punya transaksi tertaut.
/// Perubahannya baru tersimpan saat anggarannya disimpan.
class BudgetItemFormSheet extends StatefulWidget {
  /// Membuat [BudgetItemFormSheet]. [initial] `null` = pos baru.
  const BudgetItemFormSheet({required this.targetWallets, this.initial, this.kindLocked = false, super.key});

  /// Pos yang disunting.
  final BudgetItem? initial;

  /// Pilihan dompet tujuan pos transfer — pemanggil sudah mengecualikan
  /// dompet anggaran itu sendiri.
  final List<Wallet> targetWallets;

  /// Jenis pos tidak bisa diganti (sudah punya transaksi tertaut).
  final bool kindLocked;

  @override
  State<BudgetItemFormSheet> createState() => _BudgetItemFormSheetState();
}

class _BudgetItemFormSheetState extends State<BudgetItemFormSheet> {
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _quantity = TextEditingController();
  final _unitPrice = TextEditingController();
  bool _itemized = false;
  BudgetItemKind _kind = BudgetItemKind.expense;
  String? _targetWalletId;

  bool get _isTransfer => _kind == BudgetItemKind.transfer;

  @override
  void initState() {
    super.initState();
    final item = widget.initial;
    if (item == null) return;
    _name.text = item.name;
    _kind = item.kind;
    _targetWalletId = item.targetWalletId;
    _itemized = item.isItemized;
    if (item.isItemized) {
      _quantity.text = '${item.quantity}';
      _unitPrice.text = AppFormMoneyField.initialText(item.unitPrice);
    } else {
      _amount.text = AppFormMoneyField.initialText(item.enteredAmount);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _quantity.dispose();
    _unitPrice.dispose();
    super.dispose();
  }

  /// Nominal rencana pos saat ini dalam sen, atau `null` kalau belum lengkap.
  int? get _total {
    if (_isTransfer || !_itemized) return AppFormMoneyField.senOf(_amount);
    final quantity = AppFormQuantityField.valueOf(_quantity);
    final price = AppFormMoneyField.senOf(_unitPrice);
    return quantity == null || price == null ? null : quantity * price;
  }

  bool get _canSave =>
      _name.text.trim().isNotEmpty &&
      _total != null &&
      (!_isTransfer || widget.targetWallets.any((w) => w.id == _targetWalletId));

  void _save() {
    if (!_canSave) return;
    final id = widget.initial?.id ?? DateTime.now().microsecondsSinceEpoch.toString();
    final item = _isTransfer
        ? BudgetItem(
            id: id,
            name: _name.text.trim(),
            enteredAmount: AppFormMoneyField.senOf(_amount),
            kind: BudgetItemKind.transfer,
            targetWalletId: _targetWalletId,
          )
        : _itemized
        ? BudgetItem(
            id: id,
            name: _name.text.trim(),
            quantity: AppFormQuantityField.valueOf(_quantity),
            unitPrice: AppFormMoneyField.senOf(_unitPrice),
          )
        : BudgetItem(id: id, name: _name.text.trim(), enteredAmount: AppFormMoneyField.senOf(_amount));
    Navigator.of(context).pop(BudgetItemFormSaved(item));
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final editing = widget.initial != null;
    final total = _total;
    void refresh(String _) => setState(() {});
    Widget hint(String text) => Text(text, style: ds.typography.bodySm.copyWith(color: c.textSecondary));
    final selectedTarget = widget.targetWallets.where((w) => w.id == _targetWalletId).firstOrNull;
    return SizedBox.expand(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppFormHeader(title: editing ? t.budget.itemEditTitle : t.budget.itemAddTitle),
              const SizedBox(height: 16),
              AppSectionLabel(t.budget.itemKindLabel),
              const SizedBox(height: 4),
              IgnorePointer(
                ignoring: widget.kindLocked,
                child: Opacity(
                  opacity: widget.kindLocked ? 0.6 : 1,
                  child: DsSegmentedPill<BudgetItemKind>(
                    segments: [
                      DsSegment(
                        value: BudgetItemKind.expense,
                        label: t.budget.itemKindExpense,
                        asset: ClayIcons.expenseArrow,
                      ),
                      DsSegment(
                        value: BudgetItemKind.transfer,
                        label: t.budget.itemKindTransfer,
                        asset: ClayIcons.transfer,
                      ),
                    ],
                    selected: _kind,
                    onChanged: (value) => setState(() => _kind = value),
                  ),
                ),
              ),
              if (widget.kindLocked) ...[const SizedBox(height: 4), hint(t.budget.itemKindLockedHint)],
              const SizedBox(height: 16),
              AppSectionLabel(t.budget.itemNameLabel, hint: t.budget.requiredHint),
              const SizedBox(height: 4),
              AppFormTextField(controller: _name, hint: t.budget.itemNameHint, autofocus: !editing, onChanged: refresh),
              const SizedBox(height: 16),
              if (_isTransfer) ...[
                AppSectionLabel(t.budget.itemTargetWalletLabel, hint: t.budget.requiredHint),
                const SizedBox(height: 2),
                hint(t.budget.itemTargetWalletHelp),
                const SizedBox(height: 4),
                if (widget.targetWallets.isEmpty)
                  Text(t.budget.itemNoTargetWallet, style: ds.typography.bodySm.copyWith(color: c.warning))
                else
                  DsFieldGroup(
                    children: [
                      DsSelectRow<String>(
                        icon: Icons.swap_horiz,
                        leading: DsIconTile.asset(
                          asset: selectedTarget == null
                              ? ClayIcons.walletNav
                              : ClayIcons.forIcon(walletIconKey(selectedTarget.iconKey)) ?? ClayIcons.walletNav,
                          size: DsIconTileSize.sm,
                        ),
                        label: t.budget.itemTargetWalletLabel,
                        title: selectedTarget?.name ?? t.budget.itemTargetWalletLabel,
                        placeholder: selectedTarget == null,
                        options: [
                          for (final wallet in widget.targetWallets)
                            DsMenuOption(
                              value: wallet.id,
                              label: wallet.name,
                              leading: SvgPicture.asset(
                                ClayIcons.forIcon(walletIconKey(wallet.iconKey)) ?? ClayIcons.walletNav,
                              ),
                            ),
                        ],
                        onSelected: (id) => setState(() => _targetWalletId = id),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
              ] else ...[
                DsSegmentedPill<bool>(
                  segments: [
                    DsSegment(value: false, label: t.budget.itemModeAmount),
                    DsSegment(value: true, label: t.budget.itemModeItemized),
                  ],
                  selected: _itemized,
                  onChanged: (value) => setState(() => _itemized = value),
                ),
                const SizedBox(height: 16),
              ],
              if (!_isTransfer && _itemized) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppSectionLabel(t.budget.itemQuantityLabel),
                          const SizedBox(height: 4),
                          AppFormQuantityField(controller: _quantity, onChanged: refresh),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppSectionLabel(t.budget.itemUnitPriceLabel),
                          const SizedBox(height: 4),
                          AppFormMoneyField(controller: _unitPrice, onChanged: refresh),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DecoratedBox(
                  decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: DsRadius.mdAll),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            t.budget.itemTotalLabel,
                            style: ds.typography.labelMd.copyWith(color: c.textSecondary),
                          ),
                        ),
                        Text(total == null ? '—' : AppMoneyFormatter.format(total), style: ds.typography.amount),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                AppSectionLabel(t.budget.itemAmountLabel),
                const SizedBox(height: 4),
                AppFormMoneyField(controller: _amount, onChanged: refresh, large: true),
              ],
              const SizedBox(height: 24),
              DsButton(label: t.budget.itemSaveAction, expand: true, onPressed: _canSave ? _save : null),
              if (editing) ...[
                const SizedBox(height: 12),
                DsButton.danger(
                  label: t.budget.itemDeleteAction,
                  expand: true,
                  onPressed: () => Navigator.of(context).pop(const BudgetItemFormDeleted()),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
