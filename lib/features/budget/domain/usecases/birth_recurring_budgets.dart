import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/budget/domain/entities/budget.dart';
import 'package:saldough/features/budget/domain/entities/budget_item.dart';
import 'package:saldough/features/budget/domain/entities/budget_template.dart';
import 'package:saldough/features/budget/domain/repositories/budget_repository.dart';
import 'package:saldough/features/budget/domain/repositories/budget_template_repository.dart';

/// Anggaran yang perlu lahir per [today] (ADR-036 §3.2): untuk tiap template
/// berjadwal aktif, periode yang mencakup [today], bila belum ada anggaran
/// dari template itu dengan awal yang sama (diarsipkan pun dihitung ada).
///
/// Hanya periode berjalan: periode yang terlewat saat aplikasi lama tidak
/// dibuka tidak pernah lahir, dan sebelum `anchorDate` tidak ada yang lahir.
/// Pos mendapat id baru dari [newId] dan `templateItemId` pos templatenya.
List<Budget> dueBirths(
  Iterable<BudgetTemplate> templates,
  Iterable<Budget> budgets, {
  required DateTime today,
  required String Function() newId,
}) {
  final existing = {
    for (final b in budgets)
      if (b.templateId != null)
        (
          b.templateId,
          DateTime(b.startDate.year, b.startDate.month, b.startDate.day),
        ),
  };
  return [
    for (final template in templates)
      if (template.schedule case final schedule? when schedule.isActive)
        if (schedule.startAt(today) case final start? when !existing.contains((template.id, start)))
          Budget(
            id: newId(),
            name: template.name,
            walletId: schedule.walletId,
            period: schedule.period,
            startDate: start,
            templateId: template.id,
            items: [for (final item in template.items) bornItem(item, newId())],
          ),
  ];
}

/// Pos anggaran dari pos template [item] dengan id [id].
BudgetItem bornItem(BudgetItem item, String id) =>
    item.copyWith(id: id, templateItemId: () => item.templateItemId ?? item.id);

/// Menyimpan [dueBirths] (ADR-036 §3.2). Tidak menyentuh saldo dompet
/// (aturan 5, invarian 14); idempoten, jadi aman dipanggil tiap aplikasi
/// dibuka dan tiap tanggal berganti.
final class BirthRecurringBudgets {
  /// Membuat [BirthRecurringBudgets].
  BirthRecurringBudgets({
    required this._budgets,
    required this._templates,
    String Function()? newId,
  }) : _newId = newId ?? _defaultId;

  final BudgetRepository _budgets;
  final BudgetTemplateRepository _templates;
  final String Function() _newId;

  static var _salt = 0;
  static String _defaultId() => '${DateTime.now().microsecondsSinceEpoch}-${_salt++}';

  /// Jumlah anggaran yang lahir.
  Future<Either<Failure, int>> call(DateTime today) async {
    final templates = await _templates.listTemplates();
    if (templates case Left(:final value)) return left(value);
    final budgets = await _budgets.listBudgets();
    if (budgets case Left(:final value)) return left(value);
    final born = dueBirths(
      templates.getOrElse((_) => const []),
      budgets.getOrElse((_) => const []),
      today: today,
      newId: _newId,
    );
    for (final budget in born) {
      if (await _budgets.saveBudget(budget) case Left(:final value)) return left(value);
    }
    return right(born.length);
  }
}
