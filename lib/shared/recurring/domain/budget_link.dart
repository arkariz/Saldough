import 'package:saldough/shared/budget_catalog/budget_catalog.dart';
import 'package:saldough/shared/recurring/domain/recurring_rule.dart';

/// Pos anggaran rutin yang boleh ditautkan ke [rule] (ADR-036 §3.4): rutin
/// pengeluaran, pos pengeluaran bertemplate berdompet sama. Satu entri per
/// kunci pos, dari periode terbaru (namanya yang dipakai untuk label).
List<BudgetItemOption> linkableBudgetItems(RecurringRule rule, Iterable<BudgetItemOption> options) {
  if (rule.kind != RecurringKind.expense) return const [];
  final latest = <String, BudgetItemOption>{};
  for (final option in options) {
    final key = option.templateItemId;
    if (key == null || option.isTransfer || option.walletId != rule.walletId) continue;
    final current = latest[key];
    if (current == null || option.startDate.isAfter(current.startDate)) latest[key] = option;
  }
  return latest.values.toList()..sort((a, b) => a.itemName.toLowerCase().compareTo(b.itemName.toLowerCase()));
}

/// Pos yang ditautkan [rule] (`budgetItemKey`) di periode terbaru, untuk
/// label; `null` bila tidak tertaut atau posnya sudah tidak ada.
BudgetItemOption? linkedBudgetItem(RecurringRule rule, Iterable<BudgetItemOption> options) =>
    linkableBudgetItems(rule, options).where((o) => o.templateItemId == rule.budgetItemKey).firstOrNull;

/// `BudgetItem.id` pos periode yang mencakup kemunculan [date] dari rutin
/// tertaut [rule], atau `null` bila tidak tertaut atau periodenya belum lahir.
String? budgetItemForOccurrence(RecurringRule rule, DateTime date, Iterable<BudgetItemOption> options) {
  final key = rule.budgetItemKey;
  if (key == null || rule.kind != RecurringKind.expense) return null;
  return options
      .where((o) => o.templateItemId == key && o.walletId == rule.walletId && !o.isArchived && o.covers(date))
      .firstOrNull
      ?.itemId;
}

/// Saran tautan E9 sesudah rutin pengeluaran baru disimpan: satu-satunya pos
/// rutin berdompet sama yang namanya sama (tanpa beda huruf besar dan spasi)
/// dengan catatan rutin, atau, bila tidak ada, yang nominal rencananya sama.
/// Tidak pernah ditautkan otomatis.
BudgetItemOption? suggestBudgetLink(RecurringRule rule, Iterable<BudgetItemOption> options) {
  if (rule.budgetItemKey != null) return null;
  String norm(String s) => s.toLowerCase().replaceAll(RegExp(r'\s+'), '');
  final candidates = linkableBudgetItems(rule, options);
  final byName = [
    for (final o in candidates)
      if (rule.note.trim().isNotEmpty && norm(o.itemName) == norm(rule.note)) o,
  ];
  if (byName.length == 1) return byName.single;
  if (byName.length > 1) return null;
  final byAmount = [
    for (final o in candidates)
      if (o.plannedAmount == rule.amount) o,
  ];
  return byAmount.length == 1 ? byAmount.single : null;
}
