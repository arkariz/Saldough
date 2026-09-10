// Satu method disengaja — ini port Strategy yang akan punya lebih dari satu
// implementasi bertukar di DI (UnavailableRollUpResolver sekarang, resolver
// belanja/kartu sungguhan di Fase 4), bukan kelas yang sebaiknya jadi fungsi
// top-level.
// ignore_for_file: one_member_abstracts

import 'package:saldough/features/cycle/domain/entities/roll_up_resolution.dart';
import 'package:saldough/features/cycle/domain/entities/roll_up_source.dart';

/// Menghitung ulang nominal sebuah `BudgetLine` ber-`kind` `rollUp` dari
/// sumbernya. Dipanggil `CycleRepositoryImpl` setiap kali siklus dibaca
/// (ADR-0008) — tidak pernah ada nilai roll-up yang dipercaya dari dokumen
/// tersimpan.
///
/// Baris `card` sudah punya implementasi nyata (`CardRollUpResolver`,
/// T-4.6-T-4.12) yang dikawat `RootModule` — lihat catatan di
/// `_registerCrossFeatureAdapters`. Baris `grocery` dibangun di cabang
/// terpisah dan belum tergabung di sini; sampai itu `CardRollUpResolver`
/// mengembalikan `RollUpResolution.unavailable()` untuk sumber non-kartu.
/// `UnavailableRollUpResolver` di `features/cycle/data/roll_up/` tetap ada
/// sebagai fallback test/placeholder. Penempatan antarmuka ini di
/// `features/cycle/` adalah keputusan sementara; pindahkan kalau nanti
/// ditemukan tempat yang lebih tepat (misalnya `shared/`).
abstract interface class RollUpResolver {
  /// Menghitung nominal untuk [source].
  Future<RollUpResolution> resolve(RollUpSource source);
}
