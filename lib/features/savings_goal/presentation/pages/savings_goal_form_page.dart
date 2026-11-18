import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/plan/active_plan.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_input.dart';
import 'package:saldough/features/premium/presentation/navigation/premium_route_keys.dart';
import 'package:saldough/features/savings_goal/presentation/bloc/savings_goal_bloc.dart';
import 'package:saldough/shared/category/category_presentation.dart';
import 'package:saldough/shared/savings_goal/savings_goal.dart';
import 'package:saldough/shared/savings_goal/savings_goal_presentation.dart';
import 'package:state_management/state_management.dart';

/// Formulir buat/ubah tujuan tabungan (rupa B-96 §2, ADR-048). Batas Gratis
/// diperiksa saat menyimpan: isian disimpan sebagai draf lalu paywall P11
/// dibuka (ADR-048 §3.5).
class SavingsGoalFormPage extends StatefulWidget {
  /// Membuat [SavingsGoalFormPage]. [initial] `null` = tujuan baru.
  const SavingsGoalFormPage({
    required this.draftStore,
    this.initial,
    super.key,
  });

  /// Tujuan yang diubah, atau `null`.
  final SavingsGoal? initial;

  /// Penyimpan draf P11.
  final SavingsGoalDraftStore draftStore;

  @override
  State<SavingsGoalFormPage> createState() => _SavingsGoalFormPageState();
}

class _SavingsGoalFormPageState extends State<SavingsGoalFormPage> {
  final _name = TextEditingController();
  final _target = TextEditingController();
  final _description = TextEditingController();
  final _collected = TextEditingController();
  late String _id;
  late DateTime _createdAt;
  String _iconKey = IconKey.walletSavings.name;
  DateTime? _targetDate;
  bool _fromDraft = false;

