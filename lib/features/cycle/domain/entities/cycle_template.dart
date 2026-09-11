import 'package:dependencies/dependencies.dart';
import 'package:saldough/features/cycle/domain/entities/allocation.dart';
import 'package:saldough/features/cycle/domain/entities/budget_line.dart';
import 'package:saldough/features/cycle/domain/entities/income_line.dart';

/// Kerangka siklus berikutnya — satu dokumen tunggal (bukan per bulan),
/// dikelola terpisah dari siklus yang sedang berjalan (FR-TPL-004).
///
/// Setiap baris di sini berarti "ikut terbawa saat rollover" — `isTemplate`
/// pada baris template selalu `true`. Menandai sebuah baris di siklus
/// berjalan sebagai "tetap" (FR-CYCLE-002) mendaftarkannya ke sini; melepas
/// tandanya menghapusnya dari sini. Lihat `CycleRepositoryImpl` dan
/// `ToggleIncomeLineTemplate`/`ToggleBudgetLineTemplate`.
final class CycleTemplate extends Equatable {
  /// Membuat [CycleTemplate].
  const CycleTemplate({
    required this.incomeLines,
    required this.budgetLines,
    required this.defaultAllocations,
  });

  /// Template kosong.
  factory CycleTemplate.empty() => const CycleTemplate(
    incomeLines: [],
    budgetLines: [],
    defaultAllocations: [],
  );

  /// Baris pemasukan tetap.
  final List<IncomeLine> incomeLines;

  /// Baris anggaran tetap.
  final List<BudgetLine> budgetLines;

  /// Persentase alokasi investasi bawaan, disalin apa adanya saat rollover.
  final List<Allocation> defaultAllocations;

  /// Salinan [CycleTemplate] dengan field yang disebutkan diganti.
  CycleTemplate copyWith({
    List<IncomeLine>? incomeLines,
    List<BudgetLine>? budgetLines,
    List<Allocation>? defaultAllocations,
  }) {
    return CycleTemplate(
      incomeLines: incomeLines ?? this.incomeLines,
      budgetLines: budgetLines ?? this.budgetLines,
      defaultAllocations: defaultAllocations ?? this.defaultAllocations,
    );
  }

  @override
  List<Object?> get props => [incomeLines, budgetLines, defaultAllocations];
}
