import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/shared/budget_catalog/budget_catalog.dart';

/// Apakah [option] boleh ditawarkan ke transaksi bertanggal [date]:
/// periodenya mencakup [date] (keputusan KT-1), dan anggarannya tidak
/// diarsipkan — kecuali pos itu [selectedId] milik transaksi yang disunting,
/// supaya tautannya tidak hilang diam-diam.
bool _offeredOn(BudgetItemOption option, DateTime date, String? selectedId) =>
    option.covers(date) && (!option.isArchived || option.itemId == selectedId);

/// Pos PENGELUARAN yang boleh ditawarkan ke pengeluaran dari [walletId] pada
/// [date] (lihat [_offeredOn]). Pos transfer tidak pernah ditawarkan ke
/// pengeluaran (ADR-018).
List<BudgetItemOption> expenseBudgetChoicesFor(
  List<BudgetItemOption> all,
  String? walletId,
  String? selectedId,
  DateTime date,
) => [
  for (final option in all)
    if (!option.isTransfer && option.walletId == walletId && _offeredOn(option, date, selectedId)) option,
];

/// Pos TRANSFER yang boleh ditawarkan ke transfer dari [fromWalletId] ke
/// [toWalletId]: dompet anggarannya harus dompet asal DAN dompet tujuan posnya
/// harus dompet tujuan transfer (ADR-018), dan periodenya mencakup [date]
/// (lihat [_offeredOn]). Satu transaksi hanya menaikkan satu pos, jadi pos
/// anggaran milik dompet tujuan tidak pernah ditawarkan.
List<BudgetItemOption> transferBudgetChoicesFor(
  List<BudgetItemOption> all,
  String? fromWalletId,
  String? toWalletId,
  String? selectedId,
  DateTime date,
) => [
  for (final option in all)
    if (option.isTransfer &&
        option.walletId == fromWalletId &&
        option.transferToWalletId == toWalletId &&
        _offeredOn(option, date, selectedId))
      option,
];

/// Pos [selectedId] kalau tautannya lepas HANYA karena [date] di luar periode
/// anggarannya — formulir memberi tahu pemakai, tidak diam-diam (KT-1).
BudgetItemOption? budgetItemOutsidePeriod(List<BudgetItemOption> all, String? selectedId, DateTime date) {
  for (final option in all) {
    if (option.itemId == selectedId && !option.covers(date)) return option;
  }
  return null;
}

/// Pemberitahuan di bawah tanggal saat tautan ke [option] lepas karena
/// tanggal transaksi keluar dari periode anggarannya (KT-1). Tautannya
/// kembali sendiri kalau tanggalnya dikembalikan ke dalam periode.
class RecordBudgetItemOutOfPeriodNotice extends StatelessWidget {
  /// Membuat [RecordBudgetItemOutOfPeriodNotice].
  const RecordBudgetItemOutOfPeriodNotice({required this.option, super.key});

  /// Pos yang tautannya lepas.
  final BudgetItemOption option;

  @override
  Widget build(BuildContext context) {
    return Text(
      t.record.budgetItemOutOfPeriod(name: option.budgetName),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.appColors.warning),
    );
  }
}

/// Pemilih opsional pos anggaran di formulir pengeluaran dan transfer CATAT
/// (T-4.4, FR-BUD-003). Tidak tampil sama sekali kalau tidak ada pos yang
/// cocok — tidak ada yang bisa dipilih.
class RecordBudgetItemField extends StatelessWidget {
  /// Membuat [RecordBudgetItemField].
  const RecordBudgetItemField({required this.choices, required this.selectedId, required this.onSelected, super.key});

  /// Pilihan yang sudah disaring lewat [expenseBudgetChoicesFor] atau
  /// [transferBudgetChoicesFor].
  final List<BudgetItemOption> choices;

  /// `itemId` terpilih, atau `null` = tanpa anggaran.
  final String? selectedId;

  /// Dipanggil dengan `itemId` baru, atau `null`.
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    BudgetItemOption? selected;
    for (final option in choices) {
      if (option.itemId == selectedId) selected = option;
    }
    return AppMenuSelectButton<String>(
      fieldLabel: '${t.record.budgetItemLabel} (${t.record.optionalHint.toLowerCase()})',
      rowIcon: IconKey.budget,
      icon: IconKey.budget,
      label: selected == null ? t.record.budgetItemNone : '${selected.budgetName} · ${selected.itemName}',
      isPlaceholder: selected == null,
      wrapLabel: true,
      allLabel: t.record.budgetItemNone,
      allIcon: IconKey.close,
      options: [
        for (final option in choices)
          (value: option.itemId, label: '${option.itemName} · ${option.budgetName}', icon: IconKey.budget),
      ],
      onSelected: onSelected,
    );
  }
}
