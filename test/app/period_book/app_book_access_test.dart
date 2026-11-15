import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/app/period_book/app_book_access.dart';
import 'package:saldough/app/period_book/period_book_gate.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/features/period_book/domain/entities/closed_period.dart';
import 'package:saldough/features/period_book/domain/entities/period_book_content.dart';
import 'package:saldough/features/period_book/domain/entities/period_book_memory.dart';
import 'package:saldough/features/period_book/domain/entities/ritual_info.dart';
import 'package:saldough/features/period_book/domain/repositories/period_book_memory_store.dart';
import 'package:saldough/features/period_book/domain/repositories/period_book_source.dart';
import 'package:saldough/features/period_book/presentation/period_book_read_access.dart';
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
  _Source({this.untagged = 0, this.plan});
  final int untagged;
  final BookPlan? plan;

  @override
  Future<Either<Failure, PeriodBookContent>> contentFor(ClosedPeriod period) async => Right(
    PeriodBookContent(
      period: period,
      flow: const BookFlow(income: 1, expense: 1),
      uncategorizedCount: untagged,
      plan: plan,
    ),
  );

  @override
  Future<Either<Failure, RitualInfo>> ritualFor(ClosedPeriod period) => throw UnimplementedError();
}

final class _Wallets implements WalletRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Entitlements entitlements;
  late _Memory memory;
  late PeriodBookGate gate;
  late List<Set<String>> absorbed;

  AppBookAccess access({_Source? source}) => AppBookAccess(
    gate: gate,
    source: source ?? _Source(plan: const BookPlan(recorded: 1, skipped: 1)),
    transactions: _Txs(),
    wallets: _Wallets(),
    absorbStamps: absorbed.add,
  );

  setUp(() {
    entitlements = _Entitlements();
    memory = _Memory();
    absorbed = [];
    gate = PeriodBookGate(
      entitlements: entitlements,
      memory: memory,
      transactions: _Txs(),
      schedule: _Schedule(),
      now: () => DateTime(2026, 11, 14),
    );
  });

  test('membuka buku: ditandai dibuka, stempel periode tercetak permanen dan dilipat ke sampul', () async {
    final load = await access().open('2026-10-01') as BookReady;
    expect(load.stamps, ['period_tidy', 'recurring_clear']);
    expect(memory.value.isOpened('2026-10-01'), isTrue);
    expect(memory.value.stampsOf('2026-10-01'), {'period_tidy', 'recurring_clear'});
    expect(absorbed, [
      {'period_tidy', 'recurring_clear'},
    ]);
  });

  test('stempel yang sudah tercetak tidak dicabut walau datanya berubah (G-1)', () async {
    await access().open('2026-10-01');
    // Data berubah: sekarang ada transaksi tanpa kategori dan rutin belum beres.
    final changed = access(source: _Source(untagged: 2, plan: const BookPlan(recorded: 1, open: 3)));
    final load = await changed.open('2026-10-01') as BookReady;
    expect(load.stamps, ['period_tidy', 'recurring_clear']);
  });

  test('bukan Plus dan belum dibuka: terkunci, tidak ada yang ditandai atau dicetak (BP-10)', () async {
    entitlements.plus = false;
    expect(await access().open('2026-10-01'), isA<BookLocked>());
    expect(memory.value.isOpened('2026-10-01'), isFalse);
    expect(memory.value.stamps, isEmpty);
    expect(absorbed, isEmpty);
  });

  test('sudah pernah dibuka: tetap terbuka sesudah Plus berakhir; periode tak dikenal gagal', () async {
    await access().open('2026-10-01');
    entitlements.plus = false;
    expect(await access().open('2026-10-01'), isA<BookReady>());
    expect(await access().open('2026-01-01'), isA<BookFailed>());
  });
}
