// Satu method disengaja — ini port kecil untuk satu kebutuhan baca lintas
// fitur (lihat catatan revisi ADR-0009), bukan kelas yang sebaiknya jadi
// fungsi top-level.
// ignore_for_file: one_member_abstracts

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';

/// Ringkasan satu kartu kredit — hanya yang dibutuhkan layar siklus untuk
/// menautkan baris anggaran baru ke tagihan kartu tertentu (T-4.x lanjutan,
/// laporan pemilik: sebelumnya tidak ada cara menautkan baris anggaran ke
/// Rencana Belanja/kartu dari UI, hanya lewat seed).
final class CardSummary extends Equatable {
  /// Membuat [CardSummary].
  const CardSummary({required this.id, required this.name});

  /// Identitas kartu (`CreditCard.id`).
  final String id;

  /// Nama kartu, misalnya `"CC TOKPED"`.
  final String name;

  @override
  List<Object?> get props => [id, name];
}

/// Port milik fitur `cycle` — daftar kartu kredit yang ada, dibaca-saja.
/// Diimplementasikan oleh fitur `card` (lihat `CardCatalogImpl`) dan dikawat
/// di `RootModule` (ADR-0009: RootModule yang boleh melihat data lebih dari
/// satu fitur untuk mengawatnya), sama seperti `CycleIncomeWriter`/
/// `CycleInvestmentGateway` — arahnya saja yang beda (baca, bukan tulis).
abstract interface class CardCatalog {
  /// Daftar ringkasan seluruh kartu terdaftar.
  Future<Either<Failure, List<CardSummary>>> listCards();
}
