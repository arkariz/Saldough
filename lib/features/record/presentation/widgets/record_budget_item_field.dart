import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/record/domain/budget_item_catalog.dart';

/// Pos anggaran yang boleh ditawarkan untuk dompet [walletId]: pos anggaran
/// AKTIF milik dompet itu, ditambah [selectedId] kalau sedang dipakai
/// transaksi yang disunting (walau anggarannya sudah selesai/diarsipkan),
/// supaya tautannya tidak hilang diam-diam.
///
/// ⚠ Pengeluaran memberi `walletId`-nya; transfer memberi `fromWalletId`-nya
/// — BUKAN dompet tujuan. Satu transaksi hanya menaikkan satu pos, jadi pos
/// anggaran dompet tujuan tidak pernah ditawarkan (T-4.4).
List<BudgetItemOption> budgetItemChoicesFor(List<BudgetItemOption> all, String? walletId, String? selectedId) => [
  for (final option in all)
    if (option.walletId == walletId && (option.isActive || option.itemId == selectedId)) option,
];

/// Pemilih opsional pos anggaran di formulir pengeluaran dan transfer CATAT
/// (T-4.4, FR-BUD-003). Tidak tampil sama sekali kalau dompet terpilih
/// belum punya pos anggaran aktif — tidak ada yang bisa dipilih.
class RecordBudgetItemField extends StatelessWidget {
  /// Membuat [RecordBudgetItemField].
  const RecordBudgetItemField({required this.choices, required this.selectedId, required this.onSelected, super.key});

  /// Pilihan yang sudah disaring lewat [budgetItemChoicesFor].
  final List<BudgetItemOption> choices;

  /// `itemId` terpilih, atau `null` = tanpa anggaran.
  final String? selectedId;

  /// Dipanggil dengan `itemId` baru, atau `null`.
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    BudgetItemOption? selected;
    for (final option in choices) {
      if (option.itemId == selectedId) selected = option;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionLabel(t.record.budgetItemLabel, hint: t.record.optionalHint),
        const SizedBox(height: AppSpacing.xs),
        AppMenuSelectButton<String>(
          icon: IconKey.budget,
          label: selected == null ? t.record.budgetItemNone : '${selected.itemName} · ${selected.budgetName}',
          isPlaceholder: selected == null,
          wrapLabel: true,
          allLabel: t.record.budgetItemNone,
          allIcon: IconKey.close,
          options: [
            for (final option in choices)
              (value: option.itemId, label: '${option.itemName} · ${option.budgetName}', icon: IconKey.budget),
          ],
          onSelected: onSelected,
        ),
        const SizedBox(height: 4),
        Text(t.record.budgetItemHelp, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textMuted)),
      ],
    );
  }
}
