import 'package:flutter/material.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Navigasi bulan (‹ bulan tahun ›) beserta jumlah bersih bulan itu, dalam
/// satu [AppHardCard] ("kartu ringkasan bulan"). Jumlahnya dihitung dari
/// SELURUH transaksi bulan ini apa adanya (`rawTransactions`), BUKAN dari
/// hasil yang sudah tersaring filter -- ini ringkasan bulan, bukan ringkasan
/// hasil pencarian, jadi sengaja tidak ikut berubah saat filter diganti.
/// Transfer tidak dihitung (CLAUDE.md aturan 7).
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

  int get _netSen {
    var net = 0;
    for (final transaction in rawTransactions) {
      switch (transaction) {
        case IncomeTransaction():
          net += transaction.amount;
        case ExpenseTransaction():
          net -= transaction.amount;
        case TransferTransaction():
          break;
      }
    }
    return net;
  }

  String get _monthLabel {
    final cycleId = '${month.year}-${month.month.toString().padLeft(2, '0')}';
    return CycleMonthFormatter.format(cycleId);
  }

  @override
  Widget build(BuildContext context) {
    return AppHardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: const AppIcon(IconKey.chevronLeft),
                onPressed: onPreviousMonth,
              ),
              Expanded(
                child: Text(
                  _monthLabel,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: const AppIcon(IconKey.chevronRight),
                onPressed: onNextMonth,
              ),
            ],
          ),
          Center(
            child: AppMoneyText(sen: _netSen, style: Theme.of(context).textTheme.headlineSmall),
          ),
        ],
      ),
    );
  }
}
