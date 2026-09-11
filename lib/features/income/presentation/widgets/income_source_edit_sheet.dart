import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/shared/income/income.dart';

/// Bottom sheet tambah/sunting sebuah [IncomeSource], termasuk aturan
/// potongannya (FR-INC-001, FR-INC-003).
class IncomeSourceEditSheet extends StatefulWidget {
  /// Membuat [IncomeSourceEditSheet].
  const IncomeSourceEditSheet({this.initial, super.key});

  /// Sumber yang disunting, atau `null` kalau menambah baru.
  final IncomeSource? initial;

  /// Menampilkan [IncomeSourceEditSheet] sebagai modal bottom sheet,
  /// mengembalikan [IncomeSource] hasil sunting atau `null` kalau dibatalkan.
  static Future<IncomeSource?> show(BuildContext context, {IncomeSource? initial}) {
    return showModalBottomSheet<IncomeSource>(
      context: context,
      isScrollControlled: true,
      builder: (_) => IncomeSourceEditSheet(initial: initial),
    );
  }

  @override
  State<IncomeSourceEditSheet> createState() => _IncomeSourceEditSheetState();
}

class _IncomeSourceEditSheetState extends State<IncomeSourceEditSheet> {
  late final _nameController = TextEditingController(text: widget.initial?.name ?? '');
  late final _fixedAmountController = TextEditingController(
    text: widget.initial?.fixedAmount == null ? '' : (widget.initial!.fixedAmount! ~/ 100).toString(),
  );
  late final _hourlyRateController = TextEditingController(
    text: widget.initial?.hourlyRate == null ? '' : (widget.initial!.hourlyRate! ~/ 100).toString(),
  );
  late IncomeSourceKind _kind = widget.initial?.kind ?? .fixedSalary;
  late List<DeductionRule> _rules = List.of(widget.initial?.deductionRules ?? const []);

  @override
  void dispose() {
    _nameController.dispose();
    _fixedAmountController.dispose();
    _hourlyRateController.dispose();
    super.dispose();
  }

  void _addRule() {
    setState(() => _rules = [
          ..._rules,
          DeductionRule(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            label: '',
            kind: .percentage,
            value: 0,
          ),
        ]);
  }

  void _removeRule(String id) => setState(() => _rules = _rules.where((r) => r.id != id).toList());

  void _updateRule(DeductionRule updated) {
    setState(() => _rules = _rules.map((r) => r.id == updated.id ? updated : r).toList());
  }

  /// Gerbang tombol Simpan -- dinonaktifkan (bukan diam-diam menolak submit)
  /// saat nama belum diisi (UX-03), atau saat nominal yang relevan dengan
  /// [_kind] belum valid (UX-05: sebelumnya field ini boleh kosong dan
  /// tersimpan diam-diam sebagai Rp 0 -- untuk sumber baru field ini memang
  /// mulai KOSONG, bukan "0", jadi risikonya nyata: tarif per jam Rp 0
  /// berarti seluruh gaji bersih freelance jadi Rp 0 tanpa pemberitahuan).
  bool get _canSubmit {
    if (_nameController.text.trim().isEmpty) return false;
    return switch (_kind) {
      .fixedSalary => int.tryParse(_fixedAmountController.text.trim()) != null,
      .hourlyFreelance => int.tryParse(_hourlyRateController.text.trim()) != null,
      .adHoc => true,
    };
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final source = IncomeSource(
      id: widget.initial?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      kind: _kind,
      fixedAmount: _kind == .fixedSalary ? (int.tryParse(_fixedAmountController.text.trim()) ?? 0) * 100 : null,
      hourlyRate: _kind == .hourlyFreelance ? (int.tryParse(_hourlyRateController.text.trim()) ?? 0) * 100 : null,
      deductionRules: _kind == .hourlyFreelance ? _rules : const [],
    );
    Navigator.of(context).pop(source);
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
              widget.initial == null ? t.income.addSourceTitle : t.income.editSourceTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(labelText: t.income.nameFieldHint),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final kind in IncomeSourceKind.values)
                  AppChip(
                    label: switch (kind) {
                      .fixedSalary => t.income.kindFixedSalary,
                      .hourlyFreelance => t.income.kindHourlyFreelance,
                      .adHoc => t.income.kindAdHoc,
                    },
                    selected: kind == _kind,
                    onTap: () => setState(() => _kind = kind),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_kind == .fixedSalary)
              TextField(
                controller: _fixedAmountController,
                keyboardType: .number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(labelText: t.income.fixedAmountFieldHint),
                onChanged: (_) => setState(() {}),
              ),
            if (_kind == .hourlyFreelance) ...[
              TextField(
                controller: _hourlyRateController,
                keyboardType: .number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(labelText: t.income.hourlyRateFieldHint),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(t.income.deductionRulesTitle, style: Theme.of(context).textTheme.titleMedium),
              for (final rule in _rules)
                _DeductionRuleRow(rule: rule, onChanged: _updateRule, onRemoved: () => _removeRule(rule.id)),
              const SizedBox(height: AppSpacing.sm),
              AppButton(label: t.income.addDeductionRuleButton, icon: Icons.add, onPressed: _addRule),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(t.common.cancel),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(label: t.common.save, onPressed: _canSubmit ? _submit : null),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DeductionRuleRow extends StatefulWidget {
  const _DeductionRuleRow({required this.rule, required this.onChanged, required this.onRemoved});

  final DeductionRule rule;
  final ValueChanged<DeductionRule> onChanged;
  final VoidCallback onRemoved;

  @override
  State<_DeductionRuleRow> createState() => _DeductionRuleRowState();
}

class _DeductionRuleRowState extends State<_DeductionRuleRow> {
  late final _labelController = TextEditingController(text: widget.rule.label);
  late final _valueController = TextEditingController(text: widget.rule.value.toString());

  @override
  void dispose() {
    _labelController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _labelController,
              decoration: InputDecoration(labelText: t.income.deductionLabelHint),
              onChanged: (value) => widget.onChanged(widget.rule.copyWith(label: value)),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          AppChip(
            label: widget.rule.kind == .percentage ? t.income.deductionKindPermille : t.income.deductionKindFixed,
            selected: true,
            onTap: () => widget.onChanged(
              widget.rule.copyWith(kind: widget.rule.kind == .percentage ? .fixedAmount : .percentage),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          SizedBox(
            width: 72,
            child: TextField(
              controller: _valueController,
              keyboardType: .number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: t.income.deductionValueHint),
              onChanged: (value) => widget.onChanged(widget.rule.copyWith(value: int.tryParse(value) ?? 0)),
            ),
          ),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: widget.onRemoved),
        ],
      ),
    );
  }
}
