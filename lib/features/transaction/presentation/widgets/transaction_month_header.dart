import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/tutorial/tutorial.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Navigasi bulan ("konsol bulan") dan banner status log bulan itu --
/// rujukan visual `pixel_kas_daftar_transaksi`. Jumlah bersih dan proporsinya
/// dihitung dari SELURUH transaksi bulan ini apa adanya (`rawTransactions`),
/// BUKAN dari hasil yang sudah tersaring -- ini ringkasan bulan, bukan
/// ringkasan hasil pencarian, jadi sengaja tidak ikut berubah saat filter
/// diganti. Transfer tidak dihitung (CLAUDE.md aturan 7).
///
/// Tanda "+18.4% vs September" pada rujukan visual TIDAK dibangun: ia butuh
/// transaksi bulan sebelumnya, yang tidak dimuat layar ini.
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
    final totals = _totals;
    final net = totals.income - totals.expense;
    final netText = net > 0 ? '+${AppMoneyFormatter.format(net)}' : AppMoneyFormatter.format(net);
    final netColor = net > 0
        ? colors.positive
        : net < 0
        ? colors.ink
        : colors.ink;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TransactionSlab(
          color: colors.surface2,
          padding: const EdgeInsets.all(AppSpacing.space1),
          child: Row(
            children: [
              _StepperButton(
                icon: IconKey.chevronLeft,
                onPressed: onPreviousMonth,
              ),
              Expanded(
                child: Center(
                  child: TransactionSlab(
                    shadow: 0,
                    radius: 4,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space2,
                      vertical: AppSpacing.space1,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AppIcon(IconKey.calendar, size: 18),
                        const SizedBox(width: AppSpacing.space1),
                        Flexible(
                          child: Text(
                            _monthLabel,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleLarge?.copyWith(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _StepperButton(
                icon: IconKey.chevronRight,
                onPressed: onNextMonth,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        AppSummaryCard(
          tour: TourId.transaction,
          icon: IconKey.transactions,
          label: t.transaction.monthStatusLabel,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space1 + 2, vertical: 2),
            decoration: BoxDecoration(color: colors.surface, borderRadius: AppRadius.pixelSmAll),
            child: Text(
              t.transaction.logCountBadge(count: rawTransactions.length).toUpperCase(),
              style: transactionLabelStyle(context, color: colors.ink2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t.transaction.netFlowLabel,
                style: transactionLabelStyle(context, color: colors.ink2).copyWith(fontWeight: FontWeight.w400),
              ),
              const SizedBox(height: 2),
              HeroAmount(netText, color: netColor),
              if (totals.income + totals.expense > 0) ...[
                const SizedBox(height: AppSpacing.space2),
                _FlowNumbers(income: totals.income, expense: totals.expense),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onPressed});

  final IconKey icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(4),
            ),
            child: AppIcon(icon, size: 20, color: colors.ink),
          ),
        ),
      ),
    );
  }
}

/// Angka Masuk dan Keluar bulan ini, kecil di bawah Netto (ADR-020 §3.5 --
/// menggantikan bilah bersegmen `_ShareBar` lama: bilah bersegmen di
/// aplikasi ini kini HANYA berarti progres terhadap rencana anggaran, jadi
/// proporsi masuk/keluar di sini tidak boleh memakai bentuk yang sama).
class _FlowNumbers extends StatelessWidget {
  const _FlowNumbers({required this.income, required this.expense});

  final int income;
  final int expense;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        Expanded(child: _FlowNumber(label: t.transaction.flowIncomeLabel, amount: income, color: colors.positive)),
        const SizedBox(width: AppSpacing.space4),
        Expanded(child: _FlowNumber(label: t.transaction.flowExpenseLabel, amount: expense, color: colors.ink)),
      ],
    );
  }
}

class _FlowNumber extends StatelessWidget {
  const _FlowNumber({required this.label, required this.amount, required this.color});

  final String label;
  final int amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${label.toUpperCase()} ',
          style: transactionLabelStyle(context, color: colors.ink2),
        ),
        Flexible(
          child: Text(
            AppMoneyFormatter.format(amount),
            overflow: TextOverflow.ellipsis,
            style: context.numberStyles.amountSm.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
