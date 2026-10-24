import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/features/data_portability/domain/export_data.dart';
import 'package:saldough/features/data_portability/domain/export_labels.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Contoh dari EXPORT_BACKUP §5.2: periode mulai tanggal 25, IDR. Gaji dicatat
/// 23 Sep untuk kemunculan 25 Sep (maju 2 hari), jadi dihitung ke periode
/// 25 Sep – 24 Okt. Arus periode itu = 8.455.000.
ExportData sampleExportData({
  AppCurrency currency = AppCurrency.idr,
  List<Transaction>? transactions,
  String noteOfSalary = 'Gaji Sep',
}) {
  return ExportData(
    transactions:
        transactions ??
        [
          IncomeTransaction(
            id: 't3',
            date: DateTime(2026, 9, 23),
            amount: 850000000,
            note: noteOfSalary,
            categoryId: 'gaji',
            walletId: 'bca',
            recurrence: RecurrenceLink(ruleId: 'r1', occurrenceDate: DateTime(2026, 9, 25)),
          ),
          TransferTransaction(
            id: 't1',
            date: DateTime(2026, 9, 26),
            amount: 100000000,
            note: 'Isi GoPay',
            fromWalletId: 'bca',
            toWalletId: 'gopay',
          ),
          ExpenseTransaction(
            id: 't2',
            date: DateTime(2026, 9, 26),
            amount: 4500000,
            note: 'Nasi padang',
            walletId: 'gopay',
            categoryId: 'makan',
            budgetItemId: 'pos-makan',
          ),
        ],
    wallets: const [
      Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 100000000, currentBalance: 840000000),
      Wallet(
        id: 'gopay',
        name: 'GoPay',
        iconKey: 'walletEwallet',
        initialBalance: 0,
        currentBalance: 95500000,
        isActive: false,
      ),
    ],
    categoryNames: const {'gaji': 'Gaji', 'makan': 'Makan'},
    budgetLabels: const {'pos-makan': 'Bulanan › Makan'},
    ruleNames: const {'r1': 'Gaji bulanan'},
    freelanceProjectByPaymentId: const {},
    schedule: FinancialMonthSchedule.single(const FinancialMonthStart.day(25)),
    currency: currency,
  );
}

/// Judul kolom bahasa Indonesia untuk uji.
const idLabels = ExportLabels(
  fileStem: 'ekspor',
  transactionsSheet: 'Transaksi',
  walletsSheet: 'Dompet',
  transactionColumns: [
    'Tanggal',
    'Awal periode',
    'Jenis',
    'Nominal',
    'Arus',
    'Mata uang',
    'Dompet',
    'Dompet tujuan',
    'Kategori',
    'Catatan',
    'Pos anggaran',
    'Rutin',
    'Proyek freelance',
    'ID',
  ],
  walletColumns: ['Nama', 'Saldo awal', 'Saldo sekarang'],
  income: 'Pemasukan',
  expense: 'Pengeluaran',
  transfer: 'Transfer',
);
