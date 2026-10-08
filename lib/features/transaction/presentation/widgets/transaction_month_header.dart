import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Pemilih bulan dan ringkasan bulan Riwayat (prototipe `Riwayat.dc.html`):
/// panah bulan sebelumnya/berikutnya di sekitar "September 2026", lalu kartu
/// pemasukan dan pengeluaran bulan itu. Dihitung dari SELURUH transaksi
/// bulan ini (`rawTransactions`), bukan hasil saringan -- ringkasan bulan,
/// bukan hasil pencarian. Transfer tidak dihitung (CLAUDE.md aturan 7).
class TransactionMonthHeader extends StatelessWidget {
  /// Membuat [TransactionMonthHeader].
  const TransactionMonthHeader({
    required this.month,
    required this.rawTransactions,
    required this.onPreviousMonth,
    required this.onNextMonth,
    super.key,
  });

  /// Bulan yang sedang ditampilkan.
  final DateTime month;

  /// Seluruh transaksi bulan ini, belum tersaring filter.
  final List<Transaction> rawTransactions;

  /// Dipanggil saat panah bulan sebelumnya ditekan.
  final VoidCallback onPreviousMonth;

  /// Dipanggil saat panah bulan berikutnya ditekan.
  final VoidCallback onNextMonth;

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

  String get _monthLabel {
    final cycleId = '${month.year}-${month.month.toString().padLeft(2, '0')}';
    return CycleMonthFormatter.format(cycleId);
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
        Row(
          children: [
            AppIconButton(
              key: const ValueKey('month-previous'),
              icon: IconKey.chevronLeft,
              label: t.transaction.previousMonth,
              onPressed: onPreviousMonth,
            ),
            Expanded(
              child: Text(_monthLabel, textAlign: TextAlign.center, style: textTheme.titleMedium),
            ),
            AppIconButton(
              key: const ValueKey('month-next'),
              icon: IconKey.chevronRight,
              label: t.transaction.nextMonth,
              onPressed: onNextMonth,
            ),
          ],
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
