import 'dart:typed_data';

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/data_portability/domain/restore_models.dart';

/// Memulihkan data dari cadangan (FR-DAT-003, EXPORT_BACKUP §7). Implementasinya
/// di lapisan data (`RestoreService`).
///
/// Alurnya dua tahap: [inspect] memeriksa berkas tanpa menulis apa pun, lalu
/// [stage] menyiapkan penggantian atomik. Penerapan data sebenarnya terjadi
/// saat bootstrap berikutnya (ADR-040 §3.4), dipicu pemanggil lewat boot ulang.
abstract interface class RestoreGateway {
  /// Memeriksa [bytes] (R-1–R-3) dan menyusun pratinjau terhadap data sekarang.
  /// Gagal dengan kode `invalid`, `newer`, atau `inconsistent`; data tidak
  /// tersentuh.
  Future<Either<Failure, RestoreSession>> inspect(Uint8List bytes, {RestoreKind source = RestoreKind.account});

  /// Pratinjau untuk "Kembalikan data sebelum pemulihan", atau `null` bila tidak
  /// ada cadangan pengaman yang berlaku.
  Future<Either<Failure, RestoreSession?>> inspectSafetyCopy();

  /// Cadangan pengaman yang masih berlaku, atau `null`.
  Future<Either<Failure, SafetyCopyInfo?>> safetyCopy();

  /// Menyiapkan penggantian data dengan isi [session] dan menetapkan jurnal
  /// `applying`. Tidak menyentuh data hidup. Gagal dengan kode `space` bila
  /// penyimpanan penuh.
  Future<Either<Failure, Unit>> stage(RestoreSession session);
}
