import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/features/investment/data/repositories/goal_loan_repository_impl.dart';
import 'package:saldough/features/investment/domain/entities/goal_loan.dart';

void main() {
  late InMemoryKeyValueStorage storage;
  late GoalLoanRepositoryImpl repository;

  setUp(() {
    storage = InMemoryKeyValueStorage();
    repository = GoalLoanRepositoryImpl(storage: storage);
  });

  group('GoalLoanRepositoryImpl', () {
    test('menyimpan lalu membaca pinjaman mengembalikan nilai yang sama', () async {
      final loan = GoalLoan(
        id: 'l1',
        fromGoalId: 'a',
        toGoalId: 'b',
        principal: 930000000,
        repaid: 933100000,
        date: DateTime(2026, 9, 2),
        note: 'cicilan 1',
      );

      await repository.saveLoan(loan);
      final result = await repository.listLoans();

      final loans = result.getOrElse((_) => throw StateError('expected Right'));
      expect(loans.single, loan);
    });

    test('menyimpan ulang pinjaman ber-id sama menimpa, bukan menambah', () async {
      final loan = GoalLoan(id: 'l1', fromGoalId: 'a', toGoalId: 'b', principal: 1000, repaid: 1000, date: DateTime(2026));
      await repository.saveLoan(loan);
      await repository.saveLoan(loan.copyWith(repaid: 2000));

      final result = await repository.listLoans();
      final loans = result.getOrElse((_) => throw StateError('expected Right'));
      expect(loans, hasLength(1));
      expect(loans.single.repaid, 2000);
    });

    test('menghapus pinjaman ber-id tertentu', () async {
      await repository.saveLoan(
        GoalLoan(id: 'l1', fromGoalId: 'a', toGoalId: 'b', principal: 1000, repaid: 1000, date: DateTime(2026)),
      );
      await repository.deleteLoan('l1');

      final result = await repository.listLoans();
      expect(result.getOrElse((_) => throw StateError('expected Right')), isEmpty);
    });
  });
}
