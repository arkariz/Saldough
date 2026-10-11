import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/budget/domain/entities/budget.dart';
import 'package:saldough/features/budget/domain/entities/budget_item.dart';
import 'package:saldough/features/budget/domain/entities/budget_template.dart';
import 'package:saldough/features/budget/domain/repositories/budget_repository.dart';
import 'package:saldough/features/budget/domain/repositories/budget_template_repository.dart';
import 'package:saldough/features/budget/domain/usecases/calculate_budget_progress.dart';
import 'package:saldough/features/budget/domain/usecases/read_transactions_in_months.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Anggaran yang perlu lahir per [today] (ADR-036 §3.2): untuk tiap template
/// berjadwal aktif, periode yang mencakup [today], bila belum ada anggaran
/// dari template itu dengan awal yang sama (diarsipkan pun dihitung ada).
///
/// Hanya periode berjalan: periode yang terlewat saat aplikasi lama tidak
/// dibuka tidak pernah lahir, dan sebelum `anchorDate` tidak ada yang lahir.
/// Pos mendapat id baru dari [newId] dan `templateItemId` pos templatenya.
/// Akhir periodenya awal periode berikutnya jadwal itu (ADR-038 §3.3);
/// disimpan hanya bila berbeda dari `period.endFrom`, mis. patokan hari
/// terakhir bulan atau sesudah patokan dipindah.
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
            endDate: switch (schedule.endOf(start)) {
              final end when end != schedule.period.endFrom(start) => end,
              _ => null,
            },
          ),
  ];
}

/// Pos anggaran dari pos template [item] dengan id [id].
BudgetItem bornItem(BudgetItem item, String id) =>
    item.copyWith(id: id, templateItemId: () => item.templateItemId ?? item.id);

/// Transaksi yang tautan posnya perlu pindah ke anggaran [born] yang baru
/// lahir (FINANCIAL_PERIOD P-7): tertaut pos anggaran lain dari template
/// yang sama yang periodenya **tidak** lagi mencakup tanggal periodenya
/// (anggaran itu dipendekkan), sementara [born] mencakupnya. Pos tujuan
/// adalah pos [born] dengan `templateItemId` sama; transaksi yang posnya
/// tidak punya padanan dibiarkan.
List<Transaction> relinkedToBorn(Budget born, Iterable<Budget> budgets, Iterable<Transaction> transactions) {
  final siblings = [
    for (final b in budgets)
      if (b.templateId == born.templateId && b.id != born.id) b,
  ];
  final targets = {
    for (final item in born.items)
      ?item.templateItemId: item,
  };
  final result = <Transaction>[];
  for (final t in transactions) {
    final itemId = switch (t) {
      ExpenseTransaction(:final budgetItemId) || TransferTransaction(:final budgetItemId) => budgetItemId,
      IncomeTransaction() => null,
    };
    if (itemId == null) continue;
    for (final owner in siblings) {
      final item = owner.items.where((i) => i.id == itemId).firstOrNull;
      if (item == null) continue;
      final date = periodDateOf(t);
      final target = targets[item.templateItemId];
      if (owner.covers(date) || !born.covers(date) || target == null) break;
      if (!countsTowardBudgetItem(born, target, t)) break;
      result.add(switch (t) {
        final ExpenseTransaction e => e.copyWith(budgetItemId: target.id),
        final TransferTransaction e => e.copyWith(budgetItemId: target.id),
        final IncomeTransaction e => e,
      });
      break;
    }
  }
  return result;
}

/// Menyimpan [dueBirths] (ADR-036 §3.2) dan memindah tautan pos ke anggaran
/// yang baru lahir ([relinkedToBorn], P-7). Tidak menyentuh saldo dompet
/// (aturan 5, invarian 14): yang ditulis ulang hanya pos tautan, tanggal dan
/// nominal tetap. Idempoten, jadi aman dipanggil tiap aplikasi dibuka dan
/// tiap tanggal berganti.
final class BirthRecurringBudgets {
  /// Membuat [BirthRecurringBudgets]. Tanpa [transactions], tautan pos tidak
  /// dipindah.
  BirthRecurringBudgets({
    required this._budgets,
    required this._templates,
    this._transactions,
    String Function()? newId,
  }) : _newId = newId ?? _defaultId;

  final BudgetRepository _budgets;
  final BudgetTemplateRepository _templates;
  final TransactionRepository? _transactions;
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
    final all = [...budgets.getOrElse((_) => const []), ...born];
    for (final budget in born) {
      if (await _budgets.saveBudget(budget) case Left(:final value)) return left(value);
      if (await _relink(budget, all) case Left(:final value)) return left(value);
    }
    return right(born.length);
  }

  Future<Either<Failure, Unit>> _relink(Budget born, List<Budget> budgets) async {
    final repository = _transactions;
    if (repository == null) return right(unit);
    final transactions = await ReadTransactionsInMonths(repository)(born.months);
    if (transactions case Left(:final value)) return left(value);
    for (final t in relinkedToBorn(born, budgets, transactions.getOrElse((_) => const []))) {
      if (await repository.saveTransaction(t) case Left(:final value)) return left(value);
    }
    return right(unit);
  }
}
