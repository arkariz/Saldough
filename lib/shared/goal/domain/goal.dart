import 'package:dependencies/dependencies.dart';

/// Pos tujuan tabungan/investasi (misalnya `ANAK`, `RUMAH`, `PENSIUN`).
///
/// Daftar pos bersifat terbuka — nama disimpan sebagai data, bukan enum,
/// supaya pemilik bisa menambah pos baru kapan saja (FR-INV-001). Lihat
/// DOMAIN_MODEL.md bagian "Pos tujuan dan pinjaman".
///
/// `balance` (saldo berjalan) sengaja TIDAK jadi field di sini — itu nilai
/// turunan, dihitung dari `openingBalance` ditambah riwayat alokasi dan
/// pinjaman di seluruh siklus, bukan nilai yang disimpan. Use case
/// penghitungannya dibuat di Fase 5 (investasi).
final class Goal extends Equatable {
  /// Membuat [Goal].
  const Goal({
    required this.id,
    required this.name,
    required this.openingBalance,
  });

  /// Identitas pos, unik.
  final String id;

  /// Nama pos, misalnya `"ANAK"`. Data pengguna, bukan teks antarmuka —
  /// tidak pernah lewat slang.
  final String name;

  /// Saldo awal dalam sen. Nilai seed terkonfirmasi: 0 untuk seluruh pos
  /// (lihat `.claude/AGENT_CONTEXT.md` bagian nilai seed).
  final int openingBalance;

  @override
  List<Object?> get props => [id, name, openingBalance];
}
