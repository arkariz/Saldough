import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/features/investment/data/models/goal_loan_model.dart';
import 'package:saldough/features/investment/domain/entities/goal_loan.dart';
import 'package:saldough/features/investment/domain/repositories/goal_loan_repository.dart';

const _loansKey = StorageKey(namespace: 'investment', name: 'loans');

/// Implementasi [GoalLoanRepository] di atas [KeyValueStorage], mengikuti
/// pola `GoalRepositoryImpl` (ADR-0009): seluruh pinjaman disimpan sebagai
/// satu dokumen JSON (daftar kecil).
final class GoalLoanRepositoryImpl with RepositoryGuard implements GoalLoanRepository {
  /// Membuat [GoalLoanRepositoryImpl] di atas [_storage].
  const GoalLoanRepositoryImpl({required this._storage});

  final KeyValueStorage _storage;

  StoredValue<List<GoalLoanModel>> get _store => StoredValue<List<GoalLoanModel>>.json(
        key: _loansKey,
        fromJson: (json) => (json['items'] as List<dynamic>)
            .map((e) => GoalLoanModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        toJson: (models) => {
          'schemaVersion': GoalLoanModel.schemaVersion,
          'items': models.map((m) => m.toJson()).toList(),
        },
        storage: _storage,
      );

  @override
  Future<Either<Failure, List<GoalLoan>>> listLoans() => guard(() async {
        final models = await _store.read();
        return (models ?? const []).map((m) => m.toEntity()).toList();
      });

  @override
  Future<Either<Failure, Unit>> saveLoan(GoalLoan loan) => guardVoid(() async {
        final models = await _store.read() ?? <GoalLoanModel>[];
        final next = [
          ...models.where((m) => m.id != loan.id),
          GoalLoanModel.fromEntity(loan),
        ];
        await _store.write(next);
      });

  @override
  Future<Either<Failure, Unit>> deleteLoan(String id) => guardVoid(() async {
        final models = await _store.read() ?? <GoalLoanModel>[];
        await _store.write(models.where((m) => m.id != id).toList());
      });
}