  bool get _editing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final goal = widget.initial;
    _id = goal?.id ?? DateTime.now().microsecondsSinceEpoch.toString();
    _createdAt = goal?.createdAt ?? DateTime.now();
    if (goal != null) {
      _fill(goal);
    } else {
      unawaited(_loadDraft());
    }
  }

  void _fill(SavingsGoal goal) {
    _name.text = goal.name;
    _target.text = formatMoneyInput(goal.targetAmount);
    _description.text = goal.description ?? '';
    _iconKey = goal.iconKey;
    _targetDate = goal.targetDate;
  }

  Future<void> _loadDraft() async {
    final draft = (await widget.draftStore.read()).getOrElse((_) => null);
    if (draft == null || !mounted) return;
    setState(() {
      _fill(draft);
      _fromDraft = true;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    _description.dispose();
    _collected.dispose();
    super.dispose();
  }

  int get _targetSen => parseMoneyInput(_target.text) ?? 0;

  bool get _canSave => _name.text.trim().isNotEmpty && _targetSen > 0;

  SavingsGoal get _goal {
    final description = _description.text.trim();
    final base = widget.initial;
    return SavingsGoal(
      id: _id,
      name: _name.text.trim(),
      targetAmount: _targetSen,
      iconKey: _iconKey,
      walletId: base?.walletId ?? '',
      createdAt: _createdAt,
      status: base?.status ?? SavingsGoalStatus.active,
      targetDate: _targetDate,
      description: description.isEmpty ? null : description,
      completedAt: base?.completedAt,
    );
  }

  Future<void> _save() async {
    if (!_canSave) return;
    final bloc = context.read<SavingsGoalBloc>();
    final limit = ActivePlan.isPlus
        ? null
        : ActivePlan.limits.value.freeSavingsGoals;
    // P11: tujuan Active baru ke-3 di Gratis. Isian tidak hilang (keputusan 4d).
    if (!_editing &&
        limit != null &&
        activeGoalCount(bloc.state.goals) >= limit) {
      await widget.draftStore.save(_goal);
      if (!mounted) return;
      await context.pushRoute(
        PremiumRouteKeys.paywall,
        const PaywallInput(PaywallTrigger.savingsGoalLimit),
      );
      return;
    }
    bloc.add(
      SavingsGoalSaved(
        _goal,
        activeLimit: limit,
        initialAmount: parseMoneyInput(_collected.text) ?? 0,
      ),
    );
  }

  Future<void> _discardDraft() async {
    await widget.draftStore.clear();
    if (!mounted) return;
    setState(() {
      _fromDraft = false;
      _name.clear();
      _target.clear();
      _description.clear();
      _collected.clear();
      _targetDate = null;
      _iconKey = IconKey.walletSavings.name;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime(now.year + 1, now.month, now.day),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 50),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    void refresh(String _) => setState(() {});
    Widget help(String text) => Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: ds.typography.bodySm.copyWith(color: c.textSecondary),
      ),
    );
    return BlocListener<SavingsGoalBloc, SavingsGoalState>(
      listenWhen: (a, b) => a.saveCount != b.saveCount,
      listener: (context, _) async {
        if (!_editing) await widget.draftStore.clear();
        if (context.mounted) Navigator.of(context).maybePop();
      },
      // Rupa formulir mengikuti formulir v2 lain (proyek freelance, dompet):
      // kepala bersama, label bagian, kolom bersama, baris pilihan DsFieldRow.
      child: Scaffold(
        body: SafeArea(
          // Scaffold sudah menyempitkan badan sebesar keyboard; menambah
          // padding keyboard lagi membuat isi terpotong saat keyboard terbuka.
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppFormHeader(
                  title: _editing
                      ? t.assets.goal.formTitleEdit
                      : t.assets.goal.formTitleNew,
                ),
                const SizedBox(height: 16),
                Center(
                  child: DsWiggle(
                    trigger: _iconKey.hashCode,
                    child: savingsGoalTile(_iconKey, size: DsIconTileSize.lg),
                  ),
                ),
                if (_fromDraft) ...[
                  const SizedBox(height: 16),
                  DsInlineBanner(
                    icon: Icons.edit_note,
                    message: t.assets.goal.draftResumed,
                    action: DsButton.ghost(
                      label: t.assets.goal.discardDraft,
                      onPressed: _discardDraft,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                AppSectionLabel(
                  t.assets.goal.nameLabel,
                  hint: t.wallet.nameRequiredHint,
                ),
                const SizedBox(height: 8),
                AppFormTextField(
                  key: const ValueKey('goal-name'),
                  controller: _name,
                  hint: t.assets.goal.nameHint,
                  autofocus: !_editing,
                  onChanged: refresh,
                ),
                const SizedBox(height: 16),
                AppSectionLabel(
                  t.assets.goal.targetLabel,
                  hint: t.wallet.nameRequiredHint,
                ),
                const SizedBox(height: 8),
                AppFormMoneyField(
                  key: const ValueKey('goal-target'),
                  controller: _target,
                  onChanged: refresh,
                  large: true,
                ),
                if (!_editing) ...[
                  const SizedBox(height: 16),
                  AppSectionLabel(t.assets.goal.collectedLabel),
                  const SizedBox(height: 8),
                  AppFormMoneyField(
                    key: const ValueKey('goal-collected'),
                    controller: _collected,
                    onChanged: refresh,
                  ),
                  help(t.assets.goal.goalWalletHelp),
                ],
                const SizedBox(height: 16),
                AppSectionLabel(t.assets.goal.iconLabel),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    for (final (i, icon) in categoryIconChoices.indexed)
                      _IconChoice(
                        iconKey: icon,
                        index: i,
                        selected: icon.name == _iconKey,
                        onTap: () => setState(() => _iconKey = icon.name),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                DsFieldGroup(
                  children: [
                    DsFieldRow(
                      key: const ValueKey('goal-target-date'),
                      icon: Icons.calendar_today_outlined,
                      label: t.assets.goal.targetDateLabel,
                      title: _targetDate == null
                          ? t.assets.goal.targetDateNone
                          : CycleMonthFormatter.formatDate(_targetDate!),
                      placeholder: _targetDate == null,
                      trailing: _targetDate == null
                          ? null
                          : DsIconButton(
                              icon: Icons.close,
                              label: t.assets.goal.targetDateClear,
                              onPressed: () =>
                                  setState(() => _targetDate = null),
                            ),
                      chevron: _targetDate == null,
                      onTap: _pickDate,
                      semanticsLabel: t.assets.goal.targetDateLabel,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppSectionLabel(t.assets.goal.descriptionLabel),
                const SizedBox(height: 8),
                AppFormTextField(
                  controller: _description,
                  hint: t.assets.goal.descriptionHint,
                  maxLength: 120,
                  onChanged: refresh,
                ),
                const SizedBox(height: 24),
                DsButton(
                  key: const ValueKey('goal-save'),
                  label: t.assets.goal.save,
                  expand: true,
                  onPressed: _canSave ? _save : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ubin pilihan ikon, sama seperti pemilih ikon kategori dan dompet.
class _IconChoice extends StatelessWidget {
  const _IconChoice({
    required this.iconKey,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  final IconKey iconKey;
  final int index;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ds.colors;
    final asset = ClayIcons.forIcon(iconKey);
    return Semantics(
      button: true,
      selected: selected,
      label: t.category.iconOption(n: index + 1),
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('goal-icon-${iconKey.name}'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox.square(
          dimension: 48,
          child: Center(
            child: asset == null
                ? AppIconTile(iconKey, selected: selected)
                : DsIconTile.asset(
                    asset: asset,
                    category: selected
                        ? DsColorPair(
                            c.actionPrimary,
                            c.actionPrimary.withValues(alpha: 0.14),
                          )
                        : null,
                  ),
          ),
        ),
      ),
    );
  }
}
