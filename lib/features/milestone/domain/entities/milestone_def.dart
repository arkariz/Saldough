import 'package:dependencies/dependencies.dart';

/// Fakta yang dibaca mesin (ADR-046 §3.3). Penyedia fakta di `lib/app/`
/// menghitungnya dari data aplikasi; mesin hanya tahu mana yang benar.
enum MilestoneFact {
  /// Sedikitnya satu dompet aktif tersimpan.
  walletExists,

  /// Sedikitnya satu transaksi tersimpan lewat Catat.
  recordExists,

  /// Satu periode tertutup dengan ≥3 transaksi dan tanpa transaksi tanpa
  /// kategori (transfer dan pemasukan freelance tanpa kategori tidak dihitung).
  tidyPeriodClosed,

  /// Satu periode tertutup dengan ≥1 kemunculan rutin dan tanpa yang Menunggu.
  recurringClearClosed,

  /// Kotak masuk turun dari ≥1 menunggu ke nol lewat keputusan pengguna.
  inboxCleared,

  /// Satu cadangan `.tkbak` berhasil dibuat dan disimpan atau dibagikan.
  backupDone,

  /// Satu pos anggaran punya ≥1 transaksi tertaut.
  budgetItemLinked,

  /// Satu pembayaran freelance dicatat diterima.
  freelancePaid,
}

/// Jenis syarat (GAMIFICATION §9); metadata katalog, semuanya dikurangi ke
/// satu [MilestoneFact].
enum MilestoneKind {
  /// Suatu fakta menjadi benar untuk pertama kali.
  firstTime,

  /// Ada satu periode keuangan tertutup yang memenuhi syarat isinya.
  closedPeriod,

  /// Suatu antrean turun dari ada ke kosong lewat tindakan pengguna.
  queueCleared,
}

/// Kelompok di Buku Stempel.
enum MilestoneGroup {
  /// Mulai.
  start,

  /// Rapi.
  tidy,

  /// Aman.
  safe,

  /// Rencana.
  plan,
}

/// Satu baris katalog tonggak.
final class MilestoneDef extends Equatable {
  /// Membuat [MilestoneDef].
  const MilestoneDef({
    required this.id,
    required this.group,
    required this.kind,
    required this.fact,
    this.revealOnUse = false,
  });

  /// Id tetap (kosakata GAMIFICATION §5); dipakai di penyimpanan dan analitik.
  final String id;

  /// Kelompok di Buku Stempel.
  final MilestoneGroup group;

  /// Jenis syarat.
  final MilestoneKind kind;

  /// Fakta yang harus benar.
  final MilestoneFact fact;

  /// Tampil di Buku Stempel hanya sesudah fiturnya dipakai sekali (KT-G3).
  final bool revealOnUse;

  @override
  List<Object?> get props => [id, group, kind, fact, revealOnUse];
}
