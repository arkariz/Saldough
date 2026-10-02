import 'package:saldough/core/i18n/strings.g.dart';
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

/// Langkah [tour] beserta teksnya, urut [tourSteps]. Langkah yang targetnya
/// tidak tampil, atau yang sudah dilihat, disaring saat tur dimulai.
List<SpotlightStep> spotlightStepsFor(TourId tour) => [
  for (final key in tourSteps[tour]!) spotlightStep(key),
];

/// Teks langkah [key] (ONBOARDING_PLAN §4.3, ADR-021 §3.4).
SpotlightStep spotlightStep(SpotlightKey key) {
  final tr = t.tour;
  final (title, body) = switch (key) {
    SpotlightKey.homeBalance => (tr.homeBalanceTitle, tr.homeBalanceBody),
    SpotlightKey.homeRecord => (tr.homeRecordTitle, tr.homeRecordBody),
    SpotlightKey.homeVoice => (tr.homeVoiceTitle, tr.homeVoiceBody),
    SpotlightKey.homeCashFlow => (tr.homeCashFlowTitle, tr.homeCashFlowBody),
    SpotlightKey.homeBudget => (tr.homeBudgetTitle, tr.homeBudgetBody),
    SpotlightKey.homeFreelance => (tr.homeFreelanceTitle, tr.homeFreelanceBody),
    SpotlightKey.homeRecent => (tr.homeRecentTitle, tr.homeRecentBody),
    SpotlightKey.recordKind => (tr.recordKindTitle, tr.recordKindBody),
    SpotlightKey.recordFreelance => (tr.recordFreelanceTitle, tr.recordFreelanceBody),
    SpotlightKey.recordAmount => (tr.recordAmountTitle, tr.recordAmountBody),
    SpotlightKey.recordWallet => (tr.recordWalletTitle, tr.recordWalletBody),
    SpotlightKey.recordBudgetItem => (tr.recordBudgetItemTitle, tr.recordBudgetItemBody),
    SpotlightKey.walletSummary => (tr.walletSummaryTitle, tr.walletSummaryBody),
    SpotlightKey.walletCard => (tr.walletCardTitle, tr.walletCardBody),
    SpotlightKey.walletAdd => (tr.walletAddTitle, tr.walletAddBody),
    SpotlightKey.txnMonth => (tr.txnMonthTitle, tr.txnMonthBody),
    SpotlightKey.txnFilter => (tr.txnFilterTitle, tr.txnFilterBody),
    SpotlightKey.txnRow => (tr.txnRowTitle, tr.txnRowBody),
    SpotlightKey.planTabs => (tr.planTabsTitle, tr.planTabsBody),
    SpotlightKey.budgetSummary => (tr.budgetSummaryTitle, tr.budgetSummaryBody),
    SpotlightKey.budgetFilter => (tr.budgetFilterTitle, tr.budgetFilterBody),
    SpotlightKey.budgetTemplates => (tr.budgetTemplatesTitle, tr.budgetTemplatesBody),
    SpotlightKey.budgetDetailItem => (tr.budgetDetailItemTitle, tr.budgetDetailItemBody),
    SpotlightKey.budgetDetailRecord => (tr.budgetDetailRecordTitle, tr.budgetDetailRecordBody),
    SpotlightKey.freelanceProject => (tr.freelanceProjectTitle, tr.freelanceProjectBody),
    SpotlightKey.freelanceWorklog => (tr.freelanceWorklogTitle, tr.freelanceWorklogBody),
    SpotlightKey.freelanceReceive => (tr.freelanceReceiveTitle, tr.freelanceReceiveBody),
  };
  return SpotlightStep(key, title, body);
}
