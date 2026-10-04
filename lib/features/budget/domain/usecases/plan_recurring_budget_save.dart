import 'package:saldough/features/budget/domain/entities/budget.dart';
import 'package:saldough/features/budget/domain/entities/budget_schedule.dart';
import 'package:saldough/features/budget/domain/entities/budget_template.dart';

/// Lingkup perubahan anggaran rutin (ADR-036 §3.3).
enum BudgetEditScope {
  /// Hanya anggaran periode ini; template tidak berubah.
  thisPeriod,

  /// Periode ini dan berikutnya: template ikut disamakan dengan anggaran ini.
  thisAndNext,
}

/// Yang perlu ditulis sesudah formulir anggaran disimpan: anggarannya, dan
/// template berjadwal bila ikut berubah.
typedef RecurringBudgetSave = ({Budget budget, BudgetTemplate? template});

/// Rencana simpan anggaran dengan sakelar **Ulangi tiap periode** (ADR-036
/// §3.1, §3.3). [budget] adalah hasil formulir; [template] adalah template
/// asalnya (`budget.templateId`) bila ada.
///
/// - Ulangi mati: template berjadwal dimatikan (`isActive = false`), anggaran
///   tetap ada dengan `templateId`-nya.
/// - Ulangi baru dinyalakan (template belum ada atau jadwalnya mati): template
///   disamakan dengan anggaran ini, berpatokan tanggal awalnya.
/// - Sudah rutin: [BudgetEditScope.thisPeriod] tidak menyentuh template;
///   [BudgetEditScope.thisAndNext] menyamakan template dengan anggaran ini:
///   pos bertemplate diperbarui, pos baru masuk dengan kunci baru, pos yang
///   dihapus keluar dari template.
///
/// Anggaran yang tidak boleh diulang (`BudgetSchedule.canRepeat`) diperlakukan
/// seperti Ulangi mati.
RecurringBudgetSave planRecurringBudgetSave({
  required Budget budget,
  required bool repeat,
  required BudgetEditScope scope,
  required String Function() newId,
  BudgetTemplate? template,
}) {
  final scheduled = template?.isScheduled ?? false;
  if (!repeat || !BudgetSchedule.canRepeat(budget.period, budget.startDate)) {
    if (!scheduled) return (budget: budget, template: null);
    return (
      budget: budget,
      template: template!.copyWith(schedule: () => template.schedule!.copyWith(isActive: false)),
    );
  }
  if (scheduled && scope == BudgetEditScope.thisPeriod) return (budget: budget, template: null);

  final keyed = [for (final item in budget.items) item.copyWith(templateItemId: () => item.templateItemId ?? newId())];
  final templateId = template?.id ?? newId();
  return (
    budget: budget.copyWith(templateId: () => templateId, items: keyed),
    template: BudgetTemplate(
      id: templateId,
      name: budget.name,
      items: [for (final item in keyed) item.copyWith(id: item.templateItemId, templateItemId: () => null)],
      isEnabled: template?.isEnabled ?? true,
      schedule: BudgetSchedule(walletId: budget.walletId, period: budget.period, anchorDate: budget.startDate),
    ),
  );
}

/// Bawaan dialog lingkup (ADR-036 §3.3): mengubah nama, dompet, atau pos
/// bertemplate → periode ini dan berikutnya; hanya menambah atau menghapus
/// pos → hanya periode ini (ADR-008: baris baru insidental).
BudgetEditScope defaultEditScope(Budget before, Budget after) {
  if (before.name != after.name || before.walletId != after.walletId) return BudgetEditScope.thisAndNext;
  final previous = {for (final item in before.items) item.id: item};
  for (final item in after.items) {
    final old = previous[item.id];
    if (old != null && old.templateItemId != null && old != item) return BudgetEditScope.thisAndNext;
  }
  return BudgetEditScope.thisPeriod;
}

/// Apakah menyimpan [after] perlu menanyakan lingkup: anggaran rutin yang
/// periodenya belum lewat pada [today] dan benar-benar berubah. Anggaran
/// periode lalu tidak pernah mengubah template (invarian 19).
bool needsEditScope({
  required Budget before,
  required Budget after,
  required bool scheduled,
  required DateTime today,
}) => scheduled && before.endDate.isAfter(today) && before != after;
