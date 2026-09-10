// Satu method disengaja — ini port Strategy dengan lebih dari satu
// implementasi bertukar di DI (GroceryRollUpResolver untuk baris grocery
// sejak Fase 4, UnavailableRollUpResolver untuk baris yang belum punya
// sumber nyata), bukan kelas yang sebaiknya jadi fungsi top-level.
// ignore_for_file: one_member_abstracts

import 'package:saldough/features/cycle/domain/entities/roll_up_resolution.dart';
import 'package:saldough/features/cycle/domain/entities/roll_up_source.dart';

/// Menghitung ulang nominal sebuah `BudgetLine` ber-`kind` `rollUp` dari
/// sumbernya. Dipanggil `CycleRepositoryImpl` setiap kali siklus dibaca
/// (ADR-0008) — tidak pernah ada nilai roll-up yang dipercaya dari dokumen
/// tersimpan.
///
/// Sejak Fase 4 (bagian belanja), `RootModule` mengawat
/// `GroceryRollUpResolver` (`features/grocery/data/`) sebagai implementasi
/// sungguhan — lihat ROADMAP.md Fase 2 dan catatan di root_module.dart.
/// Baris `card` masih `RollUpResolution.unavailable()` sampai bagian kartu
/// kredit Fase 4 dibangun. Penempatan antarmuka ini di `features/cycle/`
/// adalah keputusan sementara; pindahkan kalau kebutuhan lain menemukan
/// tempat yang lebih tepat (misalnya `shared/`).
abstract interface class RollUpResolver {
  /// Menghitung nominal untuk [source].
  Future<RollUpResolution> resolve(RollUpSource source);
}
