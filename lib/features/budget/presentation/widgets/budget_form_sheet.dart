import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/core/utils/formatters/rupiah_input.dart';
import 'package:saldough/features/budget/domain/entities/budget.dart';
import 'package:saldough/features/budget/domain/entities/budget_item.dart';
import 'package:saldough/features/budget/domain/entities/budget_period.dart';
import 'package:saldough/features/budget/presentation/budget_display.dart';
import 'package:saldough/features/budget/presentation/widgets/budget_form_fields.dart';
import 'package:saldough/features/budget/presentation/widgets/budget_item_form_sheet.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Hasil [BudgetFormSheet]; `null` berarti dibatalkan.
sealed class BudgetFormResult {
  /// Membuat [BudgetFormResult].
  const BudgetFormResult();
}

/// Formulir disimpan.
final class BudgetFormSaved extends BudgetFormResult {
  /// Membuat [BudgetFormSaved].
  const BudgetFormSaved({
    required this.name,
    required this.walletId,
    required this.period,
    required this.startDate,
    required this.plannedAmount,
    required this.items,
  });

  /// Nama anggaran.
  final String name;

  /// Dompet sumber.
  final String walletId;

  /// Periode.
  final BudgetPeriod period;

  /// Awal periode.
  final DateTime startDate;

  /// Nominal rencana, sen.
  final int plannedAmount;

  /// Pos-pos.
  final List<BudgetItem> items;
}

/// Pemakai menekan arsipkan / aktifkan kembali.
final class BudgetFormArchiveToggled extends BudgetFormResult {
  /// Membuat [BudgetFormArchiveToggled].
  const BudgetFormArchiveToggled();
}

/// Pemakai menekan hapus dan sudah mengonfirmasi.
final class BudgetFormDeleted extends BudgetFormResult {
  /// Membuat [BudgetFormDeleted].
  const BudgetFormDeleted();
}

/// Formulir buat dan sunting anggaran (FR-BUD-001/002, T-4.6), layar penuh
/// lewat `showFullScreenSheet`, mengikuti rujukan `pixel_kas_tambah_anggaran`.
///
/// ⚠ Bagian rujukan yang sengaja tidak dibangun: periode "Kustom" (domain
/// hanya mingguan/bulanan), jenis pos "rencana transfer" (pos tidak punya
/// jenis — pengeluaran maupun transfer boleh ditautkan ke pos mana pun),
/// dan "buat dari template" (FR-BUD-005, Fase 7).
class BudgetFormSheet extends StatefulWidget {
  /// Membuat [BudgetFormSheet]. [initial] `null` = anggaran baru.
  const BudgetFormSheet({required this.wallets, this.initial, super.key});

  /// Dompet yang bisa dipilih — pemanggil menyertakan dompet milik
  /// [initial] walau sudah nonaktif, supaya pilihannya tidak hilang.
  final List<Wallet> wallets;

  /// Anggaran yang disunting.
  final Budget? initial;

