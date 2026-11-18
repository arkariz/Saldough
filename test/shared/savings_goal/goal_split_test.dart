import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/shared/savings_goal/savings_goal.dart';

void main() {
  group('splitByPercent (ADR-048 §9.2)', () {
    test('membagi menurut persen, jumlahnya tepat total', () {
      final parts = splitByPercent(100000000, {'a': 50, 'b': 30, 'c': 20});
      expect(parts, {'a': 50000000, 'b': 30000000, 'c': 20000000});
    });

    test('sisa sen pembulatan ke persen terbesar', () {
      final parts = splitByPercent(10001, {'a': 30, 'b': 50, 'c': 20});
      expect(parts, {'a': 3000, 'b': 5001, 'c': 2000});
      expect(parts.values.reduce((x, y) => x + y), 10001);
    });

    test('persen sama: sisa ke yang pertama', () {
      final parts = splitByPercent(100, {'a': 33, 'b': 33, 'c': 34});
      expect(parts.values.reduce((x, y) => x + y), 100);
      expect(splitByPercent(101, {'a': 50, 'b': 50}), {'a': 51, 'b': 50});
    });

    test('persen belum 100: tiap bagian apa adanya, tanpa sisa', () {
      expect(splitByPercent(100000000, {'a': 50, 'b': 33, 'c': 33}), {'a': 50000000, 'b': 33000000, 'c': 33000000});
    });

    test('tujuan ber-0% tidak ikut', () {
      expect(splitByPercent(1000, {'a': 100, 'b': 0}), {'a': 1000});
    });
  });

  group('isValidSplit', () {
    test('sah bila jumlah 100, minimal dua tujuan, tiap bagian > 0', () {
      expect(isValidSplit(1000, {'a': 60, 'b': 40}), isTrue);
      expect(isValidSplit(1000, {'a': 60, 'b': 30}), isFalse);
      expect(isValidSplit(1000, {'a': 100, 'b': 0}), isFalse);
      expect(isValidSplit(1, {'a': 50, 'b': 50}), isFalse);
      expect(isValidSplit(0, {'a': 50, 'b': 50}), isFalse);
    });
  });

  group('initialSplitPercents (ADR-048 §9.3)', () {
    test('tanpa simpanan: dibagi rata, sisa ke yang pertama', () {
      expect(initialSplitPercents(['a', 'b', 'c'], const {}), {'a': 34, 'b': 33, 'c': 33});
    });

    test('dengan simpanan: persen terakhir, tujuan baru mulai 0', () {
      expect(initialSplitPercents(['a', 'b', 'c'], {'a': 70, 'b': 30, 'x': 10}), {'a': 70, 'b': 30, 'c': 0});
    });
  });
}
