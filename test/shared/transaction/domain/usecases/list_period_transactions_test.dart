import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saldough/shared/transaction/transaction.dart';

import '../../../../helpers/mocks.dart';

/// Pembacaan transaksi satu periode: dokumen bulan yang disentuh ± 7 hari
/// (ADR-038 §3.5), bukan seluruh riwayat (NFR-PERF-002).
void main() {
  late MockTransactionRepository repository;

  setUp(() {
    repository = MockTransactionRepository();
    when(() => repository.listTransactionsInMonth(any())).thenAnswer((_) async => right(const <Transaction>[]));
  });

  List<DateTime> months() => verify(() => repository.listTransactionsInMonth(captureAny())).captured.cast<DateTime>();

  test('periode 25 Okt – 24 Nov membaca Okt, Nov, dan Des (batas atribusi 7 hari), bukan Sep atau Jan', () async {
    final result = await ListPeriodTransactions(repository)(from: DateTime(2026, 10, 25), until: DateTime(2026, 11, 25));
    expect(result.isRight(), isTrue);
    expect(months(), [DateTime(2026, 10), DateTime(2026, 11), DateTime(2026, 12)]);
  });

  test('periode kalender biasa 1 – 30 Sep membaca Agt (1 Sep − 7 hari), Sep, dan Okt (1 Okt + 7 hari)', () async {
    await ListPeriodTransactions(repository)(from: DateTime(2026, 9), until: DateTime(2026, 10));
    expect(months(), [DateTime(2026, 8), DateTime(2026, 9), DateTime(2026, 10)]);
  });

  test('transaksi tiap dokumen digabung berurutan', () async {
    final a = ExpenseTransaction(id: 'a', date: DateTime(2026, 9, 5), amount: 1, note: '', walletId: 'w');
    final b = ExpenseTransaction(id: 'b', date: DateTime(2026, 10, 2), amount: 2, note: '', walletId: 'w');
    when(() => repository.listTransactionsInMonth(DateTime(2026, 9))).thenAnswer((_) async => right([a]));
    when(() => repository.listTransactionsInMonth(DateTime(2026, 10))).thenAnswer((_) async => right([b]));
    final result = await ListPeriodTransactions(repository)(from: DateTime(2026, 9, 10), until: DateTime(2026, 9, 20));
    expect(result.getOrElse((_) => const []), [a]);
  });

  test('gagal membaca satu bulan menghentikan pembacaan dan mengembalikan galatnya', () async {
    const failure = SystemFailure(code: FailureCode('TEST_FORCED_FAILURE'), message: 'dipaksa gagal');
    when(() => repository.listTransactionsInMonth(DateTime(2026, 11))).thenAnswer((_) async => left(failure));
    final result = await ListPeriodTransactions(repository)(from: DateTime(2026, 10, 25), until: DateTime(2026, 11, 25));
    expect(result.fold((f) => f, (_) => null), failure);
    verifyNever(() => repository.listTransactionsInMonth(DateTime(2026, 12)));
  });
}
