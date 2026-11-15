import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/app/period_book/period_book_gate.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/features/period_book/domain/entities/period_book_memory.dart';
import 'package:saldough/features/period_book/domain/repositories/period_book_memory_store.dart';
import 'package:saldough/features/period_book/domain/services/period_book_access.dart';
import 'package:saldough/features/period_book/domain/services/period_book_shelf.dart';
import 'package:saldough/shared/transaction/transaction.dart';

final class _Entitlements implements Entitlements {
  bool plus = true;

  @override
  bool can(PlusFeature feature) => plus && feature == PlusFeature.periodBook;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Memory implements PeriodBookMemoryStore {
  PeriodBookMemory value = PeriodBookMemory.empty;
  int saves = 0;

  @override
  Future<Either<Failure, PeriodBookMemory>> load() async => Right(value);

  @override
  Future<Either<Failure, Unit>> save(PeriodBookMemory memory) async {
    value = memory;
    saves++;
    return const Right(unit);
  }
}

final class _Transactions implements TransactionRepository {
  _Transactions(this.all);
  final List<Transaction> all;

  @override
  Future<Either<Failure, List<Transaction>>> listAllTransactions() async => Right(all);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Schedule implements FinancialMonthPreferenceRepository {
  @override
  Future<Either<Failure, FinancialMonthSchedule>> load() async => Right(FinancialMonthSchedule.initial);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ExpenseTransaction _tx(int i) => ExpenseTransaction(
  id: 't$i',
  date: DateTime(2026, 10, 2 + i),
  amount: 1000,
  note: '',
  walletId: 'w',
  categoryId: 'c',
);

void main() {
  late _Entitlements entitlements;
  late _Memory memory;
  late PeriodBookGate gate;

  setUp(() {
    entitlements = _Entitlements();
    memory = _Memory();
    gate = PeriodBookGate(
      entitlements: entitlements,
      memory: memory,
      transactions: _Transactions([for (var i = 0; i < 3; i++) _tx(i)]),
      schedule: _Schedule(),
      now: () => DateTime(2026, 11, 14),
    );
  });

  test('gerbang rute: Plus membuka apa pun; berakhir hanya yang pernah dibuka (BP-10)', () async {
    expect(await gate.accessOf('2026-10-01'), BookAccess.open);
    entitlements.plus = false;
    expect(await gate.accessOf('2026-10-01'), BookAccess.locked);
    entitlements.plus = true;
    await gate.markOpened('2026-10-01');
    entitlements.plus = false;
    expect(await gate.accessOf('2026-10-01'), BookAccess.open);
    expect(await gate.accessOf('2026-09-01'), BookAccess.locked);
  });

  test('markOpened menyimpan sekali; tanggal pertama dipertahankan', () async {
    await gate.markOpened('2026-10-01');
    await gate.markOpened('2026-10-01');
    expect(memory.saves, 1);
    expect(memory.value.opened['2026-10-01'], DateTime(2026, 11, 14));
  });

  test('rak dan ajakan mengikuti paket dan ingatan', () async {
    expect((await gate.shelf()).single.status, ShelfStatus.unopened);
    expect((await gate.invitation())?.kind, InvitationKind.book);
    entitlements.plus = false;
    expect((await gate.shelf()).single.status, ShelfStatus.locked);
    expect((await gate.invitation())?.kind, InvitationKind.card);
    await gate.dismissCard('2026-10-01');
    expect(await gate.invitation(), isNull);
  });

  test('sakelar ajakan Plus (BP-14) disimpan', () async {
    await gate.setInviteEnabled(enabled: false);
    expect(await gate.invitation(), isNull);
    await gate.setInviteEnabled(enabled: true);
    expect((await gate.invitation())?.kind, InvitationKind.book);
  });
}
