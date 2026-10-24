import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/data_portability/domain/export_labels.dart';

/// [ExportLabels] dari i18n pada bahasa aplikasi saat ini (EXPORT_BACKUP §5.2:
/// judul kolom mengikuti bahasa aplikasi). Dipanggil saat ekspor, bukan saat
/// layanan dibuat, supaya mengikuti pergantian bahasa.
ExportLabels exportLabelsFromI18n() {
  final c = t.dataPortability.columns;
  return ExportLabels(
    fileStem: t.dataPortability.fileStem,
    transactionsSheet: t.dataPortability.sheetTransactions,
    walletsSheet: t.dataPortability.sheetWallets,
    transactionColumns: [
      c.date,
      c.periodStart,
      c.type,
      c.amount,
      c.flow,
      c.currency,
      c.wallet,
      c.toWallet,
      c.category,
      c.note,
      c.budgetItem,
      c.recurring,
      c.freelanceProject,
      c.id,
    ],
    walletColumns: [c.walletName, c.openingBalance, c.currentBalance],
    income: t.dataPortability.types.income,
    expense: t.dataPortability.types.expense,
    transfer: t.dataPortability.types.transfer,
  );
}