  @override
  State<BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends State<BudgetFormSheet> {
  final _name = TextEditingController();
  final _planned = TextEditingController();
  String? _walletId;
  BudgetPeriod _period = BudgetPeriod.monthly;
  late DateTime _startDate;
  List<BudgetItem> _items = [];

  bool get _editing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month);
    final budget = widget.initial;
    if (budget == null) {
      if (widget.wallets.length == 1) _walletId = widget.wallets.single.id;
      return;
    }
    _name.text = budget.name;
    _planned.text = BudgetMoneyField.initialText(budget.plannedAmount);
    _walletId = budget.walletId;
    _period = budget.period;
    _startDate = budget.startDate;
    _items = [...budget.items];
  }

  @override
  void dispose() {
    _name.dispose();
    _planned.dispose();
    super.dispose();
  }

  int get _itemsTotal => _items.fold(0, (sum, item) => sum + item.plannedAmount);

  bool get _canSave => _name.text.trim().isNotEmpty && _walletId != null && BudgetMoneyField.senOf(_planned) != null;

  Budget get _draft => Budget(
    id: widget.initial?.id ?? '',
    name: _name.text,
    walletId: _walletId ?? '',
    period: _period,
    startDate: _startDate,
    plannedAmount: BudgetMoneyField.senOf(_planned) ?? 0,
  );

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _editItem([int? index]) async {
    final result = await showFullScreenSheet<BudgetItemFormResult>(
      context,
      builder: (_) => BudgetItemFormSheet(initial: index == null ? null : _items[index]),
    );
    if (!mounted) return;
    setState(() {
      switch (result) {
        case BudgetItemFormSaved(:final item):
          if (index == null) {
            _items = [..._items, item];
          } else {
            _items = [..._items]..[index] = item;
          }
        case BudgetItemFormDeleted():
          if (index != null) _items = [..._items]..removeAt(index);
        case null:
          break;
      }
    });
  }

  void _useItemsTotal() {
    final rupiah = _itemsTotal ~/ 100;
    setState(() => _planned.text = rupiah <= 0 ? '' : formatRupiahInput(rupiah));
  }

  void _save() {
    if (!_canSave) return;
    Navigator.of(context).pop(
      BudgetFormSaved(
        name: _name.text.trim(),
        walletId: _walletId!,
        period: _period,
        startDate: _startDate,
        plannedAmount: BudgetMoneyField.senOf(_planned)!,
        items: _items,
      ),
    );
  }

  Future<void> _delete() async {
    final budget = widget.initial;
    if (budget == null) return;
    final confirmed = await showConfirmDelete(
      context,
      title: t.budget.deleteConfirmTitle,
      message: t.budget.deleteConfirmMessage(name: budget.name),
    );
    if (confirmed && mounted) Navigator.of(context).pop(const BudgetFormDeleted());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final budget = widget.initial;
    final planned = BudgetMoneyField.senOf(_planned) ?? 0;
    final difference = planned - _itemsTotal;
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
                stepLabel: _editing ? t.budget.editStepLabel : t.budget.addStepLabel,
                title: _editing ? t.budget.editTitle : t.budget.addTitle,
              ),
              const SizedBox(height: AppSpacing.md),
              TransactionSlab(
                color: colors.surfaceLow,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.budget.ruleTitle, style: textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(t.budget.ruleBody, style: textTheme.bodySmall?.copyWith(color: colors.textMuted)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppSectionLabel(t.budget.nameLabel, hint: t.budget.requiredHint),
              const SizedBox(height: AppSpacing.xs),
              BudgetTextField(controller: _name, hint: t.budget.nameHint, autofocus: !_editing, onChanged: refresh),
              const SizedBox(height: AppSpacing.md),
              AppSectionLabel(t.budget.walletLabel, hint: t.budget.requiredHint),
              const SizedBox(height: 2),
              Text(t.budget.walletHelp, style: textTheme.bodySmall?.copyWith(color: colors.textMuted)),
              const SizedBox(height: AppSpacing.xs),
              for (final wallet in widget.wallets) ...[
                _WalletChoice(
                  wallet: wallet,
                  selected: wallet.id == _walletId,
                  onTap: () => setState(() => _walletId = wallet.id),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
              const SizedBox(height: AppSpacing.sm),
              AppSectionLabel(t.budget.periodLabel),
              const SizedBox(height: AppSpacing.xs),
              BudgetSegmented<BudgetPeriod>(
                options: [
                  (BudgetPeriod.monthly, t.budget.periodMonthly),
                  (BudgetPeriod.weekly, t.budget.periodWeekly),
                ],
                selected: _period,
                onChanged: (value) => setState(() => _period = value),
              ),
              const SizedBox(height: AppSpacing.xs),
              Semantics(
                button: true,
                label: t.budget.startDateLabel,
                child: GestureDetector(
                  onTap: _pickStartDate,
                  behavior: HitTestBehavior.opaque,
                  child: TransactionSlab(
                    radius: 4,
                    shadow: 2,
                    child: Row(
                      children: [
                        const AppIcon(IconKey.calendar),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.budget.startDateLabel.toUpperCase(),
                                style: transactionLabelStyle(context, color: colors.textMuted),
                              ),
                              Text(CycleMonthFormatter.formatDate(_startDate), style: textTheme.titleMedium),
                            ],
                          ),
                        ),
                        BudgetBadge(label: budgetRangeLabel(_draft)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppSectionLabel(t.budget.plannedAmountLabel, hint: t.budget.requiredHint),
              const SizedBox(height: AppSpacing.xs),
              BudgetMoneyField(controller: _planned, onChanged: refresh, large: true),
              const SizedBox(height: 4),
              Text(t.budget.plannedAmountHelp, style: textTheme.bodySmall?.copyWith(color: colors.textMuted)),
              const SizedBox(height: AppSpacing.md),
              AppSectionLabel(t.budget.itemsLabel, hint: t.budget.itemCount(count: _items.length)),
              const SizedBox(height: 2),
              Text(t.budget.itemsHelp, style: textTheme.bodySmall?.copyWith(color: colors.textMuted)),
              const SizedBox(height: AppSpacing.xs),
              for (var i = 0; i < _items.length; i++) ...[
                _ItemRow(item: _items[i], onTap: () => _editItem(i)),
                const SizedBox(height: AppSpacing.xs),
              ],
              AppButton(label: t.budget.addItemAction, color: colors.textMuted, onPressed: _editItem),
              if (_items.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                TransactionSlab(
                  color: colors.surfaceLow,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TotalRow(label: t.budget.itemsTotalLabel, sen: _itemsTotal, color: colors.textPrimary),
                      const SizedBox(height: 4),
                      _TotalRow(
                        label: t.budget.differenceLabel,
                        sen: difference,
                        color: difference < 0 ? colors.overBudget : colors.textPrimary,
                      ),
                      if (difference != 0) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: AppQuickChip(label: t.budget.useItemsTotalAction, onTap: _useItemsTotal),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: _editing ? t.transaction.saveChangesAction : t.budget.saveAddAction,
                onPressed: _canSave ? _save : null,
              ),
              if (budget != null) ...[
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: budget.isArchived ? t.budget.unarchiveAction : t.budget.archiveAction,
                  color: colors.textMuted,
                  onPressed: () => Navigator.of(context).pop(const BudgetFormArchiveToggled()),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  t.budget.archiveHelp,
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(label: t.budget.deleteAction, color: colors.expense, onPressed: _delete),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletChoice extends StatelessWidget {
  const _WalletChoice({required this.wallet, required this.selected, required this.onTap});

  final Wallet wallet;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: selected ? colors.tinted(colors.accent, 0.12) : colors.surfaceLow,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? colors.accent : Colors.transparent, width: 2),
          ),
          child: Row(
            children: [
              AppIcon(walletIconKey(wallet.iconKey), size: 32),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(wallet.name, style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      t.budget.walletBalance(amount: AppMoneyFormatter.format(wallet.currentBalance)),
                      style: transactionLabelStyle(
                        context,
                        color: colors.textMuted,
                      ).copyWith(fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              ),
              if (selected) AppIcon(IconKey.check, color: colors.accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.onTap});

  final BudgetItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: TransactionSlab(
          radius: 4,
          shadow: 2,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: Theme.of(context).textTheme.titleMedium),
                    if (item.isItemized)
                      Text(
                        t.budget.itemItemizedDetail(
                          quantity: item.quantity!,
                          price: AppMoneyFormatter.format(item.unitPrice!),
                        ),
                        style: transactionLabelStyle(
                          context,
                          color: colors.textMuted,
                        ).copyWith(fontWeight: FontWeight.w400),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                AppMoneyFormatter.format(item.plannedAmount),
                style: PixelTypography.tabularMono(context, color: colors.textPrimary),
              ),
              const SizedBox(width: AppSpacing.xs),
              const AppIcon(IconKey.edit, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.label, required this.sen, required this.color});

  final String label;
  final int sen;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label.toUpperCase(), style: transactionLabelStyle(context, color: context.appColors.textMuted)),
        ),
        Text(AppMoneyFormatter.format(sen), style: PixelTypography.tabularMono(context, color: color)),
      ],
    );
  }
}
