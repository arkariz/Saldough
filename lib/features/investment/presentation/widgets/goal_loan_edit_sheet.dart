import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/investment/domain/entities/goal_loan.dart';
import 'package:saldough/shared/goal/goal.dart';

/// Bottom sheet tambah/sunting sebuah [GoalLoan] (FR-INV-004). [goals] harus
/// sudah terdaftar — `fromGoalId`/`toGoalId` HANYA boleh memilih dari daftar
/// ini, tidak ada ketik bebas (lihat DOMAIN_MODEL.md bagian "Pos tujuan dan
/// pinjaman").
class GoalLoanEditSheet extends StatefulWidget {
  /// Membuat [GoalLoanEditSheet].
  const GoalLoanEditSheet({required this.goals, this.initial, super.key});

  /// Pos tujuan yang sudah terdaftar, sumber pilihan pos asal/tujuan.
  final List<Goal> goals;

  /// Pinjaman yang disunting, atau `null` kalau menambah baru.
  final GoalLoan? initial;

  /// Menampilkan [GoalLoanEditSheet] sebagai modal bottom sheet,
  /// mengembalikan [GoalLoan] hasil sunting atau `null` kalau dibatalkan.
  static Future<GoalLoan?> show(BuildContext context, {required List<Goal> goals, GoalLoan? initial}) {
    return showModalBottomSheet<GoalLoan>(
      context: context,
      isScrollControlled: true,
      builder: (_) => GoalLoanEditSheet(goals: goals, initial: initial),
    );
  }

  @override
  State<GoalLoanEditSheet> createState() => _GoalLoanEditSheetState();
}

class _GoalLoanEditSheetState extends State<GoalLoanEditSheet> {
  late String? _fromGoalId = widget.initial?.fromGoalId ?? widget.goals.firstOrNull?.id;
  late String? _toGoalId = widget.initial?.toGoalId ??
      widget.goals.where((g) => g.id != _fromGoalId).firstOrNull?.id;
  late DateTime _date = widget.initial?.date ?? DateTime.now();
  late final _principalController = TextEditingController(
    text: widget.initial == null ? '' : (widget.initial!.principal ~/ 100).toString(),
  );
  late final _repaidController = TextEditingController(
    text: widget.initial == null ? '' : (widget.initial!.repaid ~/ 100).toString(),
  );
  late final _noteController = TextEditingController(text: widget.initial?.note ?? '');

  @override
  void dispose() {
    _principalController.dispose();
    _repaidController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    final fromGoalId = _fromGoalId;
    final toGoalId = _toGoalId;
    final principal = int.tryParse(_principalController.text.trim());
    if (fromGoalId == null || toGoalId == null || fromGoalId == toGoalId) return;
    if (principal == null || principal <= 0) return;
    final repaid = int.tryParse(_repaidController.text.trim()) ?? principal;

    final loan = GoalLoan(
      id: widget.initial?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      fromGoalId: fromGoalId,
      toGoalId: toGoalId,
      principal: principal * 100,
      repaid: repaid * 100,
      date: _date,
      note: _noteController.text.trim(),
    );
    Navigator.of(context).pop(loan);
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
              widget.initial == null ? t.investment.addLoanTitle : t.investment.editLoanTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(t.investment.fromGoalFieldHint, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final goal in widget.goals)
                  AppChip(
                    label: goal.name,
                    selected: goal.id == _fromGoalId,
                    onTap: () => setState(() => _fromGoalId = goal.id),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(t.investment.toGoalFieldHint, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final goal in widget.goals)
                  AppChip(
                    label: goal.name,
                    selected: goal.id == _toGoalId,
                    onTap: () => setState(() => _toGoalId = goal.id),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _principalController,
                    keyboardType: .number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(labelText: t.investment.principalFieldHint),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: _repaidController,
                    keyboardType: .number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(labelText: t.investment.repaidFieldHint),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _date = picked);
              },
              child: Text('${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(labelText: t.investment.noteFieldHint),
            ),
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
                Expanded(child: AppButton(label: t.common.save, onPressed: _submit)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
