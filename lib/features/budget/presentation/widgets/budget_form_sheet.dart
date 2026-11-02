import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/spotlight/spotlight.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
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
import 'package:saldough/shared/wallet/wallet_presentation.dart';

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
    _startDate = ActiveFinancialMonth.periodOf(DateTime.now()).start;
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

  /// Lembar lingkup (RECURRING_AND_FORECAST §8.6): bawaannya di atas dan
  /// bercentang; menutup lembar membatalkan simpan.
  Future<BudgetEditScope?> _askScope(BudgetEditScope preferred) => showOptionSheet<BudgetEditScope>(
    context,
    title: t.budget.scopeTitle,
    current: preferred,
    options: [
      for (final scope in [preferred, ...BudgetEditScope.values.where((s) => s != preferred)])
        OptionSheetItem(
          key: ValueKey('budget-scope-${scope.name}'),
          value: scope,
          label: switch (scope) {
            BudgetEditScope.thisPeriod => t.budget.scopeThisPeriod,
            BudgetEditScope.thisAndNext => t.budget.scopeThisAndNext,
          },
        ),
    ],
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
    final ds = context.ds;
    final c = ds.colors;
    final budget = widget.initial;
    void refresh(String _) => setState(() {});
    final walletName = _selectedWalletName;
    // QA PR #43 F14: dompet satu baris pemilih, periode satu baris ringkas,
    // dan total + Simpan di bilah bawah yang menempel (DsStickyBar).
    return TourTrigger(
      tour: TourId.budgetForm,
      ready: true,
      child: SizedBox.expand(
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppFormHeader(title: _editing ? t.budget.editTitle : t.budget.addTitle),
                      const SizedBox(height: 16),
                      DecoratedBox(
                        decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: DsRadius.mdAll),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DsIconTile.asset(asset: ClayIcons.piggy, size: DsIconTileSize.sm),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(t.budget.ruleTitle, style: ds.typography.titleMd),
                                    const SizedBox(height: 2),
                                    Text(
                                      t.budget.ruleBody,
                                      style: ds.typography.bodySm.copyWith(color: c.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DsFieldGroup(
                        children: [
                          DsFieldRow(
                            icon: Icons.edit_note,
                            leading: DsIconTile.asset(asset: ClayIcons.note, size: DsIconTileSize.sm),
                            label: '${t.budget.nameLabel} · ${t.budget.requiredHint}'.toUpperCase(),
                            child: TextField(
                              controller: _name,
                              autofocus: !_editing,
                              maxLength: 40,
                              textCapitalization: TextCapitalization.sentences,
                              cursorColor: c.actionPrimary,
                              onChanged: refresh,
                              style: ds.typography.bodyMd.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
                              buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                filled: false,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                hintText: t.budget.nameHint,
                                hintStyle: ds.typography.bodyMd.copyWith(fontSize: 14, color: c.textMuted),
                              ),
                            ),
                          ),
                          WalletSelectField(
                            key: const ValueKey('budget-wallet'),
                            useDs: true,
                            label: t.budget.walletLabel,
                            wallets: widget.wallets,
                            selectedId: _walletId,
                            onSelected: (id) => setState(() => _walletId = id),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(t.budget.walletHelp, style: ds.typography.bodySm.copyWith(color: c.textSecondary)),
                      ),
                      const SizedBox(height: 20),
                      AppSectionLabel(t.budget.periodLabel),
                      const SizedBox(height: 8),
                      DsSegmentedPill<BudgetPeriod>(
                        key: const ValueKey('budget-period'),
                        segments: [
                          DsSegment(
                            value: BudgetPeriod.monthly,
                            label: t.budget.periodMonthly,
                            asset: ClayIcons.calendar,
                          ),
                          DsSegment(
                            value: BudgetPeriod.weekly,
                            label: t.budget.periodWeekly,
                            asset: ClayIcons.dateCalendar,
                          ),
                        ],
                        selected: _period,
                        onChanged: (period) => setState(() => _period = period),
                      ),
                      const SizedBox(height: 8),
                      DsFieldGroup(
                        children: [
                          DsFieldRow(
                            key: const ValueKey('budget-start'),
                            icon: Icons.calendar_month_outlined,
                            leading: DsIconTile.asset(asset: ClayIcons.dateCalendar, size: DsIconTileSize.sm),
                            label: t.budget.periodLabel,
                            title: t.budget.periodStartRow(
                              date: CycleMonthFormatter.formatDayMonth(_startDate),
                              range: budgetRangeShortLabel(_draft),
                            ),
                            chevron: true,
                            onTap: _pickStartDate,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
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
                      const SizedBox(height: 16),
                      AppSectionLabel(t.budget.itemsLabel, hint: t.budget.requiredHint),
                      const SizedBox(height: 2),
                      Text(t.budget.itemsHelp, style: ds.typography.bodySm.copyWith(color: c.textSecondary)),
                      const SizedBox(height: 8),
                      for (var i = 0; i < _items.length; i++) ...[
                        BudgetItemRow(
                          item: _items[i],
                          targetWalletName: _walletName(_items[i].targetWalletId),
                          onTap: () => _editItem(i),
                        ),
                        const SizedBox(height: 8),
                      ],
                      DsButton.secondary(
                        label: t.budget.addItemAction,
                        icon: Icons.add,
                        expand: true,
                        onPressed: _editItem,
                      ),
                      const SizedBox(height: 8),
                      if (_conflictingItem case final item?) ...[
                        Text(
                          t.budget.itemTargetConflict(name: item.name),
                          style: ds.typography.bodySm.copyWith(color: c.error),
                        ),
                        const SizedBox(height: 4),
                      ],
                      if (_items.isEmpty)
                        Text(t.budget.itemsRequiredHint, style: ds.typography.bodySm.copyWith(color: c.warning))
                      else if (walletName != null)
                        Text(
                          '${t.budget.itemCount(count: _items.length)} · '
                          '${t.budget.walletUnchangedNote(wallet: walletName)}',
                          style: ds.typography.bodySm.copyWith(color: c.textSecondary),
                        ),
                      if (budget != null) ...[
                        const SizedBox(height: 24),
                        DsButton.secondary(
                          label: budget.isArchived ? t.budget.unarchiveAction : t.budget.archiveAction,
                          expand: true,
                          onPressed: () => Navigator.of(context).pop(const BudgetFormArchiveToggled()),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t.budget.archiveHelp,
                          textAlign: TextAlign.center,
                          style: ds.typography.bodySm.copyWith(color: c.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        DsButton.danger(label: t.budget.deleteAction, expand: true, onPressed: _delete),
                      ],
                    ],
                  ),
                ),
              ),
              BudgetTotalBar(
                total: _itemsTotal,
                saveLabel: _editing ? t.transaction.saveChangesAction : t.budget.saveAddAction,
                onSave: _canSave ? () => unawaited(_save()) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bilah bawah formulir anggaran dan template (QA PR #43 F14): total rencana
/// (jumlah pos, ADR-017) di kiri, tombol simpan di kanan, menempel di atas
/// navigasi sistem dan keyboard ([DsStickyBar]).
class BudgetTotalBar extends StatelessWidget {
  /// Membuat [BudgetTotalBar].
  const BudgetTotalBar({
    required this.total,
    required this.saveLabel,
    required this.onSave,
    this.label,
    super.key,
  });

  /// Total rencana (sen).
  final int total;

  /// Label total; bawaan "Total rencana anggaran".
  final String? label;

  /// Teks tombol simpan.
  final String saveLabel;

  /// Simpan; `null` menonaktifkan.
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return DsStickyBar(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label ?? t.budget.totalPlannedLabel,
                  style: ds.typography.bodySm.copyWith(color: ds.colors.textSecondary),
                ),
                FitStart(
                  child: Text(
                    AppMoneyFormatter.format(total),
                    key: const ValueKey('budget-total'),
                    style: ds.typography.amount.copyWith(fontSize: 22, height: 28 / 22, color: ds.colors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          DsButton(key: const ValueKey('budget-save'), label: saveLabel, onPressed: onSave),
        ],
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
    final ds = context.ds;
    final c = ds.colors;
    return DsListCard(
      children: [
        DsSettingRow(
          leading: DsIconTile.asset(asset: ClayIcons.repeat, size: DsIconTileSize.sm),
          title: t.budget.repeatLabel,
          subtitle: help,
          trailing: Switch(
            key: const ValueKey('budget-repeat-switch'),
            value: value,
            activeThumbColor: c.onActionPrimary,
            activeTrackColor: c.actionPrimary,
            onChanged: enabled ? onChanged : null,
          ),
        ),
      ],
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
    final ds = context.ds;
    final c = ds.colors;
    return Semantics(
      button: true,
      child: DsCard(
        onTap: onTap,
        child: Row(
          children: [
            DsIconTile.asset(
              asset: item.isTransfer ? ClayIcons.transfer : ClayIcons.expenseArrow,
              size: DsIconTileSize.sm,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: ds.typography.titleMd),
                  const SizedBox(height: 2),
                  Text(
                    item.isTransfer
                        ? '${t.budget.itemKindTransfer} · ${t.budget.itemTransferTo(wallet: targetWalletName ?? t.budget.unknownWallet)}'
                        : t.budget.itemKindExpense,
                    style: ds.typography.bodySm.copyWith(color: c.textSecondary),
                  ),
                  if (item.isItemized)
                    Text(
                      t.budget.itemItemizedDetail(
                        quantity: item.quantity!,
                        price: AppMoneyFormatter.format(item.unitPrice!),
                      ),
                      style: ds.typography.bodySm.copyWith(color: c.textSecondary),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(AppMoneyFormatter.format(item.plannedAmount), style: ds.typography.amountSm),
            const SizedBox(width: 4),
            Icon(Icons.edit_outlined, size: 18, color: c.textMuted),
          ],
        ),
      ),
    );
  }
}
