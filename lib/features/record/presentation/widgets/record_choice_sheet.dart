import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/record/presentation/widgets/record_choice.dart';

/// Lembar pilihan yang muncul saat CATAT ditekan (FR-REC-001) — tiga
/// pilihan: catat pemasukan, catat pengeluaran, catat transfer. Memilih
/// satu menutup lembar ini dan mengembalikan [RecordChoice]-nya; pemanggil
/// (`AppShellPage`) yang membuka formulir berikutnya.
///
/// Memuat banner yang menyatakan prinsip produk paling dasar Saldough --
/// aplikasi ini MENCATAT, bukan MELAKUKAN, tidak pernah memindahkan uang
/// sendiri -- sebelumnya tidak disebutkan di mana pun dalam alur CATAT.
class RecordChoiceSheet extends StatelessWidget {
  /// Membuat [RecordChoiceSheet].
  const RecordChoiceSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      t.record.sheetTitle,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              AppHardCard(
                elevation: AppHardElevation.flat,
                color: colors.pending.withValues(alpha: 0.12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: colors.pending, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        t.record.disclaimerMessage,
                        style: TextStyle(color: colors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _ChoiceTile(
                icon: IconKey.income,
                color: colors.income,
                label: t.record.incomeAction,
                subtitle: t.record.incomeSubtitle,
                effectLabel: t.record.incomeEffectLabel,
                onTap: () => Navigator.of(context).pop(RecordChoice.income),
              ),
              const SizedBox(height: AppSpacing.sm),
              _ChoiceTile(
                icon: IconKey.expense,
                color: colors.expense,
                label: t.record.expenseAction,
                subtitle: t.record.expenseSubtitle,
                effectLabel: t.record.expenseEffectLabel,
                onTap: () => Navigator.of(context).pop(RecordChoice.expense),
              ),
              const SizedBox(height: AppSpacing.sm),
              _ChoiceTile(
                icon: IconKey.transfer,
                color: colors.transfer,
                label: t.record.transferAction,
                subtitle: t.record.transferSubtitle,
                effectLabel: t.record.transferEffectLabel,
                onTap: () => Navigator.of(context).pop(RecordChoice.transfer),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.subtitle,
    required this.effectLabel,
    required this.onTap,
  });

  final IconKey icon;
  final Color color;
  final String label;
  final String subtitle;
  final String effectLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: AppHardCard(
        elevation: AppHardElevation.interactive,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: AppIcon(icon, size: 28),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.titleMedium),
                  Text(subtitle, style: TextStyle(color: colors.textMuted)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    effectLabel,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
