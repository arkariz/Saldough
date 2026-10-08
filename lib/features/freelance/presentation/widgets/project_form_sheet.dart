import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/freelance/domain/entities/deduction_kind.dart';
import 'package:saldough/features/freelance/domain/entities/deduction_rule.dart';
import 'package:saldough/features/freelance/domain/entities/freelance_project.dart';
import 'package:saldough/features/freelance/presentation/freelance_format.dart';

/// Hasil [ProjectFormSheet]; `null` berarti dibatalkan.
sealed class ProjectFormResult {
  /// Membuat [ProjectFormResult].
  const ProjectFormResult();
}

/// Proyek disimpan.
final class ProjectFormSaved extends ProjectFormResult {
  /// Membuat [ProjectFormSaved].
  const ProjectFormSaved({required this.name, required this.hourlyRate, required this.deductionRules});

  /// Nama proyek.
  final String name;

  /// Tarif per jam bawaan, sen.
  final int hourlyRate;

  /// Potongan bawaan.
  final List<DeductionRule> deductionRules;
}

/// Proyek dihapus.
final class ProjectFormDeleted extends ProjectFormResult {
  /// Membuat [ProjectFormDeleted].
  const ProjectFormDeleted();
}

/// Formulir proyek freelance (FR-FRL-001): nama, tarif per jam bawaan, dan
/// potongan bawaan.
///
/// Tarif dan potongan adalah nilai BAWAAN untuk entri dan pembayaran
/// berikutnya; mengubahnya tidak mengubah yang sudah tercatat (ADR-019).
/// Tombol hapus hanya muncul kalau [canDelete] (proyek belum punya entri).
class ProjectFormSheet extends StatefulWidget {
  /// Membuat [ProjectFormSheet]. [initial] `null` = proyek baru.
  const ProjectFormSheet({this.initial, this.canDelete = false, super.key});

  /// Proyek yang disunting.
  final FreelanceProject? initial;

  /// Proyek boleh dihapus.
  final bool canDelete;

  @override
  State<ProjectFormSheet> createState() => _ProjectFormSheetState();
}

class _ProjectFormSheetState extends State<ProjectFormSheet> {
  final _name = TextEditingController();
  final _rate = TextEditingController();
  List<DeductionRule> _deductions = const [];

  @override
  void initState() {
    super.initState();
    final project = widget.initial;
    if (project == null) return;
    _name.text = project.name;
    _rate.text = AppFormMoneyField.initialText(project.hourlyRate);
    _deductions = project.deductionRules;
  }

  @override
  void dispose() {
    _name.dispose();
    _rate.dispose();
    super.dispose();
  }

  bool get _canSave => _name.text.trim().isNotEmpty && AppFormMoneyField.senOf(_rate) != null;

  Future<void> _editDeduction([int? index]) async {
    final result = await showFullScreenSheet<Object>(
      context,
      builder: (_) => _DeductionFormSheet(initial: index == null ? null : _deductions[index]),
    );
    if (!mounted) return;
    setState(() {
      switch (result) {
        case final DeductionRule rule when index == null:
          _deductions = [..._deductions, rule];
        case final DeductionRule rule:
          _deductions = [..._deductions]..[index!] = rule;
        case _DeductionRemoved() when index != null:
          _deductions = [..._deductions]..removeAt(index);
        case _:
          break;
      }
    });
  }

