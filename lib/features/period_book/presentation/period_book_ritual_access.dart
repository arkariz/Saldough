import 'package:flutter/widgets.dart';
import 'package:saldough/features/period_book/domain/entities/ritual_info.dart';

/// Hasil memuat ritual Tutup buku untuk satu periode.
sealed class RitualLoad {
  const RitualLoad();
}

/// Siap: [info] dan langkah tempat melanjutkan ([resume], BP-6).
final class RitualReady extends RitualLoad {
  /// Membuat [RitualReady].
  const RitualReady({required this.info, required this.resume});

  /// Bahan ketiga langkah.
  final RitualInfo info;

  /// Langkah tempat ritual dilanjutkan.
  final RitualStep resume;
}

/// Buku ini terkunci untuk paket sekarang (BP-10); ritual tidak dibuka.
final class RitualLocked extends RitualLoad {
  /// Membuat [RitualLocked].
  const RitualLocked();
}

/// Gagal membaca data (periode tidak ditemukan atau galat baca).
final class RitualFailed extends RitualLoad {
  /// Membuat [RitualFailed].
  const RitualFailed();
}

/// Pintu layar ritual ke data dan tindakan di luar fitur (ADR-045, ADR-030):
/// gerbang Plus, ingatan langkah, penyunting transaksi, dan pindah tab. Akar
/// komposisi yang mengimplementasikannya.
abstract interface class PeriodBookRitualAccess {
  /// Memuat ritual [periodId]; mengecek gerbang di sini, bukan hanya di UI (BP-10).
  Future<RitualLoad> load(String periodId);

  /// Menandai langkah [step] selesai untuk [periodId] (BP-6).
  Future<void> markStepDone(String periodId, RitualStep step);

  /// Menutup buku: menandai buku dibuka. Tidak mengubah data keuangan (BP-5).
  Future<void> finish(String periodId);

  /// Membuka penyunting transaksi [transactionId] untuk memberi kategori.
  Future<void> categorize(BuildContext context, String transactionId);

  /// Membuka tab Rencana pada segmen Rutin (menutup ritual lebih dulu).
  void showRecurring(BuildContext context);
}
