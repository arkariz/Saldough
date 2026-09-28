import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/tutorial/spotlight_key.dart';
import 'package:saldough/core/tutorial/tutorial_progress.dart';

/// Penyimpanan [TutorialProgress] (ADR-021 §3.1).
///
/// Pemanggil memperlakukan `Left` dari [load] sebagai
/// [TutorialProgress.empty] — dokumen rusak berarti "belum dilihat", bukan
/// aplikasi gagal dibuka.
abstract interface class TutorialProgressRepository {
  /// Membaca progres; dokumen yang belum ada berarti [TutorialProgress.empty].
  Future<Either<Failure, TutorialProgress>> load();

  /// Menandai onboarding selesai.
  Future<Either<Failure, Unit>> markOnboardingDone();

  /// Menandai [steps] sudah dilihat.
  Future<Either<Failure, Unit>> markStepsSeen(Iterable<SpotlightKey> steps);

  /// Mengembalikan seluruh langkah [tour] ke belum dilihat.
  Future<Either<Failure, Unit>> resetTour(TourId tour);

  /// Mengembalikan onboarding dan seluruh tur ke belum dilihat.
  Future<Either<Failure, Unit>> resetAll();
}
