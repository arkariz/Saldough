import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/record/presentation/widgets/record_choice.dart';

/// Lembar pilihan yang muncul saat CATAT ditekan (FR-REC-001) — tiga
/// pilihan: catat pemasukan, catat pengeluaran, catat transfer. Memilih
/// satu menutup lembar ini dan mengembalikan [RecordChoice]-nya; pemanggil
/// (`AppShellPage`) yang membuka formulir berikutnya.
class RecordChoiceSheet extends StatelessWidget {
  /// Membuat [RecordChoiceSheet].
  const RecordChoiceSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.record.sheetTitle, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            _ChoiceTile(
              icon: IconKey.income,
              label: t.record.incomeAction,
              onTap: () => Navigator.of(context).pop(RecordChoice.income),
            ),
            _ChoiceTile(
              icon: IconKey.expense,
              label: t.record.expenseAction,
              onTap: () => Navigator.of(context).pop(RecordChoice.expense),
            ),
            _ChoiceTile(
              icon: IconKey.transfer,
              label: t.record.transferAction,
              onTap: () => Navigator.of(context).pop(RecordChoice.transfer),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({required this.icon, required this.label, required this.onTap});

  final IconKey icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: AppIcon(icon, size: 32),
      title: Text(label),
      onTap: onTap,
    );
  }
}
