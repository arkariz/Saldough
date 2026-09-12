import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/cycle/domain/entities/budget_line.dart';
import 'package:saldough/features/cycle/domain/entities/cycle_template.dart';
import 'package:saldough/features/cycle/domain/entities/income_line.dart';
import 'package:saldough/features/cycle/domain/entities/investment_plan.dart';
import 'package:saldough/features/cycle/domain/entities/monthly_cycle.dart';
import 'package:saldough/features/cycle/domain/entities/roll_up_source.dart';
import 'package:saldough/features/cycle/domain/repositories/cycle_repository.dart';
import 'package:saldough/features/cycle/domain/repositories/cycle_template_repository.dart';

/// Membuat siklus bulan berikutnya dari [CycleTemplate], dengan empat aturan
/// ADR-0008:
///
/// 1. Salin hanya baris template (baris template selalu `isTemplate: true`
///    secara definisi — lihat `CycleTemplate`).
/// 2. Untuk baris `rollUp`, salin strukturnya tapi bukan nominalnya — diisi
///    0 sementara, dihitung ulang saat siklus baru dibaca lewat
///    `CycleRepository.getCycle`.
/// 3. Tandai setiap baris hasil salinan `needsReview: true`.
/// 4. Salin `defaultAllocations` apa adanya ke `investmentPlan.allocations`.
final class RollOverCycle {
  /// Membuat [RollOverCycle] dengan kedua repository yang dibutuhkan.
  RollOverCycle({
    required this._cycleRepository,
    required this._templateRepository,
  });

  final CycleRepository _cycleRepository;
  final CycleTemplateRepository _templateRepository;

  /// Menjalankan rollover dari siklus ber-`id` [fromCycleId] ke bulan
  /// berikutnya.
  ///
  /// `Left(BusinessRuleFailure)` kalau siklus bulan berikutnya sudah ada —
  /// rollover tidak pernah menimpa siklus yang sudah dibuat.
  Future<Either<Failure, MonthlyCycle>> call(String fromCycleId) async {
    final nextId = _nextCycleId(fromCycleId);

    final existing = await _cycleRepository.getCycle(nextId);
    switch (existing) {
      case Left(value: final failure):
        return left(failure);
      case Right(value: final cycle) when cycle != null:
        return left(
          BusinessRuleFailure(
            code: const FailureCode('CYCLE_ALREADY_EXISTS'),
            message: 'Siklus $nextId sudah ada, rollover tidak menimpanya.',
            userMessage: 'Siklus bulan $nextId sudah ada.',
          ),
        );
      case Right():
        break;
    }

    final templateResult = await _templateRepository.getTemplate();
    return switch (templateResult) {
      Left(value: final failure) => left(failure),
      Right(value: final template) => await _createFrom(nextId, template),
    };
  }

  Future<Either<Failure, MonthlyCycle>> _createFrom(
    String nextId,
    CycleTemplate template,
  ) async {
    var counter = 0;
    String freshId(String prefix) => '$nextId-$prefix-${counter++}';

    final incomeLines = [
      for (final line in template.incomeLines)
        IncomeLine(
          id: freshId('income'),
          label: line.label,
          amount: line.amount,
          sourceId: line.sourceId,
          isTemplate: true,
          needsReview: true,
        ),
    ];

    final budgetLines = [
      for (final line in template.budgetLines)
        BudgetLine(
          id: freshId('budget'),
          label: line.label,
          // Aturan 2: baris rollUp tidak membawa nominal lama. Diisi 0,
          // dihitung ulang saat siklus baru dibaca (lihat RollUpResolver).
          amount: line.kind == .rollUp ? 0 : line.amount,
          kind: line.kind,
          // `GroceryRollUpSource.planId` dari template masih menunjuk siklus
          // ASAL (siklus tempat baris itu ditandai tetap) -- tautan 1:1
          // `GroceryPlan`↔`MonthlyCycle` berarti siklus BARU ini harus
          // menunjuk rencana belanja bulan INI, bukan warisan planId lama.
          // `CardRollUpSource` tidak berubah -- kartu bukan per-bulan.
          rollUpSource: line.rollUpSource is GroceryRollUpSource
              ? RollUpSource.grocery(nextId)
              : line.rollUpSource,
          isTemplate: true,
          needsReview: true,
        ),
    ];

    final newCycle = MonthlyCycle(
      id: nextId,
      incomeLines: incomeLines,
      budgetLines: budgetLines,
      investmentPlan: InvestmentPlan(
        returnDeposit: 0,
        allocations: template.defaultAllocations,
      ),
    );

    final saveResult = await _cycleRepository.saveCycle(newCycle);
    return switch (saveResult) {
      Left(value: final failure) => left(failure),
      Right() => right(newCycle),
    };
  }

  static String _nextCycleId(String cycleId) {
    final parts = cycleId.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final nextMonth = month == 12 ? 1 : month + 1;
    final nextYear = month == 12 ? year + 1 : year;
    return '$nextYear-${nextMonth.toString().padLeft(2, '0')}';
  }
}
