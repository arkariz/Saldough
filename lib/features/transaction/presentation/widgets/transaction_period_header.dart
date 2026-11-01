import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Pemilih periode dan ringkasan periode Riwayat (acuan Riwayat v2): pil
/// periode dengan panah sebelumnya/berikutnya di sekitar "September 2026"
/// (atau rentang "25 Okt – 24 Nov"), lalu kartu arus periode itu: selisih
/// dan dua ubin pemasukan dan pengeluaran. Dihitung dari SELURUH transaksi periode ini (`rawTransactions`),
/// bukan hasil saringan -- ringkasan periode, bukan hasil pencarian.
/// Transfer tidak dihitung (CLAUDE.md aturan 7). Periodenya dibagi dengan
/// segmen Analisis (T-19.10).
class TransactionPeriodHeader extends StatelessWidget {
  /// Membuat [TransactionPeriodHeader].
  const TransactionPeriodHeader({
    required this.period,
    required this.rawTransactions,
    required this.onPrevious,
    required this.onNext,
    super.key,
  });

  /// Periode yang sedang ditampilkan.
  final FinancialPeriod period;

  /// Seluruh transaksi periode ini, belum tersaring filter.
  final List<Transaction> rawTransactions;

  /// Mundur satu periode; `null` bila tidak ada yang lebih lama.
  final VoidCallback? onPrevious;

  /// Maju satu periode; `null` di periode berjalan.
  final VoidCallback? onNext;

  ({int income, int expense}) get _totals {
    var income = 0;
    var expense = 0;
    for (final transaction in rawTransactions) {
      switch (transaction) {
        case IncomeTransaction():
          income += transaction.amount;
        case ExpenseTransaction():
          expense += transaction.amount;
        case TransferTransaction():
          break;
      }
    }
    return (income: income, expense: expense);
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final totals = _totals;
    final net = totals.income - totals.expense;
    final days = period.isTransition ? period.days : null;
    Widget stat(String label, int sen, MoneyKind kind, Color dot) => DecoratedBox(
      decoration: BoxDecoration(
        color: c.surfaceSunken,
        borderRadius: DsRadius.mdAll,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox.square(
                  dimension: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: dot,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: ds.typography.labelMd.copyWith(
                      color: c.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            FitStart(child: AppMoneyText(sen, kind: kind)),
          ],
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DsPeriodStepper(
          title: period.label,
          tag: days == null ? null : t.plan.transitionLabel(days: days),
          previousLabel: t.analysis.previousPeriod,
          nextLabel: t.analysis.nextPeriod,
          onPrevious: onPrevious,
          onNext: onNext,
        ),
        const SizedBox(height: AppSpacing.space3),
        DsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      t.transaction.flowTitle,
                      style: ds.typography.titleMd.copyWith(
                        fontSize: 14,
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: net < 0 ? c.errorContainer : c.incomeContainer,
                        borderRadius: DsRadius.fullAll,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${t.home.flowNet} ${AppMoneyText.format(net.abs(), net > 0
                                ? MoneyKind.income
                                : net < 0
                                ? MoneyKind.expense
                                : MoneyKind.transfer)}',
                            key: const ValueKey('period-net'),
                            style: ds.typography.labelMd.copyWith(
                              color: net < 0 ? c.onErrorContainer : c.onIncomeContainer,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: stat(
                        t.home.incomeStat,
                        totals.income,
                        MoneyKind.income,
                        c.income,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: stat(
                        t.home.expenseStat,
                        totals.expense,
                        MoneyKind.expense,
                        c.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
