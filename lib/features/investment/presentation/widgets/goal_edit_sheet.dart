import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/shared/goal/goal.dart';

/// Bottom sheet tambah/sunting sebuah [Goal] (FR-INV-001).
class GoalEditSheet extends StatefulWidget {
  /// Membuat [GoalEditSheet].
  const GoalEditSheet({this.initial, super.key});

  /// Pos yang disunting, atau `null` kalau menambah baru.
  final Goal? initial;

  /// Menampilkan [GoalEditSheet] sebagai modal bottom sheet, mengembalikan
  /// [Goal] hasil sunting atau `null` kalau dibatalkan.
  static Future<Goal?> show(BuildContext context, {Goal? initial}) {
    return showModalBottomSheet<Goal>(
      context: context,
      isScrollControlled: true,
      builder: (_) => GoalEditSheet(initial: initial),
    );
  }

  @override
  State<GoalEditSheet> createState() => _GoalEditSheetState();
}

class _GoalEditSheetState extends State<GoalEditSheet> {
  late final _nameController = TextEditingController(text: widget.initial?.name ?? '');
  late final _openingBalanceController = TextEditingController(
    text: ((widget.initial?.openingBalance ?? 0) ~/ 100).toString(),
  );

  @override
  void dispose() {
    _nameController.dispose();
    _openingBalanceController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final goal = Goal(
      id: widget.initial?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      openingBalance: (int.tryParse(_openingBalanceController.text.trim()) ?? 0) * 100,
    );
    Navigator.of(context).pop(goal);
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
              widget.initial == null ? t.investment.addGoalTitle : t.investment.editGoalTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(labelText: t.investment.goalNameFieldHint),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _openingBalanceController,
              keyboardType: .number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: t.investment.openingBalanceFieldHint),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(label: t.common.save, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
