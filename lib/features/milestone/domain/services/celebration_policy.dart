import 'package:dependencies/dependencies.dart';
import 'package:saldough/features/milestone/domain/entities/milestone_ledger.dart';
import 'package:saldough/features/milestone/domain/services/milestone_engine.dart';

/// Bentuk perayaan yang boleh tampil sekarang (GAMIFICATION G-4, G-6, G-8).
enum CelebrationKind {
  /// Tidak ada yang ditampilkan.
  none,

  /// Snackbar satu kalimat dengan aksi Lihat; satu atau beberapa stempel digabung.
  snackbar,

  /// Lembar pengenalan sekali, sebab stempel pertama sepanjang masa.
  firstSheet,

  /// Banner pengguna lama sekali (G-6): yang sudah memenuhi syarat masuk diam-diam.
  legacyBanner,
}

/// Keputusan perayaan untuk satu evaluasi.
final class CelebrationPlan extends Equatable {
  /// Membuat [CelebrationPlan].
  const CelebrationPlan(this.kind, [this.ids = const []]);

  /// Tidak ada perayaan.
  static const none = CelebrationPlan(CelebrationKind.none);

  /// Bentuknya.
  final CelebrationKind kind;

  /// Stempel yang dirayakan (kosong untuk [CelebrationKind.legacyBanner]).
  final List<String> ids;

  @override
  List<Object?> get props => [kind, ids];
}

/// Memutuskan perayaan dari hasil [evaluation] (fungsi murni, ADR-046 §3.7).
///
/// - G-8: sakelar mati → tidak ada perayaan, banner, atau lembar.
/// - G-6: pemasukan pertama (`quiet`) hanya memunculkan banner pengenalan, sekali
///   (`introShown`), tanpa perayaan satu per satu.
/// - G-4: paling banyak satu perayaan; beberapa stempel digabung. Bila
///   [blocked] (banner pembaruan, lembar Apa yang baru, tur, bukan Beranda,
///   atau layar lain di atasnya), **tidak ada** perayaan yang menunggu dan
///   muncul belakangan; hanya titik "belum dilihat" di Akun dan Buku Stempel.
/// - Stempel pertama sepanjang masa (`introShown` salah) memakai lembar
///   pengenalan, bukan snackbar.
CelebrationPlan planCelebration({
  required MilestoneEvaluation evaluation,
  required bool blocked,
}) {
  final ledger = evaluation.ledger;
  if (!ledger.celebrationEnabled) {
    return CelebrationPlan.none;
  }
  if (evaluation.quiet) {
    if (ledger.introShown || blocked || ledger.earned.isEmpty) {
      return CelebrationPlan.none;
    }
    return const CelebrationPlan(CelebrationKind.legacyBanner);
  }
  if (evaluation.newlyEarned.isEmpty || blocked) {
    return CelebrationPlan.none;
  }
  if (!ledger.introShown) {
    return CelebrationPlan(CelebrationKind.firstSheet, evaluation.newlyEarned.take(1).toList());
  }
  return CelebrationPlan(CelebrationKind.snackbar, evaluation.newlyEarned);
}

/// Ada stempel yang belum dilihat di Buku Stempel dan perayaan menyala: titik
/// kecil di ikon Akun, baris Buku Stempel, dan stempelnya (rupa §4.4).
bool hasUnseenStamps(MilestoneLedger ledger) =>
    ledger.celebrationEnabled && ledger.earned.values.any((e) => !e.seen);

/// Banner pengguna lama (G-6) masih harus tampil: sudah ada stempel yang masuk
/// diam-diam, pengenalan belum tampil, dan perayaan menyala. Berbasis keadaan,
/// bukan hasil satu evaluasi, supaya tidak hilang bila evaluasi pertama jatuh
/// saat Beranda belum tampil.
bool legacyBannerVisible(MilestoneLedger ledger) =>
    ledger.celebrationEnabled &&
    ledger.seeded &&
    !ledger.introShown &&
    ledger.earned.values.any((e) => e.quiet);
