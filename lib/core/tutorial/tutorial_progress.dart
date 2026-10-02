import 'package:dependencies/dependencies.dart';
import 'package:saldough/core/tutorial/spotlight_key.dart';

/// Tur spotlight yang dikenal aplikasi (ADR-021 §3.4): satu tur per layar,
/// berisi langkah-langkah [tourSteps].
enum TourId {
  /// Beranda.
  home,

  /// Alur CATAT.
  record,

  /// Tab Dompet.
  wallet,

  /// Tab Transaksi.
  transaction,

  /// Segmen Anggaran tab Rencana.
  budget,

  /// Rincian anggaran.
  budgetDetail,

  /// Ikhtisar Freelance.
  freelance,

  /// Rincian proyek Freelance.
  freelanceProject,
}

/// Langkah tiap tur, urut tampil (ONBOARDING_PLAN §4.3, ADR-021 §3.4).
const Map<TourId, List<SpotlightKey>> tourSteps = {
  TourId.home: [
    SpotlightKey.homeBalance,
    SpotlightKey.homeRecord,
    SpotlightKey.homeVoice,
    SpotlightKey.homeCashFlow,
    SpotlightKey.homeBudget,
    SpotlightKey.homeFreelance,
    SpotlightKey.homeRecent,
  ],
  TourId.record: [
    SpotlightKey.recordKind,
    // Hanya tampil di formulir Pemasukan; karena progres per langkah, ia
    // disorot sendiri saat Masuk pertama kali dipilih.
    SpotlightKey.recordFreelance,
    SpotlightKey.recordAmount,
    SpotlightKey.recordWallet,
    SpotlightKey.recordBudgetItem,
  ],
  TourId.wallet: [SpotlightKey.walletSummary, SpotlightKey.walletCard, SpotlightKey.walletAdd],
  TourId.transaction: [SpotlightKey.txnMonth, SpotlightKey.txnFilter, SpotlightKey.txnRow],
  // Sub-tab Rencana disorot lebih dulu: segmen Anggaran adalah segmen
  // pertama yang dibuka tab Rencana (R1a), dan satu tur per layar.
  TourId.budget: [SpotlightKey.planTabs, SpotlightKey.budgetSummary, SpotlightKey.budgetFilter, SpotlightKey.budgetTemplates],
  TourId.budgetDetail: [SpotlightKey.budgetDetailItem, SpotlightKey.budgetDetailRecord],
  TourId.freelance: [SpotlightKey.freelanceProject],
  TourId.freelanceProject: [SpotlightKey.freelanceWorklog, SpotlightKey.freelanceReceive],
};

/// Progres onboarding dan tur spotlight di perangkat ini (ADR-021 §3.1).
///
/// Dicatat **per langkah**, bukan per tur: elemen yang baru muncul belakangan
/// (mis. kartu anggaran Beranda sesudah anggaran pertama dibuat) tetap
/// disorot sekali saat pertama tampil, walau langkah lain di layarnya sudah
/// dilihat. Bukan data keuangan: kehilangan dokumen ini hanya berarti
/// pengenalan dan tur tampil lagi.
final class TutorialProgress extends Equatable {
  /// Membuat [TutorialProgress].
  const TutorialProgress({required this.onboardingDone, required this.seenSteps});

  /// Belum ada yang dilihat — keadaan instalasi baru, dan keadaan yang dipakai
  /// saat dokumen progres rusak.
  static const empty = TutorialProgress(onboardingDone: false, seenSteps: {});

  /// Onboarding sudah selesai atau dilewati.
  final bool onboardingDone;

  /// Langkah tur yang sudah pernah dilihat (atau dilewati).
  final Set<SpotlightKey> seenSteps;

  /// True kalau langkah [step] sudah dilihat.
  bool hasSeen(SpotlightKey step) => seenSteps.contains(step);

  /// True kalau seluruh langkah [tour] sudah dilihat.
  bool hasCompleted(TourId tour) => tourSteps[tour]!.every(hasSeen);

  /// Salinan dengan field yang diganti.
  TutorialProgress copyWith({bool? onboardingDone, Set<SpotlightKey>? seenSteps}) => TutorialProgress(
    onboardingDone: onboardingDone ?? this.onboardingDone,
    seenSteps: seenSteps ?? this.seenSteps,
  );

  @override
  List<Object?> get props => [onboardingDone, seenSteps];
}
