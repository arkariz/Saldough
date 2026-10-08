import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/budget/domain/entities/budget_item.dart';
import 'package:saldough/features/budget/domain/entities/budget_template.dart';
import 'package:saldough/features/budget/presentation/widgets/budget_form_sheet.dart';
import 'package:saldough/features/budget/presentation/widgets/budget_item_form_sheet.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Hasil [BudgetTemplateFormSheet]; `null` berarti dibatalkan.
sealed class BudgetTemplateFormResult {
  /// Membuat [BudgetTemplateFormResult].
  const BudgetTemplateFormResult();
}

/// Formulir disimpan.
final class BudgetTemplateFormSaved extends BudgetTemplateFormResult {
  /// Membuat [BudgetTemplateFormSaved].
  const BudgetTemplateFormSaved({required this.name, required this.items, required this.isEnabled});

  /// Nama template.
  final String name;

  /// Pos bawaan, minimal satu.
  final List<BudgetItem> items;

  /// Template ditawarkan saat membuat anggaran.
  final bool isEnabled;
}

/// Pemakai menekan hapus dan sudah mengonfirmasi.
final class BudgetTemplateFormDeleted extends BudgetTemplateFormResult {
  /// Membuat [BudgetTemplateFormDeleted].
  const BudgetTemplateFormDeleted();
}

/// Formulir buat dan sunting template anggaran (T-7.2, FR-BUD-005), layar
/// penuh lewat `showFullScreenSheet`. Bentuknya sama dengan formulir anggaran
/// tanpa dompet dan periode — keduanya dipilih saat template dipakai.
///
/// ⚠ Menyimpan template tidak pernah mengubah saldo dompet mana pun.
class BudgetTemplateFormSheet extends StatefulWidget {
  /// Membuat [BudgetTemplateFormSheet]. [initial] `null` = template baru.
  const BudgetTemplateFormSheet({required this.wallets, this.initial, super.key});

  /// Seluruh dompet — pilihan dan nama dompet tujuan pos transfer.
  final List<Wallet> wallets;

  /// Template yang disunting.
  final BudgetTemplate? initial;

  @override
  State<BudgetTemplateFormSheet> createState() => _BudgetTemplateFormSheetState();
}

class _BudgetTemplateFormSheetState extends State<BudgetTemplateFormSheet> {
  final _name = TextEditingController();
  List<BudgetItem> _items = [];
  bool _isEnabled = true;

  bool get _editing => widget.initial != null;

  bool get _canSave => _name.text.trim().isNotEmpty && _items.isNotEmpty;

  @override
  void initState() {
    super.initState();
    final template = widget.initial;
    if (template == null) return;
    _name.text = template.name;
    _items = [...template.items];
    _isEnabled = template.isEnabled;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String? _walletName(String? id) => widget.wallets.where((w) => w.id == id).firstOrNull?.name;

  /// Pilihan dompet tujuan: dompet aktif, ditambah tujuan pos yang sedang
  /// disunting walau sudah nonaktif. Belum ada dompet anggaran yang perlu
  /// dikecualikan — itu diperiksa saat template dipakai.
  List<Wallet> _targetWalletsFor(BudgetItem? item) => [
    for (final wallet in widget.wallets)
      if (wallet.isActive || wallet.id == item?.targetWalletId) wallet,
  ];

  Future<void> _editItem([int? index]) async {
    final item = index == null ? null : _items[index];
    final result = await showFullScreenSheet<BudgetItemFormResult>(
      context,
      builder: (_) => BudgetItemFormSheet(initial: item, targetWallets: _targetWalletsFor(item)),
    );
    if (!mounted) return;
    setState(() {
      switch (result) {
        case BudgetItemFormSaved(item: final saved):
          if (index == null) {
            _items = [..._items, saved];
          } else {
            _items = [..._items]..[index] = saved;
          }
        case BudgetItemFormDeleted():
          if (index != null) _items = [..._items]..removeAt(index);
        case null:
          break;
      }
    });
  }

  void _save() {
    if (!_canSave) return;
    Navigator.of(
      context,
    ).pop(BudgetTemplateFormSaved(name: _name.text.trim(), items: _items, isEnabled: _isEnabled));
  }

  Future<void> _delete() async {
    final template = widget.initial;
    if (template == null) return;
    final confirmed = await showConfirmDelete(
      context,
      title: t.budget.templateDeleteConfirmTitle,
      message: t.budget.templateDeleteConfirmMessage(name: template.name),
    );
    if (confirmed && mounted) Navigator.of(context).pop(const BudgetTemplateFormDeleted());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final total = _items.fold(0, (sum, item) => sum + item.plannedAmount);
    return SizedBox.expand(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.space4, AppSpacing.space4, AppSpacing.space4, AppSpacing.space6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppFormHeader(
                stepLabel: t.budget.templateStepLabel,
                title: _editing ? t.budget.templateEditTitle : t.budget.templateAddTitle,
              ),
              const SizedBox(height: AppSpacing.space4),
              TransactionSlab(
                color: colors.surface2,
                child: Text(t.budget.templateRuleBody, style: textTheme.bodySmall?.copyWith(color: colors.ink2)),
              ),
              const SizedBox(height: AppSpacing.space4),
              AppSectionLabel(t.budget.templateNameLabel, hint: t.budget.requiredHint),
              const SizedBox(height: AppSpacing.space1),
              AppFormTextField(
                controller: _name,
                hint: t.budget.templateNameHint,
                autofocus: !_editing,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.space4),
              AppSectionLabel(t.budget.itemsLabel, hint: t.budget.requiredHint),
              const SizedBox(height: 2),
              Text(t.budget.itemsHelp, style: textTheme.bodySmall?.copyWith(color: colors.ink2)),
              const SizedBox(height: AppSpacing.space1),
              for (var i = 0; i < _items.length; i++) ...[
                BudgetItemRow(
                  item: _items[i],
                  targetWalletName: _walletName(_items[i].targetWalletId),
                  onTap: () => _editItem(i),
                ),
                const SizedBox(height: AppSpacing.space1),
              ],
              AppButton.secondary(label: t.budget.addItemAction, onPressed: _editItem),
              const SizedBox(height: AppSpacing.space4),
              TransactionSlab(
                color: colors.surface2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.budget.templateTotalLabel.toUpperCase(),
                      style: transactionLabelStyle(context, color: colors.ink2),
                    ),
                    FitStart(
                      child: Text(
                        AppMoneyFormatter.format(total),
                        style: context.numberStyles.amountHero.copyWith(color: colors.ink),
                      ),
                    ),
                    if (_items.isEmpty)
                      Text(t.budget.itemsRequiredHint, style: textTheme.bodySmall?.copyWith(color: colors.warning)),
                  ],
                ),
              ),
              if (_editing) ...[
                const SizedBox(height: AppSpacing.space4),
                TransactionSlab(
                  radius: 4,
                  shadow: 2,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.budget.templateEnabledLabel,
                              style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              t.budget.templateEnabledHelp,
                              style: textTheme.bodySmall?.copyWith(color: colors.ink2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      Switch(
                        value: _isEnabled,
                        activeThumbColor: colors.onBrand,
                        activeTrackColor: colors.brand,
                        onChanged: (value) => setState(() => _isEnabled = value),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.space6),
              AppButton(
                label: _editing ? t.transaction.saveChangesAction : t.budget.templateSaveAction,
                onPressed: _canSave ? _save : null,
              ),
              if (_editing) ...[
                const SizedBox(height: AppSpacing.space4),
                AppButton.danger(
                  label: t.budget.templateDeleteAction,
                  onPressed: _delete,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
