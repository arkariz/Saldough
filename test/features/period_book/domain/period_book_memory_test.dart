import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/period_book/domain/entities/period_book_memory.dart';

void main() {
  final t1 = DateTime(2026, 11, 14, 9);
  final t2 = DateTime(2026, 11, 20, 9);

  test('kosong: ajakan menyala, tidak ada buku dibuka', () {
    expect(PeriodBookMemory.empty.inviteEnabled, isTrue);
    expect(PeriodBookMemory.empty.isOpened('2026-10-25'), isFalse);
  });

  test('tanggal pembukaan pertama dipertahankan', () {
    final m = PeriodBookMemory.empty.withOpened('2026-10-25', t1).withOpened('2026-10-25', t2);
    expect(m.opened['2026-10-25'], t1);
  });

  test('langkah ritual terkumpul per periode', () {
    final m = PeriodBookMemory.empty.withStepDone('p', 0).withStepDone('p', 2).withStepDone('q', 1);
    expect(m.stepsOf('p'), {0, 2});
    expect(m.stepsOf('q'), {1});
    expect(m.stepsOf('x'), isEmpty);
  });
}
