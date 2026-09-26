// Satu method disengaja — port kecil untuk satu kebutuhan baca lintas fitur
// (ADR-0009), sama seperti `BudgetItemCatalog` milik `record`.
// ignore_for_file: one_member_abstracts

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';

/// Ringkasan seluruh anggaran aktif untuk Beranda (FR-HOME-002). Bentuk
/// transport milik `home` sendiri — fitur ini tidak mengimpor domain
/// `budget`. Seluruh nominal dalam sen.
final class BudgetOverview extends Equatable {
  /// Membuat [BudgetOverview].
  const BudgetOverview({required this.activeCount, required this.plannedAmount, required this.spent});

  /// Jumlah anggaran aktif (belum diarsipkan dan periodenya belum lewat).
  final int activeCount;

  /// Total rencana anggaran aktif.
  final int plannedAmount;

  /// Total terpakai anggaran aktif.
  final int spent;

  /// Total sisa; negatif kalau pemakaian melewati rencana.
  int get remaining => plannedAmount - spent;

  @override
  List<Object?> get props => [activeCount, plannedAmount, spent];
}

/// Port milik `home`: ringkasan anggaran aktif. Diimplementasikan fitur
/// `budget` dan dikawat di `RootModule`.
abstract interface class BudgetOverviewSource {
  /// Ringkasan anggaran yang aktif saat ini.
  Future<Either<Failure, BudgetOverview>> activeBudgetOverview();
}
