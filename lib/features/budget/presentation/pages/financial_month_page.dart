import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/budget/domain/entities/budget_template.dart';
import 'package:saldough/features/budget/domain/repositories/budget_repository.dart';
import 'package:saldough/features/budget/domain/repositories/budget_template_repository.dart';
import 'package:saldough/features/budget/domain/usecases/align_recurring_budgets.dart';
import 'package:saldough/features/budget/domain/usecases/birth_recurring_budgets.dart';
import 'package:saldough/features/budget/presentation/widgets/financial_month_sheet.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Isi rute `budget.financialMonth` (ADR-038, FINANCIAL_PERIOD F1, F3):
/// memuat anggaran rutin yang bisa ikut pindah, lalu menampilkan
/// [FinancialMonthSheet]. Menyimpan = jadwal baru lewat
/// `FinancialMonthSchedule.changedOn`, anggaran terpilih dipindah lewat
/// [AlignRecurringBudgets], lalu `LedgerChanges` supaya Beranda, Rencana,
/// dan Anggaran segar. Saldo tidak berubah.
class FinancialMonthPage extends StatefulWidget {
  /// Membuat [FinancialMonthPage].
  const FinancialMonthPage({this.now, super.key});

  /// Jam, bisa diganti di uji.
  final DateTime Function()? now;

  @override
  State<FinancialMonthPage> createState() => _FinancialMonthPageState();
}

class _FinancialMonthPageState extends State<FinancialMonthPage> {
  late final GetIt _c = ScopeProvider.of(context);
  late final DateTime _today = (widget.now ?? DateTime.now)();
  late final FinancialMonthSchedule _schedule = ActiveFinancialMonth.schedule;
  late final Future<List<FinancialMonthBudgetOption>> _budgets = _loadBudgets();

  Future<List<FinancialMonthBudgetOption>> _loadBudgets() async {
    final templates = (await _c<BudgetTemplateRepository>().listTemplates()).getOrElse((_) => const <BudgetTemplate>[]);
    return movableRecurringBudgets(templates, _schedule.active);
  }

  Future<bool> _save(FinancialMonthStart start, Set<String> moved) async {
    final updated = _schedule.changedOn(_today, start);
    final saved = await _c<FinancialMonthPreferenceRepository>().save(updated);
    if (saved.isLeft()) {
      _showError();
      return false;
    }
    ActiveFinancialMonth.notifier.value = updated;
    final budgets = _c<BudgetRepository>();
    final templates = _c<BudgetTemplateRepository>();
    final aligned = await AlignRecurringBudgets(
      budgets: budgets,
      templates: templates,
      birth: BirthRecurringBudgets(
        budgets: budgets,
        templates: templates,
        transactions: _c<TransactionRepository>(),
      ),
    )(
      templateIds: moved,
      today: _today,
      transitionEnd: updated.periodOf(_schedule.periodOf(_today).start).end,
      start: start,
    );
    _c<LedgerChanges>().notifyChanged(source: this);
    // Jadwal sudah tersimpan; anggaran yang gagal dipindah bisa diubah
    // sendiri dari tab Anggaran, jadi lembar tetap ditutup.
    if (aligned.isLeft()) _showError();
    return true;
  }

  void _showError() {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(t.common.genericErrorMessage)));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FinancialMonthBudgetOption>>(
      future: _budgets,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.expand();
        return FinancialMonthSheet(
          schedule: _schedule,
          today: _today,
          budgets: snapshot.data!,
          onSave: _save,
        );
      },
    );
  }
}
