import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/features/budget/domain/entities/budget.dart';
import 'package:saldough/features/budget/domain/entities/budget_period.dart';
import 'package:saldough/features/budget/domain/entities/budget_template.dart';
import 'package:saldough/features/budget/domain/repositories/budget_repository.dart';
import 'package:saldough/features/budget/domain/repositories/budget_template_repository.dart';
import 'package:saldough/features/budget/domain/usecases/birth_recurring_budgets.dart';

/// Hasil [alignRecurringBudgets]: anggaran dan template yang berubah.
typedef RecurringBudgetAlignment = ({List<Budget> budgets, List<BudgetTemplate> templates});

/// Menyelaraskan anggaran rutin bulanan [templateIds] ke awal bulan
/// keuangan baru [start] (ADR-038 §3.4, FINANCIAL_PERIOD P-6, P-7), dengan
/// periode peralihan berakhir [transitionEnd] (eksklusif):
/// - anggaran periode berjalan (yang mencakup [today]) mendapat
///   `endDate = transitionEnd`, diregangkan atau dipendekkan; `startDate` dan
///   nominal posnya tidak berubah;
/// - patokan jadwal templatnya menjadi [transitionEnd], jadi periode
///   berikutnya lahir tepat di sana, tanpa celah atau tumpang-tindih.
///
/// Template yang tidak dipilih, tidak berjadwal, atau mingguan tidak
/// tersentuh (P-6).
RecurringBudgetAlignment alignRecurringBudgets(
  Iterable<BudgetTemplate> templates,
  Iterable<Budget> budgets, {
  required Set<String> templateIds,
  required DateTime today,
  required DateTime transitionEnd,
  required FinancialMonthStart start,
}) {
  final day = DateTime(today.year, today.month, today.day);
  final end = DateTime(transitionEnd.year, transitionEnd.month, transitionEnd.day);
  final changedBudgets = <Budget>[];
  final changedTemplates = <BudgetTemplate>[];
  for (final template in templates) {
    final schedule = template.schedule;
    if (!templateIds.contains(template.id) || schedule == null || schedule.period != BudgetPeriod.monthly) continue;
    changedTemplates.add(
      template.copyWith(
        schedule: () => schedule.copyWith(anchorDate: end, onLastDay: start.isLastDay),
      ),
    );
    final current = budgets.where((b) => b.templateId == template.id && b.covers(day)).firstOrNull;
    if (current != null && current.startDate.isBefore(end) && current.endDate != end) {
      changedBudgets.add(current.copyWith(endDate: () => end));
    }
  }
  return (budgets: changedBudgets, templates: changedTemplates);
}

/// Menyimpan [alignRecurringBudgets] lalu menjalankan [BirthRecurringBudgets]
/// untuk [today]: bila periode peralihan sudah selesai (contoh C), periode
/// baru lahir sekarang dan tautan pos sesudah akhir baru ikut pindah. Saldo
/// tidak berubah (aturan 5).
final class AlignRecurringBudgets {
  /// Membuat [AlignRecurringBudgets].
  const AlignRecurringBudgets({required this._budgets, required this._templates, required this._birth});

  final BudgetRepository _budgets;
  final BudgetTemplateRepository _templates;
  final BirthRecurringBudgets _birth;

  /// Lihat [alignRecurringBudgets].
  Future<Either<Failure, Unit>> call({
    required Set<String> templateIds,
    required DateTime today,
    required DateTime transitionEnd,
    required FinancialMonthStart start,
  }) async {
    if (templateIds.isEmpty) return right(unit);
    final templates = await _templates.listTemplates();
    if (templates case Left(:final value)) return left(value);
    final budgets = await _budgets.listBudgets();
    if (budgets case Left(:final value)) return left(value);
    final aligned = alignRecurringBudgets(
      templates.getOrElse((_) => const []),
      budgets.getOrElse((_) => const []),
      templateIds: templateIds,
      today: today,
      transitionEnd: transitionEnd,
      start: start,
    );
    for (final budget in aligned.budgets) {
      if (await _budgets.saveBudget(budget) case Left(:final value)) return left(value);
    }
    for (final template in aligned.templates) {
      if (await _templates.saveTemplate(template) case Left(:final value)) return left(value);
    }
    return (await _birth(today)).map((_) => unit);
  }
}
