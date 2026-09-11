// Satu method disengaja — ini port Strategy dengan lebih dari satu
// implementasi bertukar di DI (GroceryRollUpResolver untuk baris grocery,
// CardRollUpResolver untuk baris card, keduanya sejak Fase 4, digabung jadi
// satu lewat CompositeRollUpResolver di RootModule), bukan kelas yang
// sebaiknya jadi fungsi top-level.
// ignore_for_file: one_member_abstracts

import 'package:saldough/features/cycle/domain/entities/roll_up_resolution.dart';
import 'package:saldough/features/cycle/domain/entities/roll_up_source.dart';

/// Menghitung ulang nominal sebuah `BudgetLine` ber-`kind` `rollUp` dari
/// sumbernya. Dipanggil `CycleRepositoryImpl` setiap kali siklus dibaca
/// (ADR-0008) — tidak pernah ada nilai roll-up yang dipercaya dari dokumen
/// tersimpan.
///
/// Baris `grocery` (`GroceryRollUpResolver`, Fase 4 bagian belanja) dan
/// `card` (`CardRollUpResolver`, T-4.6-T-4.12) sudah punya implementasi
/// nyata, masing-masing hanya menangani satu jenis sumbernya sendiri dan
/// mengembalikan `RollUpResolution.unavailable()` untuk sumber lain.
/// `RootModule` mengawat keduanya di belakang satu `CompositeRollUpResolver`
/// yang mendelegasikan ke resolver yang cocok berdasar tipe `RollUpSource`
/// — lihat catatan di `_registerCrossFeatureAdapters`.
/// `UnavailableRollUpResolver` di `features/cycle/data/roll_up/` tetap ada
/// sebagai fallback test/placeholder. Penempatan antarmuka ini di
/// `features/cycle/` adalah keputusan sementara; pindahkan kalau nanti
/// ditemukan tempat yang lebih tepat (misalnya `shared/`).
abstract interface class RollUpResolver {
  /// Menghitung nominal untuk [source].
  Future<RollUpResolution> resolve(RollUpSource source);
}
