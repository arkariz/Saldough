import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/app/period_book/app_ritual_access.dart';
import 'package:saldough/app/period_book/period_book_gate.dart';
import 'package:saldough/app/shell/shell_requests.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/features/period_book/domain/entities/closed_period.dart';
import 'package:saldough/features/period_book/domain/entities/period_book_content.dart';
import 'package:saldough/features/period_book/domain/entities/period_book_memory.dart';
import 'package:saldough/features/period_book/domain/entities/ritual_info.dart';
import 'package:saldough/features/period_book/domain/repositories/period_book_memory_store.dart';
import 'package:saldough/features/period_book/domain/repositories/period_book_source.dart';
import 'package:saldough/features/period_book/presentation/period_book_ritual_access.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

final class _Entitlements implements Entitlements {
  bool plus = true;

  @override
  bool can(PlusFeature feature) => plus;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Memory implements PeriodBookMemoryStore {
  PeriodBookMemory value = PeriodBookMemory.empty;

  @override
  Future<Either<Failure, PeriodBookMemory>> load() async => Right(value);

  @override
  Future<Either<Failure, Unit>> save(PeriodBookMemory memory) async {
    value = memory;
    return const Right(unit);
  }
}

final class _Txs implements TransactionRepository {
  @override
  Future<Either<Failure, List<Transaction>>> listAllTransactions() async => Right([
    for (var i = 0; i < 3; i++)
      ExpenseTransaction(id: 't$i', date: DateTime(2026, 10, 2 + i), amount: 1, note: '', walletId: 'w', categoryId: 'c'),
  ]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Schedule implements FinancialMonthPreferenceRepository {
  @override
  Future<Either<Failure, FinancialMonthSchedule>> load() async => Right(FinancialMonthSchedule.initial);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Source implements PeriodBookSource {
  @override
  Future<Either<Failure, RitualInfo>> ritualFor(ClosedPeriod period) async =>
      Right(RitualInfo(period: period, untagged: const [], openRoutines: 0));

  @override
  Future<Either<Failure, PeriodBookContent>> contentFor(ClosedPeriod period) => throw UnimplementedError();
}

final class _Wallets implements WalletRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Entitlements entitlements;
  late _Memory memory;
  late AppRitualAccess access;

  setUp(() {
    entitlements = _Entitlements();
    memory = _Memory();
    final gate = PeriodBookGate(
      entitlements: entitlements,
      memory: memory,
      transactions: _Txs(),
      schedule: _Schedule(),
      now: () => DateTime(2026, 11, 14),
    );
    access = AppRitualAccess(
      gate: gate,
      source: _Source(),
      transactions: _Txs(),
      wallets: _Wallets(),
      shell: ShellRequests(),
    );
  });

  test('Plus: siap, melanjutkan dari langkah tersimpan; periode tidak dikenal gagal', () async {
    expect(await access.load('2026-10-01'), isA<RitualReady>());
    await access.markStepDone('2026-10-01', RitualStep.uncategorized);
    final ready = await access.load('2026-10-01') as RitualReady;
    expect(ready.resume, RitualStep.routines);
    expect(await access.load('2026-01-01'), isA<RitualFailed>());
  });

  test('bukan Plus dan belum pernah dibuka: terkunci di akar, bukan hanya di UI (BP-10); finish tidak menandai', () async {
    entitlements.plus = false;
    expect(await access.load('2026-10-01'), isA<RitualLocked>());
    await access.finish('2026-10-01');
    expect(memory.value.isOpened('2026-10-01'), isFalse);
  });

  test('finish menandai dibuka; sesudah Plus berakhir buku itu tetap bisa dimuat (BP-10)', () async {
    await access.finish('2026-10-01');
    expect(memory.value.isOpened('2026-10-01'), isTrue);
    entitlements.plus = false;
    expect(await access.load('2026-10-01'), isA<RitualReady>());
  });

  test('ShellRequests meneruskan permintaan ke pendengar', () async {
    final shell = ShellRequests();
    final requests = <ShellRequest>[];
    shell.stream.listen(requests.add);
    shell.send(ShellRequest.showPlanRecurring);
    await Future<void>.delayed(Duration.zero);
    expect(requests, [ShellRequest.showPlanRecurring]);
  });
}
