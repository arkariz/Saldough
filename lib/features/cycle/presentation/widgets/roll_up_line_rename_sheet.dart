import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';

/// Bottom sheet ganti nama baris `rollUp` (UX-37) — satu-satunya jalur
/// penyuntingan yang berlaku untuk baris ini. Nominalnya tetap dihitung
/// dari sumbernya (ADR-0008); sheet ini sengaja TIDAK punya field nominal
/// sama sekali, supaya tidak ada jalan menyuntingnya secara langsung.
class RollUpLineRenameSheet extends StatefulWidget {
  /// Membuat [RollUpLineRenameSheet].
  const RollUpLineRenameSheet({required this.initialLabel, super.key});

  /// Nama baris saat ini.
  final String initialLabel;

  /// Menampilkan [RollUpLineRenameSheet] sebagai modal bottom sheet,
  /// mengembalikan nama baru atau `null` kalau dibatalkan.
  static Future<String?> show(BuildContext context, {required String initialLabel}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => RollUpLineRenameSheet(initialLabel: initialLabel),
    );
  }

  @override
  State<RollUpLineRenameSheet> createState() => _RollUpLineRenameSheetState();
}

class _RollUpLineRenameSheetState extends State<RollUpLineRenameSheet> {
  late final _labelController = TextEditingController(text: widget.initialLabel);

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  bool get _canSubmit => _labelController.text.trim().isNotEmpty;

  void _submit() {
    final label = _labelController.text.trim();
    if (label.isEmpty) return;
    Navigator.of(context).pop(label);
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
            Text(t.cycle.renameRollUpLineTitle, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(t.cycle.rollUpNotEditable, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _labelController,
              autofocus: true,
              decoration: InputDecoration(labelText: t.cycle.labelFieldHint),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
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
