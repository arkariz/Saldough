import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';

/// Satu baris pemasukan atau anggaran di [CyclePage].
class CycleLineTile extends StatelessWidget {
  /// Membuat [CycleLineTile].
  const CycleLineTile({
    required this.label,
    required this.amount,
    required this.isTemplate,
    required this.needsReview,
    this.isEditable = true,
    this.rollUpSourceUnavailable = false,
    this.onTap,
    this.onDelete,
    this.onToggleTemplate,
    this.onConfirmReview,
    super.key,
  });

  /// Nama baris.
  final String label;

  /// Nominal dalam sen.
  final int amount;

  /// True kalau baris ini ikut terbawa saat rollover.
  final bool isTemplate;

  /// True kalau baris ini hasil rollover yang belum dikonfirmasi.
  final bool needsReview;

  /// False untuk baris `rollUp` — tidak bisa disunting/dihapus langsung
  /// (ADR-0008).
  final bool isEditable;

  /// True kalau baris `rollUp` ini sumbernya belum tersedia.
  final bool rollUpSourceUnavailable;

  /// Dipanggil saat baris diketuk untuk disunting. `null` kalau tidak bisa.
  final VoidCallback? onTap;

  /// Dipanggil saat tombol hapus ditekan.
  final VoidCallback? onDelete;

  /// Dipanggil saat status tetap/insidental ditukar.
  final VoidCallback? onToggleTemplate;

  /// Dipanggil saat baris dikonfirmasi benar (melepas [needsReview]).
  final VoidCallback? onConfirmReview;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      elevation: AppElevation.sm,
      child: InkWell(
        onTap: isEditable ? onTap : null,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(label, overflow: .ellipsis)),
                      if (isTemplate)
                        Padding(
                          padding: const EdgeInsets.only(left: AppSpacing.xs),
                          child: Icon(Icons.repeat, size: 14, color: colors.textMuted),
                        ),
                    ],
                  ),
                  if (rollUpSourceUnavailable)
                    Text(
                      t.cycle.rollUpSourceUnavailable,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  if (needsReview)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Row(
                        mainAxisSize: .min,
                        children: [
                          AppChip(
                            label: t.cycle.needsReviewBadge,
                            selected: true,
                            color: colors.needsReview,
                          ),
                          if (onConfirmReview != null)
                            TextButton(
                              onPressed: onConfirmReview,
                              child: Text(t.cycle.confirmReviewed),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            AppMoneyText(sen: amount, style: Theme.of(context).textTheme.titleMedium),
            if (onToggleTemplate != null)
              IconButton(
                tooltip: isTemplate ? t.cycle.markIncidental : t.cycle.markFixed,
                icon: Icon(isTemplate ? Icons.push_pin : Icons.push_pin_outlined),
                onPressed: onToggleTemplate,
              ),
            if (isEditable && onDelete != null)
              IconButton(
                tooltip: t.common.delete,
                icon: Icon(Icons.delete_outline, color: colors.expense),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}
