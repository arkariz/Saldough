import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/income/domain/repositories/income_worklog_gateway.dart';
import 'package:saldough/features/worklog/domain/repositories/worklog_repository.dart';

/// Implementasi [IncomeWorklogGateway] (port milik fitur `income`) di atas
/// [WorklogRepository] fitur ini sendiri — lihat catatan revisi ADR-0009
/// bagian "Tujuh fitur MVP". `income` tidak pernah mengimpor
/// `WorklogRepository` atau `BillingBook` secara langsung; satu-satunya
/// yang dibagikan adalah antarmuka kecil [IncomeWorklogGateway] ini,
/// dikawat di `RootModule`.
final class IncomeWorklogGatewayImpl implements IncomeWorklogGateway {
  /// Membuat [IncomeWorklogGatewayImpl] di atas [_repository].
  const IncomeWorklogGatewayImpl({required this._repository});

  final WorklogRepository _repository;

  @override
  Future<Either<Failure, Map<String, int>>> openBookHoursBySourceId(List<String> sourceIds) async {
    final result = <String, int>{};
    for (final sourceId in sourceIds) {
      final booksResult = await _repository.listBooks(sourceId);
      switch (booksResult) {
        case Left(value: final failure):
          return left(failure);
        case Right(value: final books):
          final open = books.where((b) => !b.isClosed).firstOrNull;
          if (open != null) result[sourceId] = open.totalHours;
      }
    }
    return right(result);
  }
}
