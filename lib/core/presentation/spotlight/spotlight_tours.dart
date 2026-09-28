import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/spotlight/spotlight_key.dart';
import 'package:saldough/core/tutorial/tutorial.dart';

/// Satu langkah tur: elemen yang disorot dan teksnya.
final class SpotlightStep {
  /// Membuat [SpotlightStep].
  const SpotlightStep(this.key, this.title, this.body);

  /// Elemen yang disorot.
  final SpotlightKey key;

  /// Judul gelembung.
  final String title;

  /// Isi gelembung.
  final String body;
}

/// Langkah [tour], urut (ONBOARDING_PLAN §4.3, disesuaikan ADR-021 §3.4).
/// Langkah yang targetnya tidak terpasang dilewati saat tur dimulai.
List<SpotlightStep> spotlightStepsFor(TourId tour) {
  final tr = t.tour;
  return switch (tour) {
    TourId.home => [
      SpotlightStep(SpotlightKey.homeBalance, tr.homeBalanceTitle, tr.homeBalanceBody),
      SpotlightStep(SpotlightKey.homeRecord, tr.homeRecordTitle, tr.homeRecordBody),
      SpotlightStep(SpotlightKey.homeCashFlow, tr.homeCashFlowTitle, tr.homeCashFlowBody),
      SpotlightStep(SpotlightKey.homeBudget, tr.homeBudgetTitle, tr.homeBudgetBody),
    ],
    TourId.record => [
      SpotlightStep(SpotlightKey.recordKind, tr.recordKindTitle, tr.recordKindBody),
      SpotlightStep(SpotlightKey.recordAmount, tr.recordAmountTitle, tr.recordAmountBody),
      SpotlightStep(SpotlightKey.recordWallet, tr.recordWalletTitle, tr.recordWalletBody),
      SpotlightStep(SpotlightKey.recordBudgetItem, tr.recordBudgetItemTitle, tr.recordBudgetItemBody),
    ],
    TourId.wallet => [
      SpotlightStep(SpotlightKey.walletSummary, tr.walletSummaryTitle, tr.walletSummaryBody),
      SpotlightStep(SpotlightKey.walletCard, tr.walletCardTitle, tr.walletCardBody),
      SpotlightStep(SpotlightKey.walletAdd, tr.walletAddTitle, tr.walletAddBody),
    ],
    TourId.transaction => [
      SpotlightStep(SpotlightKey.txnMonth, tr.txnMonthTitle, tr.txnMonthBody),
      SpotlightStep(SpotlightKey.txnFilter, tr.txnFilterTitle, tr.txnFilterBody),
      SpotlightStep(SpotlightKey.txnRow, tr.txnRowTitle, tr.txnRowBody),
    ],
    TourId.budget => [
      SpotlightStep(SpotlightKey.budgetSummary, tr.budgetSummaryTitle, tr.budgetSummaryBody),
      SpotlightStep(SpotlightKey.budgetFilter, tr.budgetFilterTitle, tr.budgetFilterBody),
      SpotlightStep(SpotlightKey.budgetTemplates, tr.budgetTemplatesTitle, tr.budgetTemplatesBody),
    ],
    TourId.budgetDetail => [
      SpotlightStep(SpotlightKey.budgetDetailItem, tr.budgetDetailItemTitle, tr.budgetDetailItemBody),
      SpotlightStep(SpotlightKey.budgetDetailRecord, tr.budgetDetailRecordTitle, tr.budgetDetailRecordBody),
    ],
    TourId.freelance => [
      SpotlightStep(SpotlightKey.freelanceProject, tr.freelanceProjectTitle, tr.freelanceProjectBody),
    ],
    TourId.freelanceProject => [
      SpotlightStep(SpotlightKey.freelanceWorklog, tr.freelanceWorklogTitle, tr.freelanceWorklogBody),
      SpotlightStep(SpotlightKey.freelanceReceive, tr.freelanceReceiveTitle, tr.freelanceReceiveBody),
    ],
  };
}
