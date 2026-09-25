import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/budget/domain/entities/budget_item.dart';
import 'package:saldough/features/budget/domain/entities/budget_item_kind.dart';
import 'package:saldough/features/budget/presentation/widgets/budget_form_fields.dart';
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
      _unitPrice.text = BudgetMoneyField.initialText(item.unitPrice);
    } else {
      _amount.text = BudgetMoneyField.initialText(item.enteredAmount);
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
    if (_isTransfer || !_itemized) return BudgetMoneyField.senOf(_amount);
    final quantity = BudgetQuantityField.valueOf(_quantity);
    final price = BudgetMoneyField.senOf(_unitPrice);
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
            enteredAmount: BudgetMoneyField.senOf(_amount),
            kind: BudgetItemKind.transfer,
            targetWalletId: _targetWalletId,
          )
        : _itemized
        ? BudgetItem(
            id: id,
            name: _name.text.trim(),
            quantity: BudgetQuantityField.valueOf(_quantity),
            unitPrice: BudgetMoneyField.senOf(_unitPrice),
          )
        : BudgetItem(id: id, name: _name.text.trim(), enteredAmount: BudgetMoneyField.senOf(_amount));
    Navigator.of(context).pop(BudgetItemFormSaved(item));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final editing = widget.initial != null;
    final total = _total;
    void refresh(String _) => setState(() {});
    return SizedBox.expand(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BudgetFormHeader(
                stepLabel: t.budget.itemsLabel,
                title: editing ? t.budget.itemEditTitle : t.budget.itemAddTitle,
              ),
              const SizedBox(height: AppSpacing.md),
              AppSectionLabel(t.budget.itemKindLabel),
              const SizedBox(height: AppSpacing.xs),
              IgnorePointer(
                ignoring: widget.kindLocked,
                child: Opacity(
                  opacity: widget.kindLocked ? 0.6 : 1,
                  child: BudgetSegmented<BudgetItemKind>(
                    options: [
                      (BudgetItemKind.expense, t.budget.itemKindExpense),
                      (BudgetItemKind.transfer, t.budget.itemKindTransfer),
                    ],
                    selected: _kind,
                    onChanged: (value) => setState(() => _kind = value),
                  ),
                ),
              ),
              if (widget.kindLocked) ...[
                const SizedBox(height: 4),
                Text(
                  t.budget.itemKindLockedHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textMuted),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              AppSectionLabel(t.budget.itemNameLabel, hint: t.budget.requiredHint),
              const SizedBox(height: AppSpacing.xs),
              BudgetTextField(controller: _name, hint: t.budget.itemNameHint, autofocus: !editing, onChanged: refresh),
              const SizedBox(height: AppSpacing.md),
              if (_isTransfer) ...[
                AppSectionLabel(t.budget.itemTargetWalletLabel, hint: t.budget.requiredHint),
                const SizedBox(height: 2),
                Text(
                  t.budget.itemTargetWalletHelp,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textMuted),
                ),
                const SizedBox(height: AppSpacing.xs),
                if (widget.targetWallets.isEmpty)
                  Text(t.budget.itemNoTargetWallet, style: TextStyle(color: colors.pending))
                else
                  AppMenuSelectButton<String>(
                    icon: IconKey.transfer,
                    label: widget.targetWallets.where((w) => w.id == _targetWalletId).firstOrNull?.name ??
                        t.budget.itemTargetWalletLabel,
                    isPlaceholder: !widget.targetWallets.any((w) => w.id == _targetWalletId),
                    wrapLabel: true,
                    options: [
                      for (final wallet in widget.targetWallets)
                        (value: wallet.id, label: wallet.name, icon: walletIconKey(wallet.iconKey)),
                    ],
                    onSelected: (id) => setState(() => _targetWalletId = id),
                  ),
                const SizedBox(height: AppSpacing.md),
              ] else ...[
                BudgetSegmented<bool>(
                  options: [(false, t.budget.itemModeAmount), (true, t.budget.itemModeItemized)],
                  selected: _itemized,
                  onChanged: (value) => setState(() => _itemized = value),
                ),
                const SizedBox(height: AppSpacing.md),
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
                          const SizedBox(height: AppSpacing.xs),
                          BudgetQuantityField(controller: _quantity, onChanged: refresh),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppSectionLabel(t.budget.itemUnitPriceLabel),
                          const SizedBox(height: AppSpacing.xs),
                          BudgetMoneyField(controller: _unitPrice, onChanged: refresh),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                TransactionSlab(
                  color: colors.surfaceLow,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.budget.itemTotalLabel.toUpperCase(),
                          style: transactionLabelStyle(context, color: colors.textMuted),
                        ),
                      ),
                      Text(
                        total == null ? '—' : AppMoneyFormatter.format(total),
                        style: PixelTypography.tabularMono(context, fontSize: 16, color: colors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                AppSectionLabel(t.budget.itemAmountLabel),
                const SizedBox(height: AppSpacing.xs),
                BudgetMoneyField(controller: _amount, onChanged: refresh, large: true),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppButton(label: t.budget.itemSaveAction, onPressed: _canSave ? _save : null),
              if (editing) ...[
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: t.budget.itemDeleteAction,
                  color: colors.expense,
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
