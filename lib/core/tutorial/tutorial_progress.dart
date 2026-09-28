import 'package:dependencies/dependencies.dart';

/// Tur spotlight yang dikenal aplikasi (ADR-021 §3.4). [name] adalah id
/// yang disimpan di dokumen progres — jangan diganti nama tanpa migrasi.
enum TourId {
  /// Beranda.
  home,

  /// Alur CATAT.
  record,

  /// Tab Dompet.
  wallet,

  /// Tab Transaksi.
  transaction,

  /// Tab Anggaran.
  budget,

  /// Rincian anggaran.
  budgetDetail,

  /// Ikhtisar Freelance.
  freelance,

  /// Rincian proyek Freelance.
  freelanceProject,
}

/// Progres onboarding dan tur spotlight di perangkat ini (ADR-021 §3.1).
///
/// Bukan data keuangan: kehilangan dokumen ini hanya berarti pengenalan dan
/// tur tampil lagi.
final class TutorialProgress extends Equatable {
  /// Membuat [TutorialProgress].
  const TutorialProgress({required this.onboardingDone, required this.completedTours});

  /// Belum ada yang dilihat — keadaan instalasi baru, dan keadaan yang dipakai
  /// saat dokumen progres rusak.
  static const empty = TutorialProgress(onboardingDone: false, completedTours: {});

  /// Onboarding sudah selesai atau dilewati.
  final bool onboardingDone;

  /// Tur yang sudah selesai atau dilewati.
  final Set<TourId> completedTours;

  /// True kalau [tour] sudah selesai.
  bool hasCompleted(TourId tour) => completedTours.contains(tour);

  /// Salinan dengan field yang diganti.
  TutorialProgress copyWith({bool? onboardingDone, Set<TourId>? completedTours}) => TutorialProgress(
    onboardingDone: onboardingDone ?? this.onboardingDone,
    completedTours: completedTours ?? this.completedTours,
  );

  @override
  List<Object?> get props => [onboardingDone, completedTours];
}
