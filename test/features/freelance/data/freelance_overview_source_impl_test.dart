import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/features/freelance/data/adapters/freelance_overview_source_impl.dart';
import 'package:saldough/features/freelance/data/repositories/freelance_repository_impl.dart';
import 'package:saldough/features/freelance/domain/entities/freelance_payment.dart';
import 'package:saldough/features/freelance/domain/entities/payment_status.dart';
import 'package:saldough/features/freelance/domain/entities/worklog_entry.dart';
import 'package:saldough/features/home/domain/freelance_overview_source.dart';

void main() {
  late FreelanceRepositoryImpl repository;
  late FreelanceOverviewSourceImpl source;
  const rate = 7250000; // Rp72.500 per jam

  WorklogEntry entry(String id, int hours, {String? paymentId}) => WorklogEntry(
    id: id,
    projectId: 'p1',
    date: DateTime(2026, 9),
    hours: hours,
    hourlyRate: rate,
    paymentId: paymentId,
  );

  FreelancePayment pending(String id, DateTime expected) =>
      FreelancePayment(id: id, projectId: 'p1', entryIds: const [], expectedDate: expected);

  FreelanceOverview? read(Either<Failure, FreelanceOverview?> result) =>
      result.getOrElse((_) => throw StateError('expected Right'));

  setUp(() {
    repository = FreelanceRepositoryImpl(storage: InMemoryKeyValueStorage());
    source = FreelanceOverviewSourceImpl(repository: repository);
  });

  test('tanpa pembayaran tertunda, ringkasan tidak ada (Beranda menyembunyikannya)', () async {
    await repository.saveEntries([entry('a', 5)]);
    await repository.savePayment(
      FreelancePayment(
        id: 'lunas',
        projectId: 'p1',
        entryIds: const ['a'],
        expectedDate: DateTime(2026, 9, 10),
        status: PaymentStatus.paid,
        walletId: 'bca',
        incomeTransactionId: 'freelance-lunas',
        receivedDate: DateTime(2026, 9, 10),
      ),
    );

    expect(read(await source.freelanceOverview()), isNull);
  });

  test('dengan pembayaran tertunda: jam, kotor, diterima, dan perkiraan terdekat', () async {
    await repository.saveEntries([
      entry('a', 37, paymentId: 'lunas'),
      entry('b', 10, paymentId: 'nanti'),
      entry('c', 8, paymentId: 'segera'),
      entry('d', 3),
    ]);
    await repository.savePayment(
      FreelancePayment(
        id: 'lunas',
        projectId: 'p1',
        entryIds: const ['a'],
        expectedDate: DateTime(2026, 8),
        status: PaymentStatus.paid,
        walletId: 'bca',
        incomeTransactionId: 'freelance-lunas',
        receivedDate: DateTime(2026, 8),
      ),
    );
    await repository.savePayment(pending('nanti', DateTime(2026, 10, 25)));
    await repository.savePayment(pending('segera', DateTime(2026, 10, 5)));

    final overview = read(await source.freelanceOverview())!;
    expect(overview.totalHours, 58);
    expect(overview.earned, 58 * rate);
    expect(overview.paid, 37 * rate);
    expect(overview.unpaid, 21 * rate);
    expect(overview.pendingCount, 2);
    expect(overview.nextExpectedDate, DateTime(2026, 10, 5));
  });
}
