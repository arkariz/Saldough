import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/core/financial_month/financial_month.dart';

void main() {
  T read<T>(Either<Failure, T> result) => result.getOrElse((_) => throw StateError('expected Right'));

  group('financialMonthOf', () {
    test('mulai tanggal 1: bulan kalender, label nama bulan', () {
      final range = financialMonthOf(DateTime(2026, 10, 2, 9), 1);
      expect(range.start, DateTime(2026, 10));
      expect(range.end, DateTime(2026, 11));
      expect(range.days, 31);
      expect(range.label, 'Oktober 2026');
    });

    test('mulai tanggal 25: 3 Nov ada di 25 Okt – 24 Nov; 25 Nov sudah bulan berikutnya', () {
      final range = financialMonthOf(DateTime(2026, 11, 3), 25);
      expect(range.start, DateTime(2026, 10, 25));
      expect(range.end, DateTime(2026, 11, 25));
      expect(range.lastDay, DateTime(2026, 11, 24));
      expect(range.label, '25 Okt – 24 Nov');
      expect(financialMonthOf(DateTime(2026, 11, 25), 25).start, DateTime(2026, 11, 25));
      expect(range.contains(DateTime(2026, 11, 24, 23)), isTrue);
      expect(range.contains(DateTime(2026, 11, 25)), isFalse);
    });

    test('Februari dan pergantian tahun', () {
      final feb = financialMonthOf(DateTime(2027, 2, 27), 28);
      expect(feb.start, DateTime(2027, 1, 28));
      expect(feb.end, DateTime(2027, 2, 28));
      expect(feb.days, 31);
      expect(financialMonthOf(DateTime(2027, 1, 5), 25).start, DateTime(2026, 12, 25));
    });
  });

  test('preferensi: bawaan 1, tersimpan, nilai di luar 1–28 dibaca 1', () async {
    final storage = InMemoryKeyValueStorage();
    final repository = FinancialMonthPreferenceRepositoryImpl(storage: storage);
    expect(read(await repository.load()), 1);
    await repository.save(25);
    expect(read(await repository.load()), 25);
    await storage.write(
      const StorageKey(namespace: 'settings', name: 'financial_month_start').value,
      '{"schemaVersion":1,"startDay":31}',
    );
    expect(read(await repository.load()), 1);
  });
}
