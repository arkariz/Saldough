import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/features/freelance/data/repositories/freelance_repository_impl.dart';
import 'package:saldough/features/freelance/domain/entities/deduction_kind.dart';
import 'package:saldough/features/freelance/domain/entities/deduction_rule.dart';
import 'package:saldough/features/freelance/domain/entities/freelance_payment.dart';
import 'package:saldough/features/freelance/domain/entities/freelance_project.dart';
import 'package:saldough/features/freelance/domain/entities/worklog_entry.dart';
import 'package:saldough/shared/transaction/data/transaction_model.dart';
import 'package:saldough/shared/transaction/transaction.dart';

T _right<T>(Either<Failure, T> result) => result.getOrElse((_) => throw StateError('expected Right'));

void main() {
  const tax = DeductionRule(id: 'pajak', label: 'Pajak', kind: DeductionKind.percentage, value: 25);
  late FreelanceRepositoryImpl repository;

  setUp(() => repository = FreelanceRepositoryImpl(storage: InMemoryKeyValueStorage()));

  test('proyek beserta potongannya tersimpan dan terbaca utuh', () async {
    const project = FreelanceProject(id: 'p1', name: 'Studio', hourlyRate: 7250000, deductionRules: [tax]);
    await repository.saveProject(project);
    expect(_right(await repository.listProjects()), [project]);

    await repository.saveProject(project.copyWith(name: 'Studio Koding'));
    expect(_right(await repository.listProjects()).single.name, 'Studio Koding');

    await repository.deleteProject('p1');
    expect(_right(await repository.listProjects()), isEmpty);
  });

  test('saveEntries menimpa di posisi semula dan menambah yang baru di akhir', () async {
    final a = WorklogEntry(id: 'a', projectId: 'p1', date: DateTime(2026, 9, 4), hours: 4, hourlyRate: 100);
    final b = WorklogEntry(id: 'b', projectId: 'p1', date: DateTime(2026, 9, 2), hours: 2, hourlyRate: 100, note: 'x');
    await repository.saveEntries([a, b]);
    final c = WorklogEntry(id: 'c', projectId: 'p1', date: DateTime(2026, 9, 3), hours: 1, hourlyRate: 100);
    await repository.saveEntries([c, a.copyWith(paymentId: () => 'pay')]);

    final entries = _right(await repository.listEntries());
    expect(entries.map((e) => e.id), ['a', 'b', 'c']);
    expect(entries.first.paymentId, 'pay');
    expect(entries[1].note, 'x');

    await repository.deleteEntry('b');
    expect(_right(await repository.listEntries()).map((e) => e.id), ['a', 'c']);
  });

  test('pembayaran tertunda dan diterima tersimpan utuh, termasuk salinan potongan', () async {
    final pending = FreelancePayment(
      id: 'pay',
      projectId: 'p1',
      entryIds: const ['a', 'c'],
      expectedDate: DateTime(2026, 10, 5),
      deductionRules: const [tax],
    );
    await repository.savePayment(pending);
    expect(_right(await repository.listPayments()), [pending]);

    final paid = pending.markPaid(walletId: 'bca', date: DateTime(2026, 10, 7));
    await repository.savePayment(paid);
    expect(_right(await repository.listPayments()), [paid]);

    await repository.deletePayment('pay');
    expect(_right(await repository.listPayments()), isEmpty);
  });

  group('TransactionModel.freelancePaymentId (ADR-019)', () {
    test('pemasukan milik pembayaran tersimpan dan terbaca utuh', () {
      final income = IncomeTransaction(
        id: 'freelance-pay',
        date: DateTime(2026, 10, 7),
        amount: 261543750,
        note: '',
        walletId: 'bca',
        freelancePaymentId: 'pay',
      );
      final json = TransactionModel.fromEntity(income).toJson();
      expect(json['freelancePaymentId'], 'pay');
      expect(TransactionModel.fromJson(json).toEntity(), income);
    });

    test('pemasukan biasa tidak menulis kuncinya, dan dokumen lama terbaca sebagai pemasukan biasa', () {
      final income = IncomeTransaction(id: 'i', date: DateTime(2026, 10), amount: 1, note: '', walletId: 'bca');
      final json = TransactionModel.fromEntity(income).toJson();
      expect(json.containsKey('freelancePaymentId'), isFalse);
      final read = TransactionModel.fromJson(json).toEntity() as IncomeTransaction;
      expect(read.isFreelancePayment, isFalse);
    });
  });
}
