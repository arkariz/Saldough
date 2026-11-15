import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/period_book/domain/entities/period_book_memory.dart';
import 'package:saldough/features/period_book/domain/entities/ritual_info.dart';
import 'package:saldough/features/period_book/domain/services/ritual_progress.dart';

void main() {
  test('lanjut dari langkah pertama yang belum selesai (BP-6)', () {
    expect(ritualResumeStep(PeriodBookMemory.empty, 'p'), RitualStep.uncategorized);
    expect(ritualResumeStep(PeriodBookMemory.empty.withStepDone('p', 0), 'p'), RitualStep.routines);
    expect(ritualResumeStep(PeriodBookMemory.empty.withStepDone('p', 0).withStepDone('p', 1), 'p'), RitualStep.review);
  });

  test('langkah dilewati (tidak ditandai) tetap ditawarkan lagi; ketiganya selesai: langkah terakhir', () {
    final skippedFirst = PeriodBookMemory.empty.withStepDone('p', 1);
    expect(ritualResumeStep(skippedFirst, 'p'), RitualStep.uncategorized);
    final all = PeriodBookMemory.empty.withStepDone('p', 0).withStepDone('p', 1).withStepDone('p', 2);
    expect(ritualResumeStep(all, 'p'), RitualStep.review);
  });

  test('periode lain tidak memengaruhi', () {
    expect(ritualResumeStep(PeriodBookMemory.empty.withStepDone('q', 0), 'p'), RitualStep.uncategorized);
  });
}
