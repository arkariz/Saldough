import 'package:dependencies/dependencies.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saldough/features/worklog/domain/entities/billing_book.dart';
import 'package:saldough/features/worklog/domain/entities/work_log_entry.dart';
import 'package:saldough/features/worklog/domain/repositories/worklog_repository.dart';
import 'package:saldough/features/worklog/domain/usecases/close_billing_book.dart';
import 'package:saldough/shared/income/income.dart';

class MockWorklogRepository extends Mock implements WorklogRepository {}

void main() {
  late MockWorklogRepository repository;

  setUpAll(() {
    registerFallbackValue(
      BillingBook(id: 'b', sourceId: 's', startDate: DateTime(2026), entries: const []),
    );
  });

  setUp(() {
    repository = MockWorklogRepository();
    when(() => repository.saveBook(any())).thenAnswer((_) async => right(unit));
  });

  final source = IncomeSource(
    id: 'gaji-menul',
    name: 'Gaji Menul',
    kind: IncomeSourceKind.hourlyFreelance,
    hourlyRate: 7250000,
    deductionRules: const [
      DeductionRule(id: 'pajak', label: 'Pajak', kind: DeductionKind.percentage, value: 25),
    ],
  );

  group('CloseBillingBook', () {
    test('menutup buku terbuka dan menghitung gaji bersih dari totalHours', () async {
      final closeBook = CloseBillingBook(repository: repository);
      final book = BillingBook(
        id: 'b1',
        sourceId: source.id,
        startDate: DateTime(2026, 8, 29),
        entries: [
          WorkLogEntry(id: 'e1', date: DateTime(2026, 8, 29), hours: 10, startsNewBook: true),
          WorkLogEntry(id: 'e2', date: DateTime(2026, 9, 5), hours: 5),
        ],
      );

      final result = await closeBook(book: book, source: source);

      expect(result.isRight(), isTrue);
      final breakdown = result.getOrElse((_) => throw StateError('expected Right'));
      expect(breakdown.grossPay, 15 * 7250000);
      expect(breakdown.netPay, breakdown.grossPay - breakdown.deductions.single.amount);

      final saved = verify(() => repository.saveBook(captureAny())).captured.single as BillingBook;
      expect(saved.isClosed, isTrue);
      expect(saved.netPayAmount, breakdown.netPay);
    });

    test('menolak menutup buku yang sudah ditutup', () async {
      final closeBook = CloseBillingBook(repository: repository);
      final entry = WorkLogEntry(id: 'e1', date: DateTime(2026, 8, 29), hours: 10, startsNewBook: true);
      final book = BillingBook(id: 'b1', sourceId: source.id, startDate: entry.date, entries: [entry])
          .close(netPayAmount: 1);

      final result = await closeBook(book: book, source: source);

      expect(result.isLeft(), isTrue);
      verifyNever(() => repository.saveBook(any()));
    });

    test('menolak menutup buku tanpa entri', () async {
      final closeBook = CloseBillingBook(repository: repository);
      final book = BillingBook(id: 'b1', sourceId: source.id, startDate: DateTime(2026), entries: const []);

      final result = await closeBook(book: book, source: source);

      expect(result.isLeft(), isTrue);
      verifyNever(() => repository.saveBook(any()));
    });
  });
}
