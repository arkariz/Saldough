import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/freelance/domain/entities/freelance_payment.dart';
import 'package:saldough/features/freelance/domain/entities/worklog_entry.dart';
import 'package:saldough/features/freelance/domain/repositories/freelance_repository.dart';
import 'package:saldough/features/freelance/domain/usecases/summarize_worklog.dart';
import 'package:saldough/features/home/domain/freelance_overview_source.dart';

/// Implementasi port [FreelanceOverviewSource] milik `home` dari data
/// freelance (ADR-0009: port milik konsumen, implementasi di fitur penyedia,
/// dikawat di `RootModule`). Angkanya dari [SummarizeWorklog] yang sama
/// dengan puncak Ikhtisar Freelance.
final class FreelanceOverviewSourceImpl implements FreelanceOverviewSource {
  /// Membuat [FreelanceOverviewSourceImpl].
  const FreelanceOverviewSourceImpl({required this._repository});

  final FreelanceRepository _repository;

  @override
  Future<Either<Failure, FreelanceOverview?>> freelanceOverview() async {
    final List<FreelancePayment> payments;
    switch (await _repository.listPayments()) {
      case Left(:final value):
        return Left(value);
      case Right(:final value):
        payments = value;
    }
    final pending = payments.where((p) => !p.isPaid).toList();
    if (pending.isEmpty) return const Right(null);

    final List<WorklogEntry> entries;
    switch (await _repository.listEntries()) {
      case Left(:final value):
        return Left(value);
      case Right(:final value):
        entries = value;
    }
    final summary = const SummarizeWorklog()(entries, payments);
    final nextExpectedDate = pending.map((p) => p.expectedDate).reduce((a, b) => b.isBefore(a) ? b : a);
    return Right(
      FreelanceOverview(
        totalHours: summary.totalHours,
        earned: summary.earned,
        paid: summary.paid,
        pendingCount: pending.length,
        nextExpectedDate: nextExpectedDate,
      ),
    );
  }
}
