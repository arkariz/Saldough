import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/spotlight/spotlight.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/tutorial/tutorial.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/budget/domain/entities/budget.dart';
import 'package:saldough/features/budget/domain/entities/budget_item.dart';
import 'package:saldough/features/budget/domain/entities/budget_period.dart';
import 'package:saldough/features/budget/domain/entities/budget_schedule.dart';
import 'package:saldough/features/budget/domain/usecases/plan_recurring_budget_save.dart';
import 'package:saldough/features/budget/presentation/budget_display.dart';
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
    this.repeat,
    this.scope = BudgetEditScope.thisPeriod,
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

  /// Sakelar **Ulangi tiap periode** (ADR-036 §3.1); `null` bila tidak bisa
  /// diubah (anggaran periode lalu).
  final bool? repeat;

  /// Lingkup perubahan anggaran rutin yang dipilih (ADR-036 §3.3).
  final BudgetEditScope scope;
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
/// Anggaran baru boleh diisi awal dari template ([prefillName],
/// [prefillItems], [templateName]; FR-BUD-005, T-7.3). Pos isian awal sudah
/// ber-id baru (`CreateBudgetFromTemplate.draftItems`); pos transfer yang
/// tujuannya ternyata sama dengan dompet yang dipilih ditandai dan menahan
/// simpan sampai pemilik mengganti tujuannya — sama untuk pos yang diketik.
///
/// ⚠ Bagian rujukan yang sengaja tidak dibangun: periode "Kustom" (domain
/// hanya mingguan/bulanan).
class BudgetFormSheet extends StatefulWidget {
  /// Membuat [BudgetFormSheet]. [initial] `null` = anggaran baru.
  const BudgetFormSheet({
    required this.wallets,
    this.initial,
    this.allWallets = const [],
    this.lockedItemIds = const {},
    this.prefillName,
    this.prefillItems = const [],
    this.templateName,
    this.repeatInitially = false,
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

  /// Nama awal anggaran baru (dari template).
  final String? prefillName;

  /// Pos awal anggaran baru (dari template), sudah ber-id baru.
  final List<BudgetItem> prefillItems;

  /// Nama template asal, untuk label langkah; `null` = anggaran kosong.
  final String? templateName;

  /// [initial] adalah anggaran rutin yang jadwalnya aktif (ADR-036).
  final bool repeatInitially;

  @override
  State<BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends State<BudgetFormSheet> {
  final _name = TextEditingController();
  String? _walletId;
  BudgetPeriod _period = BudgetPeriod.monthly;
  late DateTime _startDate;
  List<BudgetItem> _items = [];
  late bool _repeat = widget.repeatInitially;

  bool get _editing => widget.initial != null;

  /// Anggaran periode lalu tidak pernah mengubah templatenya (ADR-036 §3.3).
  bool get _isPast => widget.initial?.endDate.isAfter(DateTime.now()) == false;

  bool get _canRepeat => BudgetSchedule.canRepeat(_period, _startDate);

  @override
  void initState() {
    super.initState();
    // Bawaan bulanan: awal bulan keuangan (ADR-036 §3.1).
    _startDate = financialMonthOf(DateTime.now(), ActiveFinancialMonth.startDay).start;
    final budget = widget.initial;
    if (budget == null) {
      if (widget.wallets.length == 1) _walletId = widget.wallets.single.id;
      _name.text = widget.prefillName ?? '';
      _items = [...widget.prefillItems];
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

  Future<void> _save() async {
    if (!_canSave) return;
    final repeat = _isPast ? null : _repeat && _canRepeat;
    var scope = BudgetEditScope.thisAndNext;
    if (widget.initial case final before? when repeat ?? false) {
      final after = before.copyWith(
        name: _name.text.trim(),
        walletId: _walletId,
        period: _period,
        startDate: _startDate,
        items: _items,
      );
      if (needsEditScope(before: before, after: after, scheduled: widget.repeatInitially, today: DateTime.now())) {
        final chosen = await _askScope(defaultEditScope(before, after));
        if (chosen == null || !mounted) return;
        scope = chosen;
        AppAnalytics.log(PlanEvents.budgetEditScope(chosen.name));
      }
    }
    if (!mounted) return;
    Navigator.of(context).pop(
      BudgetFormSaved(
        name: _name.text.trim(),
        walletId: _walletId!,
        period: _period,
        startDate: _startDate,
        items: _items,
        repeat: repeat,
        scope: scope,
      ),
    );
  }

  /// Dialog lingkup (RECURRING_AND_FORECAST §8.6): bawaannya di atas dan
  /// bercentang; menutup dialog membatalkan simpan.
  Future<BudgetEditScope?> _askScope(BudgetEditScope preferred) => showDialog<BudgetEditScope>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: Text(t.budget.scopeTitle),
      children: [
        for (final scope in [preferred, ...BudgetEditScope.values.where((s) => s != preferred)])
          SimpleDialogOption(
            key: ValueKey('budget-scope-${scope.name}'),
            onPressed: () => Navigator.of(dialogContext).pop(scope),
            child: Row(
              children: [
                Expanded(
                  child: Text(switch (scope) {
                    BudgetEditScope.thisPeriod => t.budget.scopeThisPeriod,
                    BudgetEditScope.thisAndNext => t.budget.scopeThisAndNext,
                  }),
                ),
                if (scope == preferred) const AppIcon(IconKey.check),
              ],
            ),
          ),
      ],
    ),
  );

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
    return TourTrigger(
      tour: TourId.budgetForm,
      ready: true,
      child: SizedBox.expand(
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.space4, AppSpacing.space4, AppSpacing.space4, AppSpacing.space6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppFormHeader(
                  stepLabel: _editing
                      ? t.budget.editStepLabel
                      : switch (widget.templateName) {
                          final name? => t.budget.fromTemplateStepLabel(name: name),
                          null => t.budget.addStepLabel,
                        },
                  title: _editing ? t.budget.editTitle : t.budget.addTitle,
                ),
                const SizedBox(height: AppSpacing.space4),
                TransactionSlab(
                  color: colors.surface2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.budget.ruleTitle, style: textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(t.budget.ruleBody, style: textTheme.bodySmall?.copyWith(color: colors.ink2)),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                AppSectionLabel(t.budget.nameLabel, hint: t.budget.requiredHint),
                const SizedBox(height: AppSpacing.space1),
                AppFormTextField(controller: _name, hint: t.budget.nameHint, autofocus: !_editing, onChanged: refresh),
                const SizedBox(height: AppSpacing.space4),
                AppSectionLabel(t.budget.walletLabel, hint: t.budget.requiredHint),
                const SizedBox(height: 2),
                Text(t.budget.walletHelp, style: textTheme.bodySmall?.copyWith(color: colors.ink2)),
                const SizedBox(height: AppSpacing.space1),
                for (final wallet in widget.wallets) ...[
                  _WalletChoice(
                    wallet: wallet,
                    selected: wallet.id == _walletId,
                    onTap: () => setState(() => _walletId = wallet.id),
                  ),
                  const SizedBox(height: AppSpacing.space1),
                ],
                const SizedBox(height: AppSpacing.space2),
                AppSectionLabel(t.budget.periodLabel),
                const SizedBox(height: AppSpacing.space1),
                AppSegmented<BudgetPeriod>(
                  options: [
                    (BudgetPeriod.monthly, t.budget.periodMonthly),
                    (BudgetPeriod.weekly, t.budget.periodWeekly),
                  ],
                  selected: _period,
                  onChanged: (value) => setState(() => _period = value),
                ),
                const SizedBox(height: AppSpacing.space1),
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
                          const SizedBox(width: AppSpacing.space2),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.budget.startDateLabel.toUpperCase(),
                                  style: transactionLabelStyle(context, color: colors.ink2),
                                ),
                                Text(CycleMonthFormatter.formatDate(_startDate), style: textTheme.titleMedium),
                              ],
                            ),
                          ),
                          // Rentang panjang boleh membungkus di 360dp.
                          Flexible(child: BudgetBadge(label: budgetRangeLabel(_draft))),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space1),
                SpotlightTarget(
                  spotlightKey: SpotlightKey.budgetRepeat,
                  child: _RepeatSwitch(
                    value: _repeat && _canRepeat,
                    enabled: _canRepeat && !_isPast,
                    help: _isPast
                        ? t.budget.repeatPastNote
                        : !_canRepeat
                        ? t.budget.repeatUnavailable
                        : switch (_period) {
                            BudgetPeriod.monthly => t.budget.repeatHelpMonthly(
                              date: CycleMonthFormatter.formatDate(_period.endFrom(_startDate)),
                            ),
                            BudgetPeriod.weekly => t.budget.repeatHelpWeekly(
                              date: CycleMonthFormatter.formatDate(_period.endFrom(_startDate)),
                            ),
                          },
                    onChanged: (value) {
                      AppAnalytics.log(PlanEvents.budgetRepeatToggled(on: value));
                      setState(() => _repeat = value);
                    },
                  ),
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
                const SizedBox(height: AppSpacing.space2),
                if (_conflictingItem case final item?) ...[
                  Text(
                    t.budget.itemTargetConflict(name: item.name),
                    style: textTheme.bodySmall?.copyWith(color: colors.danger),
                  ),
                  const SizedBox(height: AppSpacing.space1),
                ],
                _PlannedTotalCard(
                  total: _itemsTotal,
                  itemCount: _items.length,
                  walletName: _selectedWalletName,
                ),
                const SizedBox(height: AppSpacing.space6),
                AppButton(
                  label: _editing ? t.transaction.saveChangesAction : t.budget.saveAddAction,
                  onPressed: _canSave ? () => unawaited(_save()) : null,
                ),
                if (budget != null) ...[
                  const SizedBox(height: AppSpacing.space6),
                  AppButton.secondary(
                    label: budget.isArchived ? t.budget.unarchiveAction : t.budget.archiveAction,
                    onPressed: () => Navigator.of(context).pop(const BudgetFormArchiveToggled()),
                  ),
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    t.budget.archiveHelp,
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(color: colors.ink2),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  AppButton.secondary(label: t.budget.deleteAction, textColor: colors.danger, onPressed: _delete),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Sakelar **Ulangi tiap periode** (RECURRING_AND_FORECAST §8.6, ADR-036
/// §3.1) dengan kalimat kapan periode berikutnya lahir.
class _RepeatSwitch extends StatelessWidget {
  const _RepeatSwitch({required this.value, required this.enabled, required this.help, required this.onChanged});

  final bool value;
  final bool enabled;
  final String help;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    return TransactionSlab(
      radius: 4,
      shadow: 2,
      child: Row(
        children: [
          const AppIcon(IconKey.calendar),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.budget.repeatLabel, style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                Text(help, style: textTheme.bodySmall?.copyWith(color: colors.ink2)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
          Switch(
            key: const ValueKey('budget-repeat-switch'),
            value: value,
            activeThumbColor: colors.onBrand,
            activeTrackColor: colors.brand,
            onChanged: enabled ? onChanged : null,
          ),
        ],
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
          padding: const EdgeInsets.all(AppSpacing.space2),
          decoration: BoxDecoration(
            color: selected ? colors.tinted(colors.brand, 0.12) : colors.surface2,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? colors.brand : Colors.transparent, width: 2),
          ),
          child: Row(
            children: [
              AppIcon(walletIconKey(wallet.iconKey), size: 32),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(wallet.name, style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      t.budget.walletBalance(amount: AppMoneyFormatter.format(wallet.currentBalance)),
                      style: transactionLabelStyle(
                        context,
                        color: colors.ink2,
                      ).copyWith(fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              ),
              if (selected) AppIcon(IconKey.check, color: colors.brand),
            ],
          ),
        ),
      ),
    );
  }
}

/// Satu baris pos di formulir anggaran dan formulir template: nama, jenis
/// (dan tujuan transfer), rincian jumlah × harga, dan nominal rencana.
class BudgetItemRow extends StatelessWidget {
  /// Membuat [BudgetItemRow].
  const BudgetItemRow({required this.item, required this.targetWalletName, required this.onTap, super.key});

  /// Pos yang ditampilkan.
  final BudgetItem item;

  /// Nama dompet tujuan pos transfer.
  final String? targetWalletName;

  /// Membuka formulir pos.
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
                      color: item.isTransfer ? colors.ink2 : colors.ink2,
                    ),
                    if (item.isItemized)
                      Text(
                        t.budget.itemItemizedDetail(
                          quantity: item.quantity!,
                          price: AppMoneyFormatter.format(item.unitPrice!),
                        ),
                        style: transactionLabelStyle(
                          context,
                          color: colors.ink2,
                        ).copyWith(fontWeight: FontWeight.w400),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                AppMoneyFormatter.format(item.plannedAmount),
                style: context.numberStyles.amountSm.copyWith(color: colors.ink),
              ),
              const SizedBox(width: AppSpacing.space1),
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
      color: colors.surface2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.budget.totalPlannedLabel.toUpperCase(),
            style: transactionLabelStyle(context, color: colors.ink2),
          ),
          const SizedBox(height: 2),
          FitStart(
            child: Text(
              AppMoneyFormatter.format(total),
              style: textTheme.headlineMedium?.copyWith(fontSize: 30, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 4),
          if (itemCount == 0)
            Text(t.budget.itemsRequiredHint, style: textTheme.bodySmall?.copyWith(color: colors.warning))
          else
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: AppSpacing.space2,
              runSpacing: 2,
              children: [
                Text(
                  t.budget.itemCount(count: itemCount),
                  style: transactionLabelStyle(context, color: colors.ink2).copyWith(fontWeight: FontWeight.w400),
                ),
                if (walletName != null)
                  Text(
                    t.budget.walletUnchangedNote(wallet: walletName!),
                    style: transactionLabelStyle(
                      context,
                      color: colors.ink2,
                    ).copyWith(fontWeight: FontWeight.w400),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
