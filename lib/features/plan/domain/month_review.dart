import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';

/// Langkah tinjau awal bulan (J4, ADR-036 §3.7). Semuanya bisa dilewati.
enum MonthReviewStep {
  /// Anggaran rutin yang baru lahir.
  budgets,

  /// Rutin bernominal kira-kira.
  estimates,

  /// Kilas balik bulan lalu (W10, W9).
  lookback,
}

/// Status tinjau satu bulan keuangan. Disimpan satu dokumen untuk bulan
/// berjalan; bulan baru menimpanya.
final class MonthReview extends Equatable {
  /// Membuat [MonthReview].
  const MonthReview({
    required this.monthStart,
    this.doneSteps = const {},
    this.completed = false,
    this.dismissed = false,
  });

  /// Awal bulan keuangan yang ditinjau.
  final DateTime monthStart;

  /// Langkah yang sudah dicentang.
  final Set<MonthReviewStep> doneSteps;

  /// "Selesai meninjau" ditekan.
  final bool completed;

  /// "Nanti" ditekan: kartu dilipat jadi satu baris.
  final bool dismissed;

  /// Salinan dengan field yang disebutkan diganti.
  MonthReview copyWith({Set<MonthReviewStep>? doneSteps, bool? completed, bool? dismissed}) => MonthReview(
    monthStart: monthStart,
    doneSteps: doneSteps ?? this.doneSteps,
    completed: completed ?? this.completed,
    dismissed: dismissed ?? this.dismissed,
  );

  @override
  List<Object?> get props => [monthStart, doneSteps, completed, dismissed];
}

/// Tinjau awal bulan tersimpan di `plan/month_review` (ADR-036 §3.7).
abstract interface class MonthReviewRepository {
  /// Status tersimpan, atau `null` bila belum pernah.
  Future<Either<Failure, MonthReview?>> load();

  /// Menyimpan [review], menimpa bulan sebelumnya.
  Future<Either<Failure, Unit>> save(MonthReview review);
}