  void _save() {
    if (!_canSave) return;
    Navigator.of(context).pop(
      ProjectFormSaved(
        name: _name.text.trim(),
        hourlyRate: AppFormMoneyField.senOf(_rate)!,
        deductionRules: _deductions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final editing = widget.initial != null;
    void refresh(String _) => setState(() {});
    return SizedBox.expand(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.space4, AppSpacing.space4, AppSpacing.space4, AppSpacing.space6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppFormHeader(
                title: editing ? t.freelance.projectEditTitle : t.freelance.projectAddTitle,
              ),
              const SizedBox(height: AppSpacing.space4),
              AppSectionLabel(t.freelance.projectNameLabel, hint: t.freelance.requiredHint),
              const SizedBox(height: AppSpacing.space1),
              AppFormTextField(
                controller: _name,
                hint: t.freelance.projectNameHint,
                autofocus: !editing,
                onChanged: refresh,
              ),
              const SizedBox(height: AppSpacing.space4),
              AppSectionLabel(t.freelance.hourlyRateLabel, hint: t.freelance.requiredHint),
              const SizedBox(height: AppSpacing.space1),
              AppFormMoneyField(controller: _rate, onChanged: refresh, large: true),
              const SizedBox(height: 4),
              Text(
                t.freelance.hourlyRateHelp,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.ink2),
              ),
              const SizedBox(height: AppSpacing.space4),
              AppSectionLabel(t.freelance.deductionsLabel),
              const SizedBox(height: 2),
              Text(
                t.freelance.deductionsHelp,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.ink2),
              ),
              const SizedBox(height: AppSpacing.space1),
              for (final (index, rule) in _deductions.indexed) ...[
                _DeductionRow(rule: rule, onTap: () => _editDeduction(index)),
                const SizedBox(height: AppSpacing.space1),
              ],
              AppButton.secondary(label: t.freelance.deductionAddAction, onPressed: _editDeduction),
              const SizedBox(height: AppSpacing.space6),
              AppButton(label: t.freelance.projectSaveAction, onPressed: _canSave ? _save : null),
              if (editing && widget.canDelete) ...[
                const SizedBox(height: AppSpacing.space4),
                AppButton.danger(
                  label: t.freelance.projectDeleteAction,
                  onPressed: () => Navigator.of(context).pop(const ProjectFormDeleted()),
                ),
              ] else if (editing) ...[
                const SizedBox(height: AppSpacing.space2),
                Text(
                  t.freelance.projectDeleteLockedHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.ink2),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DeductionRow extends StatelessWidget {
  const _DeductionRow({required this.rule, required this.onTap});

  final DeductionRule rule;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AppCard(
        child: Row(
          children: [
            Expanded(child: Text(describeDeduction(rule), style: Theme.of(context).textTheme.bodyLarge)),
            AppIcon(IconKey.edit, size: 18, color: colors.ink2),
          ],
        ),
      ),
    );
  }
}

/// Penanda hasil "hapus potongan" dari [_DeductionFormSheet].
final class _DeductionRemoved {
  const _DeductionRemoved();
}

/// Formulir satu potongan: label, jenis (persen atau nominal tetap), nilai.
/// Mengembalikan [DeductionRule] atau [_DeductionRemoved].
class _DeductionFormSheet extends StatefulWidget {
  const _DeductionFormSheet({this.initial});

  final DeductionRule? initial;

  @override
  State<_DeductionFormSheet> createState() => _DeductionFormSheetState();
}

class _DeductionFormSheetState extends State<_DeductionFormSheet> {
  final _label = TextEditingController();
  final _percent = TextEditingController();
  final _amount = TextEditingController();
  DeductionKind _kind = DeductionKind.percentage;

  @override
  void initState() {
    super.initState();
    final rule = widget.initial;
    if (rule == null) return;
    _label.text = rule.label;
    _kind = rule.kind;
    if (rule.kind == DeductionKind.percentage) {
      _percent.text = formatPerMilAsPercent(rule.value);
    } else {
      _amount.text = AppFormMoneyField.initialText(rule.value);
    }
  }

  @override
  void dispose() {
    _label.dispose();
    _percent.dispose();
    _amount.dispose();
    super.dispose();
  }

  int? get _value =>
      _kind == DeductionKind.percentage ? parsePercentToPerMil(_percent.text) : AppFormMoneyField.senOf(_amount);

  bool get _canSave => _label.text.trim().isNotEmpty && _value != null;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final editing = widget.initial != null;
    void refresh(String _) => setState(() {});
    return SizedBox.expand(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.space4, AppSpacing.space4, AppSpacing.space4, AppSpacing.space6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppFormHeader(title: t.freelance.deductionTitle),
              const SizedBox(height: AppSpacing.space4),
              AppSectionLabel(t.freelance.deductionLabelLabel, hint: t.freelance.requiredHint),
              const SizedBox(height: AppSpacing.space1),
              AppFormTextField(
                controller: _label,
                hint: t.freelance.deductionLabelHint,
                autofocus: !editing,
                onChanged: refresh,
              ),
              const SizedBox(height: AppSpacing.space4),
              AppSegmentedControl<DeductionKind>(
                options: [
                  (DeductionKind.percentage, t.freelance.deductionKindPercentage),
                  (DeductionKind.fixedAmount, t.freelance.deductionKindFixed),
                ],
                selected: _kind,
                onChanged: (kind) => setState(() => _kind = kind),
              ),
              const SizedBox(height: AppSpacing.space4),
              if (_kind == DeductionKind.percentage) ...[
                AppSectionLabel(t.freelance.deductionPercentLabel),
                const SizedBox(height: AppSpacing.space1),
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space2),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _percent,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          cursorColor: colors.brand,
                          onChanged: refresh,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            filled: false,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            hintText: formatPerMilAsPercent(25),
                            hintStyle: TextStyle(color: colors.ink2.withValues(alpha: 0.5)),
                          ),
                        ),
                      ),
                      Text('%', style: context.numberStyles.amount.copyWith(color: colors.brand)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  t.freelance.deductionPercentHelp,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.ink2),
                ),
              ] else ...[
                AppSectionLabel(t.freelance.deductionAmountLabel),
                const SizedBox(height: AppSpacing.space1),
                AppFormMoneyField(controller: _amount, onChanged: refresh),
              ],
              const SizedBox(height: AppSpacing.space6),
              AppButton(
                label: t.freelance.deductionSaveAction,
                onPressed: _canSave
                    ? () => Navigator.of(context).pop(
                        DeductionRule(
                          id: widget.initial?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
                          label: _label.text.trim(),
                          kind: _kind,
                          value: _value!,
                        ),
                      )
                    : null,
              ),
              if (editing) ...[
                const SizedBox(height: AppSpacing.space4),
                AppButton.danger(
                  label: t.freelance.deductionRemoveAction,
                  onPressed: () => Navigator.of(context).pop(const _DeductionRemoved()),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
