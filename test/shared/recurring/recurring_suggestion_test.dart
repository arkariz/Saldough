import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Saran "Sepertinya rutin" (T-17.7, ADR-037 §3.3).
void main() {
  final today = DateTime(2026, 10, 6);

  ExpenseTransaction gym(int month, {int day = 5, int amount = 30000000, String note = 'Gym', String? ruleId}) =>
      ExpenseTransaction(
        id: 'gym-$month-$day',
        date: DateTime(2026, month, day),
        amount: amount,
        note: note,
        walletId: 'bca',
        recurrence: ruleId == null ? null : RecurrenceLink(ruleId: ruleId, occurrenceDate: DateTime(2026, month, day)),
      );

  List<RecurringSuggestion> suggest(
    List<Transaction> txs, {
    List<RecurringRule> rules = const [],
    Set<String> dismissed = const {},
  }) => suggestRecurring(txs, today: today, rules: rules, dismissed: dismissed);

  test('tiga bulan berturut-turut, nominal dan catatan sama: disarankan, yang terbaru dibawa', () {
    final result = suggest([gym(8), gym(9, day: 7), gym(10, day: 4)]);
    expect(result.single.latest.id, 'gym-10-4');
  });

  test('berakhir bulan lalu juga dihitung; dua bulan saja tidak', () {
    expect(suggest([gym(7), gym(8), gym(9)]), hasLength(1));
    expect(suggest([gym(9), gym(10)]), isEmpty);
  });

  test('bulan bolong, tanggal terlalu jauh, nominal beda, atau catatan kosong: tidak', () {
    expect(suggest([gym(7), gym(9), gym(10)]), isEmpty);
    expect(suggest([gym(8, day: 1), gym(9), gym(10, day: 20)]), isEmpty);
    expect(suggest([gym(8), gym(9, amount: 31000000), gym(10)]), isEmpty);
    expect(suggest([gym(8, note: ''), gym(9, note: ''), gym(10, note: '')]), isEmpty);
  });

  test('sudah tertaut, sudah punya rutin, atau ditolak: tidak', () {
    expect(suggest([gym(8, ruleId: 'r'), gym(9, ruleId: 'r'), gym(10, ruleId: 'r')]), isEmpty);
    final rule = RecurringRule(
      id: 'r',
      kind: RecurringKind.expense,
      amount: 30000000,
      walletId: 'bca',
      note: 'gym',
      schedule: RecurringSchedule(frequency: RecurringFrequency.monthly, anchorDate: DateTime(2026, 8, 5)),
    );
    expect(suggest([gym(8), gym(9), gym(10)], rules: [rule]), isEmpty);
    final key = suggest([gym(8), gym(9), gym(10)]).single.key;
    expect(suggest([gym(8), gym(9), gym(10)], dismissed: {key}), isEmpty);
  });

  test('penolakan tersimpan', () async {
    final store = RecurringSuggestionDismissalsImpl(storage: InMemoryKeyValueStorage());
    await store.add('a');
    await store.add('b');
    expect((await store.load()).getOrElse((_) => const {}), {'a', 'b'});
  });
}
