// Satu method disengaja — ini port kecil untuk satu kebutuhan baca lintas
// fitur (lihat catatan revisi ADR-0009), bukan kelas yang sebaiknya jadi
// fungsi top-level.
// ignore_for_file: one_member_abstracts

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';

/// Satu pos anggaran yang bisa ditautkan ke transaksi dari formulir CATAT.
/// Bentuk transport milik `record` sendiri, bukan entitas `Budget` — fitur
/// ini tidak mengimpor domain `budget` (ADR-0009, pola port kecil).
final class BudgetItemOption extends Equatable {
  /// Membuat [BudgetItemOption].
  const BudgetItemOption({
    required this.budgetId,
    required this.budgetName,
    required this.itemId,
    required this.itemName,
    required this.walletId,
    required this.startDate,
    required this.endDate,
    this.isArchived = false,
    this.transferToWalletId,
  });

  /// Anggaran pemilik pos.
  final String budgetId;

  /// Nama anggaran, untuk label pilihan.
  final String budgetName;

  /// `BudgetItem.id` — nilai yang disimpan di `budgetItemId` transaksi.
  final String itemId;

  /// Nama pos.
  final String itemName;

  /// Dompet anggaran. Pengeluaran hanya boleh memilih pos yang `walletId`-nya
  /// sama dengan dompet asal; transfer, dengan `fromWalletId`-nya.
  final String walletId;

  /// Dompet tujuan kalau pos ini rencana transfer; `null` = pos pengeluaran
  /// (ADR-018). Pos transfer hanya ditawarkan ke transfer DARI [walletId] KE
  /// dompet ini; pos pengeluaran hanya ke pengeluaran dari [walletId].
  final String? transferToWalletId;

  /// Apakah pos ini rencana transfer.
  bool get isTransfer => transferToWalletId != null;

  /// Awal periode anggaran; hanya tanggalnya yang dipakai.
  final DateTime startDate;

  /// Akhir periode anggaran, eksklusif.
  final DateTime endDate;

  /// Anggarannya diarsipkan — tidak ditawarkan lagi, kecuali sudah dipakai
  /// transaksi yang sedang disunting.
  final bool isArchived;

  /// Apakah transaksi bertanggal [date] boleh ditautkan ke pos ini:
  /// `startDate ≤ date < endDate` (keputusan KT-1). Pos yang periodenya tidak
  /// mencakup tanggal transaksi tidak pernah terhitung, jadi tidak ditawarkan.
  bool covers(DateTime date) =>
      !date.isBefore(DateTime(startDate.year, startDate.month, startDate.day)) && date.isBefore(endDate);

  @override
  List<Object?> get props => [
    budgetId,
    budgetName,
    itemId,
    itemName,
    walletId,
    startDate,
    endDate,
    isArchived,
    transferToWalletId,
  ];
}

/// Port milik `record`: daftar pos anggaran untuk pemilih di formulir
/// pengeluaran dan transfer (T-4.4, FR-BUD-003). Diimplementasikan fitur
/// `budget` dan dikawat di `RootModule`.
abstract interface class BudgetItemCatalog {
  /// Seluruh pos dari seluruh anggaran, termasuk yang tidak aktif.
  Future<Either<Failure, List<BudgetItemOption>>> listOptions();
}
