import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/shared/recurring/recurring.dart';

void main() {
  late RecurringRuleRepositoryImpl repository;

  T read<T>(Either<Failure, T> result) => result.getOrElse((_) => throw StateError('expected Right'));

  final netflix = RecurringRule(
    id: 'netflix',
    kind: RecurringKind.expense,
    amount: 6500000,
    walletId: 'bca',
    categoryId: 'hiburan',
    note: 'Netflix',
    schedule: RecurringSchedule(frequency: RecurringFrequency.monthly, anchorDate: DateTime(2026, 1, 31)),
    end: const RecurringEndsAfter(12),
    paymentMode: RecurringPaymentMode.autoDebit,
    skippedDates: {DateTime(2026, 3, 31, 10)},
  );

  final tabungan = RecurringRule(
    id: 'tabungan',
    kind: RecurringKind.transfer,
    amount: 100000000,
    amountMode: RecurringAmountMode.estimated,
    walletId: 'bca',
    toWalletId: 'jago',
    note: 'Ke tabungan',
    schedule: RecurringSchedule(
      frequency: RecurringFrequency.weekly,
      interval: 2,
      anchorDate: DateTime(2026, 10),
    ),
    end: RecurringEndsOn(DateTime(2027, 6, 30)),
    isPaused: true,
  );

  setUp(() => repository = RecurringRuleRepositoryImpl(storage: InMemoryKeyValueStorage()));

  test('daftar kosong sebelum ada yang disimpan', () async {
    expect(read(await repository.listRules()), isEmpty);
  });

  test('menyimpan lalu membaca kembali seluruh field, termasuk akhir dan tanggal dilewati', () async {
    await repository.saveRule(netflix);
    await repository.saveRule(tabungan);
    final rules = read(await repository.listRules());
    expect(rules, [netflix, tabungan]);
    expect(rules.first.skippedDates, {DateTime(2026, 3, 31)});
    expect(rules.first.schedule.anchorDay, 31);
    expect(rules.last.effectivePaymentMode, RecurringPaymentMode.manual);
  });

  test('menimpa di posisi semula dan menghapus menurut id', () async {
    await repository.saveRule(netflix);
    await repository.saveRule(tabungan);
    await repository.saveRule(netflix.copyWith(amount: 7900000));
    expect(read(await repository.listRules()).map((r) => r.amount), [7900000, 100000000]);

    await repository.deleteRule('netflix');
    await repository.deleteRule('tidak-ada');
    expect(read(await repository.listRules()).map((r) => r.id), ['tabungan']);
  });
}
