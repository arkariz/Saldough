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
    this.isRollUp = false,
    this.isExpense = false,
    this.rollUpSourceUnavailable = false,
    this.rollUpSourceIsCard = false,
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

  /// False untuk baris `rollUp` — nominalnya tidak bisa disunting/dihapus
  /// langsung (ADR-0008). Hanya mengontrol ikon hapus di sini; [onTap]
  /// tetap dipanggil apa adanya untuk kedua nilai (UX-36/UX-37: baris
  /// `rollUp` tetap bisa diketuk, hanya membuka sheet yang berbeda —
  /// ganti nama, bukan sunting nominal).
  final bool isEditable;

  /// True untuk baris `rollUp` — menampilkan penanda visual (ikon
  /// terhubung berwarna `colors.rollUp`) supaya baris ini terlihat beda
  /// dari baris manual SEBELUM diketuk, bukan baru terasa beda setelah
  /// ketukannya tidak berbuat apa-apa (UX-36).
  final bool isRollUp;

  /// True untuk baris anggaran — nominalnya SELALU disimpan positif, tapi
  /// semantiknya pengeluaran, jadi warnanya dipaksa `expenseOnLight` alih-
  /// alih ikut pewarnaan otomatis `AppMoneyText` (yang akan salah menyangka
  /// nominal positif = pemasukan). Bawaan `false` (baris pemasukan, biarkan
  /// pewarnaan otomatis). Lihat UX-23.
  final bool isExpense;

  /// True kalau baris `rollUp` ini sumbernya belum tersedia.
  final bool rollUpSourceUnavailable;

  /// True kalau sumber roll-up baris ini kartu kredit, false kalau rencana
  /// belanja -- menentukan pesan [rollUpSourceUnavailable] mana yang
  /// tampil (UX-12). Diabaikan kalau [rollUpSourceUnavailable] false.
  final bool rollUpSourceIsCard;

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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      elevation: AppElevation.sm,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(label, overflow: .ellipsis)),
                      if (isRollUp)
                        Padding(
                          padding: const EdgeInsets.only(left: AppSpacing.xs),
                          child: Icon(
                            Icons.link,
                            size: 14,
                            color: colors.rollUp,
                          ),
                        ),
                      if (isTemplate)
                        Padding(
                          padding: const EdgeInsets.only(left: AppSpacing.xs),
                          child: Icon(
                            Icons.repeat,
                            size: 14,
                            color: colors.textMuted,
                          ),
                        ),
                    ],
                  ),
                  if (rollUpSourceUnavailable)
                    Text(
                      rollUpSourceIsCard
                          ? t.cycle.rollUpSourceUnavailableCard
                          : t.cycle.rollUpSourceUnavailableGrocery,
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
                            shout: true,
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
            AppMoneyText(
              sen: amount,
              color: isExpense ? colors.expenseOnLight : null,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (onToggleTemplate != null)
              IconButton(
                tooltip: isTemplate
                    ? t.cycle.markIncidental
                    : t.cycle.markFixed,
                icon: Icon(
                  isTemplate ? Icons.push_pin : Icons.push_pin_outlined,
                ),
                onPressed: onToggleTemplate,
              ),
            if (isEditable && onDelete != null)
              IconButton(
                tooltip: t.common.delete,
                icon: Icon(Icons.delete_outline, color: colors.textMuted),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}
