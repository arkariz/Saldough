import 'package:saldough/features/period_book/domain/entities/period_book_memory.dart';
import 'package:saldough/features/period_book/domain/entities/ritual_info.dart';

/// Langkah tempat ritual dilanjutkan (BP-6: menutup di tengah menyimpan langkah
/// yang selesai). Langkah pertama yang belum selesai; bila ketiganya selesai,
/// langkah terakhir (ritual yang sudah dijalani lagi tidak mengulang dari awal).
RitualStep ritualResumeStep(PeriodBookMemory memory, String periodId) {
  final done = memory.stepsOf(periodId);
  for (final step in RitualStep.values) {
    if (!done.contains(step.index)) {
      return step;
    }
  }
  return RitualStep.review;
}

/// Langkah yang tidak punya apa-apa untuk dikerjakan tetap ditampilkan sebagai
/// keadaan rapi ("Semua transaksi sudah berkategori"), bukan dilewati diam-diam
/// (rupa D4), kecuali langkah kilas balik tanpa anggaran yang digantikan baris
/// info. Fungsi ini hanya menjawab apakah langkah punya pekerjaan terbuka.
bool ritualStepHasWork(RitualInfo info, RitualStep step) => switch (step) {
  RitualStep.uncategorized => info.untagged.isNotEmpty,
  RitualStep.routines => info.openRoutines > 0,
  RitualStep.review => false,
};
