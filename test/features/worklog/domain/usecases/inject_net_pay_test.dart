import 'package:dependencies/dependencies.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saldough/features/worklog/domain/entities/billing_book.dart';
import 'package:saldough/features/worklog/domain/entities/work_log_entry.dart';
import 'package:saldough/features/worklog/domain/repositories/cycle_income_writer.dart';
import 'package:saldough/features/worklog/domain/repositories/worklog_repository.dart';
import 'package:saldough/features/worklog/domain/usecases/inject_net_pay.dart';

class MockCycleIncomeWriter extends Mock implements CycleIncomeWriter {}

class MockWorklogRepository extends Mock implements WorklogRepository {}

void main() {
  late MockCycleIncomeWriter writer;
  late MockWorklogRepository repository;

  setUpAll(() {
    registerFallbackValue(
      BillingBook(id: 'b', sourceId: 's', startDate: DateTime(2026), entries: const []),
    );
  });

  setUp(() {
    writer = MockCycleIncomeWriter();
    repository = MockWorklogRepository();
  });

  final closedEntry = WorkLogEntry(id: 'e1', date: DateTime(2026, 8, 29), hours: 15, startsNewBook: true);
  BillingBook closedBook() =>
      BillingBook(id: 'b1', sourceId: 'gaji-menul', startDate: closedEntry.date, entries: [closedEntry])
          .close(netPayAmount: 303956250);

  group('InjectNetPay', () {
    test('menyuntikkan gaji bersih lewat CycleIncomeWriter lalu menandai buku', () async {
      when(() => writer.inject(
            cycleId: '2026-09',
            sourceId: 'gaji-menul',
            sourceLabel: 'Gaji Menul',
            amount: 303956250,
          )).thenAnswer((_) async => right('line-1'));
      when(() => repository.saveBook(any())).thenAnswer((_) async => right(unit));

      final inject = InjectNetPay(writer: writer, repository: repository);
      final result = await inject(book: closedBook(), sourceLabel: 'Gaji Menul', cycleId: '2026-09');

      expect(result.isRight(), isTrue);
      final saved = verify(() => repository.saveBook(captureAny())).captured.single as BillingBook;
      expect(saved.isInjected, isTrue);
      expect(saved.injectedCycleId, '2026-09');
      expect(saved.injectedIncomeLineId, 'line-1');
    });

    test('menolak menyuntikkan buku yang belum ditutup', () async {
      final open = BillingBook(id: 'b1', sourceId: 'gaji-menul', startDate: DateTime(2026), entries: [closedEntry]);
      final inject = InjectNetPay(writer: writer, repository: repository);

      final result = await inject(book: open, sourceLabel: 'Gaji Menul', cycleId: '2026-09');

      expect(result.isLeft(), isTrue);
      verifyNever(() => writer.inject(
            cycleId: any(named: 'cycleId'),
            sourceId: any(named: 'sourceId'),
            sourceLabel: any(named: 'sourceLabel'),
            amount: any(named: 'amount'),
          ));
    });

    test('menolak menyuntikkan buku yang sudah pernah disuntikkan', () async {
      final injected = closedBook().markInjected(cycleId: '2026-08', incomeLineId: 'line-0');
      final inject = InjectNetPay(writer: writer, repository: repository);

      final result = await inject(book: injected, sourceLabel: 'Gaji Menul', cycleId: '2026-09');

      expect(result.isLeft(), isTrue);
      verifyNever(() => writer.inject(
            cycleId: any(named: 'cycleId'),
            sourceId: any(named: 'sourceId'),
            sourceLabel: any(named: 'sourceLabel'),
            amount: any(named: 'amount'),
          ));
    });
  });
}
