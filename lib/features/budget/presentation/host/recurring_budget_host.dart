import 'dart:async';

import 'package:dependencies/dependencies.dart' show Right;
import 'package:di/di.dart';
import 'package:flutter/widgets.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/features/budget/domain/repositories/budget_repository.dart';
import 'package:saldough/features/budget/domain/repositories/budget_template_repository.dart';
import 'package:saldough/features/budget/domain/usecases/birth_recurring_budgets.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Melahirkan anggaran rutin (ADR-036 §3.2) saat aplikasi dibuka dan saat
/// tanggal berganti (`ActiveDay`). Bila ada yang lahir, memancarkan
/// `LedgerChanges` supaya Beranda, Rencana, dan Anggaran memuat ulang.
/// Tanpa pekerjaan latar.
class RecurringBudgetHost extends StatefulWidget {
  /// Membuat [RecurringBudgetHost].
  const RecurringBudgetHost({
    required this.container,
    required this.child,
    super.key,
  });

  /// Kontainer akar.
  final GetIt container;

  /// Isi shell.
  final Widget child;

  @override
  State<RecurringBudgetHost> createState() => _RecurringBudgetHostState();
}

class _RecurringBudgetHostState extends State<RecurringBudgetHost> {
  BirthRecurringBudgets? _birth;
  late final LedgerChanges _ledger;
  var _running = false;

  @override
  void initState() {
    super.initState();
    final c = widget.container;
    // Kontainer tanpa template (sebagian uji shell): tidak ada yang lahir.
    if (!c.isRegistered<BudgetTemplateRepository>()) return;
    _birth = BirthRecurringBudgets(
      budgets: c<BudgetRepository>(),
      templates: c<BudgetTemplateRepository>(),
      transactions: c<TransactionRepository>(),
    );
    _ledger = c<LedgerChanges>();
    ActiveDay.notifier.addListener(_run);
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  void _run() => unawaited(_birthDue());

  Future<void> _birthDue() async {
    if (_running || _birth == null) return;
    _running = true;
    try {
      if (await _birth!(DateTime.now()) case Right(value: final born) when born > 0) {
        AppAnalytics.log(PlanEvents.budgetPeriodBorn(count: born));
        _ledger.notifyChanged(source: this);
      }
    } finally {
      _running = false;
    }
  }

  @override
  void dispose() {
    ActiveDay.notifier.removeListener(_run);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
