import 'package:flutter/material.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Pemilih periode dan ringkasan periode Riwayat (prototipe `Riwayat.dc.html`):
/// panah periode sebelumnya/berikutnya di sekitar "September 2026" (atau
/// rentang "25 Okt – 24 Nov"), lalu kartu pemasukan dan pengeluaran periode
/// itu. Dihitung dari SELURUH transaksi periode ini (`rawTransactions`),
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
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final totals = _totals;
    Widget stat(String label, int sen, MoneyKind kind) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.bodyMedium?.copyWith(color: colors.ink2)),
        FitStart(child: AppMoneyText(sen, kind: kind)),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppPeriodStepper(
          title: period.label,
          transitionDays: period.isTransition ? period.days : null,
          onPrevious: onPrevious,
          onNext: onNext,
        ),
        const SizedBox(height: AppSpacing.space2),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4, vertical: AppSpacing.space3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: stat(t.home.incomeStat, totals.income, MoneyKind.income)),
              const SizedBox(width: AppSpacing.space3),
              Expanded(child: stat(t.home.expenseStat, totals.expense, MoneyKind.expense)),
            ],
          ),
        ),
      ],
    );
  }
}
