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
/// ⚠ Belum ada implementasi nyata sampai Fase 4 (rencana belanja dan kartu
/// kredit belum dibangun). Sampai itu, `UnavailableRollUpResolver` di
/// `features/cycle/data/roll_up/` didaftarkan di DI dan selalu
/// mengembalikan `RollUpResolution.unavailable()` — lihat ROADMAP.md
/// Fase 2. Penempatan antarmuka ini di `features/cycle/` adalah keputusan
/// sementara; pindahkan kalau Fase 4 menemukan tempat yang lebih tepat
/// (misalnya `shared/`).
abstract interface class RollUpResolver {
  /// Menghitung nominal untuk [source].
  Future<RollUpResolution> resolve(RollUpSource source);
}
