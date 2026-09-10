import 'package:saldough/features/cycle/domain/entities/budget_line.dart';
import 'package:saldough/features/cycle/domain/entities/cycle_totals.dart';
import 'package:saldough/features/cycle/domain/entities/income_line.dart';
import 'package:saldough/features/cycle/domain/entities/monthly_cycle.dart';
import 'package:saldough/features/cycle/domain/usecases/calculate_cycle_totals.dart';
import 'package:saldough/shared/income/income.dart';
import 'package:state_management/state_management.dart';

/// State [CycleBloc]. `effect` tidak pernah masuk [props] (ADR-0003).
///
/// [totals] dan [unreviewedCount] bukan field tersimpan — keduanya getter
/// yang dihitung ulang dari [cycle] tiap diakses, supaya tidak ada risiko
/// lupa memperbaruinya setelah baris berubah (kelas ini, bukan [CycleBloc],
/// yang memegang logika itu — lihat juga [withCycle]).
final class CycleState extends UiState<CycleState> {
  /// Membuat [CycleState].
  const CycleState({
    required this.cycle,
    required this.isLoading,
    this.incomeSources = const [],
    super.effect,
  });

  /// State awal sebelum siklus mana pun dimuat.
  factory CycleState.initial() => CycleState(cycle: .empty(''), isLoading: true);

  /// Siklus yang sedang ditampilkan.
  final MonthlyCycle cycle;

  /// Sedang memuat/menyimpan.
  final bool isLoading;

  /// Seluruh `IncomeSource` terdaftar — dipakai layar penyuntingan baris
  /// pemasukan untuk menautkan baris ke sumber dan mengisi nominal otomatis
  /// (T-3.4/FR-INC-002). Dimuat sekali saat siklus dibuka.
  final List<IncomeSource> incomeSources;

  /// Total dan sisa, dihitung dari [cycle] lewat `CalculateCycleTotals`.
  CycleTotals get totals => CalculateCycleTotals()(cycle);

  /// Jumlah baris ber-`needsReview: true` — ditampilkan di ringkasan siklus
  /// (ADR-0008), supaya bulan tidak dianggap selesai selama masih menggantung.
  int get unreviewedCount =>
      cycle.incomeLines.where((l) => l.needsReview).length +
      cycle.budgetLines.where((l) => l.needsReview).length;

  /// Baris pemasukan ber-`id` [id] di [cycle], atau `null` kalau tidak ada.
  IncomeLine? findIncomeLine(String id) => cycle.incomeLines.where((l) => l.id == id).firstOrNull;

  /// Baris anggaran ber-`id` [id] di [cycle], atau `null` kalau tidak ada.
  BudgetLine? findBudgetLine(String id) => cycle.budgetLines.where((l) => l.id == id).firstOrNull;

  @override
  CycleState copyWith({
    MonthlyCycle? cycle,
    bool? isLoading,
    List<IncomeSource>? incomeSources,
    UiEffect? effect,
  }) {
    return CycleState(
      cycle: cycle ?? this.cycle,
      isLoading: isLoading ?? this.isLoading,
      incomeSources: incomeSources ?? this.incomeSources,
      effect: effect,
    );
  }

  /// Helper transisi state — berpindah ke [cycle] baru. Dipakai [CycleBloc]
  /// tiap kali berhasil memuat, menyimpan, rollover, atau membuka kembali
  /// siklus; `isLoading` bawaan `false` karena selalu dipanggil setelah
  /// operasi selesai.
  CycleState withCycle(MonthlyCycle cycle, {bool isLoading = false, UiEffect? effect}) =>
      copyWith(cycle: cycle, isLoading: isLoading, effect: effect);

  @override
  List<Object?> get props => [cycle, isLoading, incomeSources];
}
