import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/transaction/presentation/widgets/transaction_surfaces.dart';
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
        ? colors.income
        : net < 0
        ? colors.expense
        : colors.textPrimary;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TransactionSlab(
          color: colors.surfaceMid,
          padding: const EdgeInsets.all(AppSpacing.xs),
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
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AppIcon(IconKey.calendar, size: 18),
                        const SizedBox(width: AppSpacing.xs),
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
        const SizedBox(height: AppSpacing.sm),
        TransactionSlab(
          color: colors.surfaceLow,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colors.incomeFill,
                      boxShadow: [
                        BoxShadow(
                          color: colors.edge,
                          offset: const Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      t.transaction.monthStatusLabel.toUpperCase(),
                      overflow: TextOverflow.ellipsis,
                      style: transactionLabelStyle(
                        context,
                        color: colors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceHigh,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      t.transaction.logCountBadge(count: rawTransactions.length).toUpperCase(),
                      style: transactionLabelStyle(
                        context,
                        color: colors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                t.transaction.netFlowLabel,
                style: transactionLabelStyle(
                  context,
                  color: colors.textMuted,
                ).copyWith(fontWeight: FontWeight.w400),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  netText,
                  style: textTheme.titleLarge?.copyWith(
                    fontSize: 22,
                    color: netColor,
                  ),
                ),
              ),
              if (totals.income + totals.expense > 0) ...[
                const SizedBox(height: AppSpacing.sm),
                _ShareBar(income: totals.income, expense: totals.expense),
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
              color: colors.cardBackground,
              borderRadius: BorderRadius.circular(4),
            ),
            child: AppIcon(icon, size: 20, color: colors.textPrimary),
          ),
        ),
      ),
    );
  }
}

/// Bilah segmen pemasukan (hijau) lawan pengeluaran (merah) bulan ini --
/// sepuluh blok, minimal satu blok untuk sisi yang tidak nol.
class _ShareBar extends StatelessWidget {
  const _ShareBar({required this.income, required this.expense});

  final int income;
  final int expense;

  static const _segments = 10;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final total = income + expense;
    var incomeSegments = (income * _segments / total).round();
    if (income > 0 && incomeSegments == 0) incomeSegments = 1;
    if (expense > 0 && incomeSegments == _segments) incomeSegments = _segments - 1;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: colors.surfaceHigh,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          for (var i = 0; i < _segments; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Container(
                height: 8,
                color: i < incomeSegments ? colors.incomeFill : colors.expenseFill,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
