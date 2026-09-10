import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/cycle/domain/entities/income_line.dart';
import 'package:saldough/features/cycle/domain/repositories/cycle_repository.dart';
import 'package:saldough/features/worklog/domain/repositories/cycle_income_writer.dart';

/// Implementasi [CycleIncomeWriter] (port milik fitur `worklog`) di atas
/// [CycleRepository] fitur ini sendiri — lihat catatan revisi ADR-0009 bagian
/// "Tujuh fitur MVP". `worklog` tidak pernah mengimpor `CycleRepository`
/// atau `MonthlyCycle` secara langsung; satu-satunya yang dibagikan adalah
/// antarmuka kecil [CycleIncomeWriter] ini, dikawat di `RootModule`.
final class CycleIncomeWriterImpl implements CycleIncomeWriter {
  /// Membuat [CycleIncomeWriterImpl] di atas [_cycleRepository].
  const CycleIncomeWriterImpl({required this._cycleRepository});

  final CycleRepository _cycleRepository;

  @override
  Future<Either<Failure, String>> inject({
    required String cycleId,
    required String sourceId,
    required String sourceLabel,
    required int amount,
  }) async {
    final cycleResult = await _cycleRepository.getCycle(cycleId);
    switch (cycleResult) {
      case Left(value: final failure):
        return left(failure);
      case Right(value: null):
        return left(BusinessRuleFailure(
          code: const FailureCode('CYCLE_NOT_FOUND'),
          message: 'Siklus $cycleId belum ada, tidak bisa disuntik.',
          userMessage: 'Siklus $cycleId belum ada.',
        ));
      case Right(value: final cycle?) when cycle.isClosed:
        return left(BusinessRuleFailure(
          code: const FailureCode('CYCLE_CLOSED'),
          message: 'Siklus $cycleId sudah ditutup, tidak bisa disuntik.',
          userMessage: 'Siklus $cycleId sudah ditutup. Buka kembali dulu.',
        ));
      case Right(value: final cycle?):
        final existing = cycle.incomeLines.where((l) => l.sourceId == sourceId).firstOrNull;
        final line = existing?.copyWith(amount: amount) ??
            IncomeLine(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              label: sourceLabel,
              amount: amount,
              sourceId: sourceId,
            );
        final lines = [
          ...cycle.incomeLines.where((l) => l.id != line.id),
          line,
        ];

        final saveResult = await _cycleRepository.saveCycle(cycle.copyWith(incomeLines: lines));
        return switch (saveResult) {
          Left(value: final failure) => left(failure),
          Right() => right(line.id),
        };
    }
  }
}
