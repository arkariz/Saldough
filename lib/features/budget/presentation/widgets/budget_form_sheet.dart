import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
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

  /// Pos-pos, minimal satu; nominal rencana anggaran adalah jumlahnya.
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
/// Nominal rencana anggaran TIDAK diketik terpisah: selalu jumlah pos, dan
/// ditampilkan sebagai "Total rencana" yang ikut berubah tiap pos ditambah,
/// disunting, atau dihapus (ADR-017). Minimal satu pos wajib ada.
///
/// Pos berjenis pengeluaran atau transfer (ADR-018); jenis pos yang sudah
/// punya transaksi tertaut dikunci ([lockedItemIds]).
///
/// ⚠ Bagian rujukan yang sengaja tidak dibangun: periode "Kustom" (domain
/// hanya mingguan/bulanan) dan "buat dari template" (FR-BUD-005, Fase 7).
class BudgetFormSheet extends StatefulWidget {
  /// Membuat [BudgetFormSheet]. [initial] `null` = anggaran baru.
  const BudgetFormSheet({
    required this.wallets,
    this.initial,
    this.allWallets = const [],
    this.lockedItemIds = const {},
    super.key,
  });

  /// Dompet yang bisa dipilih — pemanggil menyertakan dompet milik
  /// [initial] walau sudah nonaktif, supaya pilihannya tidak hilang.
  final List<Wallet> wallets;

  /// Anggaran yang disunting.
  final Budget? initial;

  /// Seluruh dompet, untuk pilihan dan nama dompet tujuan pos transfer
  /// (dompet nonaktif hanya muncul kalau sudah jadi tujuan pos itu).
  final List<Wallet> allWallets;

  /// `id` pos yang sudah punya transaksi tertaut — jenisnya dikunci
  /// (ADR-018).
  final Set<String> lockedItemIds;

  @override
  State<BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends State<BudgetFormSheet> {
  final _name = TextEditingController();
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
    _walletId = budget.walletId;
    _period = budget.period;
    _startDate = budget.startDate;
    _items = [...budget.items];
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String? get _selectedWalletName {
    for (final wallet in widget.wallets) {
      if (wallet.id == _walletId) return wallet.name;
    }
    return null;
  }

  int get _itemsTotal => _items.fold(0, (sum, item) => sum + item.plannedAmount);

  bool get _canSave =>
      _name.text.trim().isNotEmpty && _walletId != null && _items.isNotEmpty && _conflictingItem == null;

  /// Pos transfer yang dompet tujuannya sama dengan dompet anggaran — tidak
  /// sah (transfer ke dompet yang sama), terjadi kalau dompet anggaran
  /// diganti sesudah pos transfer dibuat.
  BudgetItem? get _conflictingItem =>
      _items.where((item) => item.isTransfer && item.targetWalletId == _walletId).firstOrNull;

  /// Pilihan dompet tujuan pos transfer: dompet aktif selain dompet
  /// anggaran, ditambah tujuan pos yang sedang disunting walau nonaktif.
  List<Wallet> _targetWalletsFor(BudgetItem? item) => [
    for (final wallet in widget.allWallets.isEmpty ? widget.wallets : widget.allWallets)
      if (wallet.id != _walletId && (wallet.isActive || wallet.id == item?.targetWalletId)) wallet,
  ];

  String? _walletName(String? id) => (widget.allWallets.isEmpty ? widget.wallets : widget.allWallets)
      .where((wallet) => wallet.id == id)
      .firstOrNull
      ?.name;

  Budget get _draft => Budget(
    id: widget.initial?.id ?? '',
    name: _name.text,
    walletId: _walletId ?? '',
    period: _period,
    startDate: _startDate,
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
      builder: (_) {
        final item = index == null ? null : _items[index];
        return BudgetItemFormSheet(
          initial: item,
          targetWallets: _targetWalletsFor(item),
          kindLocked: item != null && widget.lockedItemIds.contains(item.id),
        );
      },
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

  void _save() {
    if (!_canSave) return;
    Navigator.of(context).pop(
      BudgetFormSaved(
        name: _name.text.trim(),
        walletId: _walletId!,
        period: _period,
        startDate: _startDate,
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
              AppSectionLabel(t.budget.itemsLabel, hint: t.budget.requiredHint),
              const SizedBox(height: 2),
              Text(t.budget.itemsHelp, style: textTheme.bodySmall?.copyWith(color: colors.textMuted)),
              const SizedBox(height: AppSpacing.xs),
              for (var i = 0; i < _items.length; i++) ...[
                _ItemRow(
                  item: _items[i],
                  targetWalletName: _walletName(_items[i].targetWalletId),
                  onTap: () => _editItem(i),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
              AppButton(label: t.budget.addItemAction, color: colors.textMuted, onPressed: _editItem),
              const SizedBox(height: AppSpacing.sm),
              if (_conflictingItem case final item?) ...[
                Text(
                  t.budget.itemTargetConflict(name: item.name),
                  style: textTheme.bodySmall?.copyWith(color: colors.overBudget),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
              _PlannedTotalCard(
                total: _itemsTotal,
                itemCount: _items.length,
                walletName: _selectedWalletName,
              ),
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
  const _ItemRow({required this.item, required this.targetWalletName, required this.onTap});

  final BudgetItem item;
  final String? targetWalletName;
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
                    const SizedBox(height: 2),
                    BudgetBadge(
                      label: item.isTransfer
                          ? '${t.budget.itemKindTransfer} · ${t.budget.itemTransferTo(wallet: targetWalletName ?? t.budget.unknownWallet)}'
                          : t.budget.itemKindExpense,
                      color: item.isTransfer ? colors.transfer : colors.textMuted,
                    ),
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

/// Total rencana anggaran = jumlah pos (ADR-017), rujukan
/// `pixel_kas_tambah_anggaran` bagian "Total Rencana Anggaran". Tanpa pos,
/// kartu ini menjelaskan bahwa minimal satu pos dibutuhkan.
class _PlannedTotalCard extends StatelessWidget {
  const _PlannedTotalCard({required this.total, required this.itemCount, required this.walletName});

  final int total;
  final int itemCount;
  final String? walletName;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    return TransactionSlab(
      color: colors.surfaceLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.budget.totalPlannedLabel.toUpperCase(), style: transactionLabelStyle(context, color: colors.textMuted)),
          const SizedBox(height: 2),
          FitStart(
            child: Text(
              AppMoneyFormatter.format(total),
              style: textTheme.headlineMedium?.copyWith(fontSize: 30, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 4),
          if (itemCount == 0)
            Text(t.budget.itemsRequiredHint, style: textTheme.bodySmall?.copyWith(color: colors.pending))
          else
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: AppSpacing.sm,
              runSpacing: 2,
              children: [
                Text(
                  t.budget.itemCount(count: itemCount),
                  style: transactionLabelStyle(context, color: colors.textMuted).copyWith(fontWeight: FontWeight.w400),
                ),
                if (walletName != null)
                  Text(
                    t.budget.walletUnchangedNote(wallet: walletName!),
                    style: transactionLabelStyle(context, color: colors.textMuted).copyWith(fontWeight: FontWeight.w400),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
