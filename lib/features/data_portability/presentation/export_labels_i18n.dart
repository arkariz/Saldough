import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/data_portability/domain/export_labels.dart';

/// [ExportLabels] dari i18n pada bahasa aplikasi saat ini (EXPORT_BACKUP §5.2:
/// judul kolom mengikuti bahasa aplikasi). Dipanggil saat ekspor, bukan saat
/// layanan dibuat, supaya mengikuti pergantian bahasa.
ExportLabels exportLabelsFromI18n() {
  final c = t.dataPortability.columns;
  final g = t.dataPortability.goalColumns;
  final i = t.dataPortability.investmentColumns;
  final v = t.dataPortability.valuationColumns;
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
    adjustmentIncrease: t.dataPortability.types.adjustmentIncrease,
    adjustmentDecrease: t.dataPortability.types.adjustmentDecrease,
    investBuy: t.dataPortability.types.investBuy,
    investSell: t.dataPortability.types.investSell,
    goalsSheet: t.dataPortability.sheetGoals,
    goalColumns: [g.name, g.target, g.saved, g.status, g.targetDate, g.wallets],
    goalStatuses: [g.statusActive, g.statusReached, g.statusArchived],
    investmentsSheet: t.dataPortability.sheetInvestments,
    investmentColumns: [
      i.name,
      i.type,
      i.code,
      i.quantity,
      i.unit,
      i.cost,
      i.lastPrice,
      i.priceUnit,
      i.priceDate,
      i.marketValue,
      i.unrealized,
      i.realized,
      i.status,
    ],
    investmentTypes: [
      t.assets.invest.type.stock,
      t.assets.invest.type.mutualFund,
      t.assets.invest.type.bond,
      t.assets.invest.type.gold,
      t.assets.invest.type.other,
    ],
    quantityUnits: [
      t.assets.invest.unit.lot,
      t.assets.invest.unit.unit,
      t.assets.invest.nominal,
      t.assets.invest.unit.gram,
      t.assets.invest.unit.unit,
    ],
    priceUnits: [
      t.assets.invest.price.perShare,
      t.assets.invest.price.perUnit,
      t.assets.invest.price.bondPercent,
      t.assets.invest.price.perGram,
      t.assets.invest.price.perUnit,
    ],
    investmentStatuses: [i.statusActive, t.assets.invest.closedBadge],
    valuationsSheet: t.dataPortability.sheetValuations,
    valuationColumns: [v.date, v.investment, v.price, v.priceUnit, v.source],
    valuationSources: [v.sourceManual, v.sourceSheet, v.sourceSheetEstimate],
  );
}
