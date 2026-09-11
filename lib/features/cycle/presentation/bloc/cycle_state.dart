import 'package:saldough/features/cycle/domain/entities/budget_line.dart';
import 'package:saldough/features/cycle/domain/entities/cycle_totals.dart';
import 'package:saldough/features/cycle/domain/entities/income_line.dart';
import 'package:saldough/features/cycle/domain/entities/monthly_cycle.dart';
import 'package:saldough/features/cycle/domain/repositories/card_catalog.dart';
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
    this.existingCycleIds = const [],
    this.cards = const [],
    super.effect,
  });

  /// State awal sebelum siklus mana pun dimuat.
  factory CycleState.initial() =>
      CycleState(cycle: .empty(''), isLoading: true);

  /// Siklus yang sedang ditampilkan.
  final MonthlyCycle cycle;

  /// Sedang memuat/menyimpan.
  final bool isLoading;

  /// Seluruh `IncomeSource` terdaftar — dipakai layar penyuntingan baris
  /// pemasukan untuk menautkan baris ke sumber dan mengisi nominal otomatis
  /// (T-3.4/FR-INC-002). Dimuat sekali saat siklus dibuka.
  final List<IncomeSource> incomeSources;

  /// Seluruh `id` siklus yang benar-benar sudah dibuat (`CycleRepository`),
  /// terurut menaik. Dipakai app bar untuk membatasi navigasi bulan —
  /// siklus baru hanya boleh muncul lewat [CycleBloc.add] dengan
  /// `CycleRollOverRequested`, bukan dengan sekadar menggeser bulan
  /// (sebelumnya bisa, ini perbaikan atas laporan pemilik).
  final List<String> existingCycleIds;

  /// Seluruh kartu kredit terdaftar (ringkasan id+nama) — dipakai layar
  /// penyuntingan baris anggaran untuk menautkan baris baru ke tagihan
  /// kartu tertentu sebagai sumber roll-up (laporan pemilik: sebelumnya
  /// hanya bisa lewat seed, tidak ada cara dari UI). Dimuat sekali saat
  /// siklus dibuka, lewat `CardCatalog` (port milik fitur ini, ADR-0009).
  final List<CardSummary> cards;

  /// True kalau siklus ber-`id` [id] sudah benar-benar ada.
  bool hasCycle(String id) => existingCycleIds.contains(id);

  /// True kalau siklus yang sedang ditampilkan boleh dihapus: harus siklus
  /// TERAKHIR (paling baru, [existingCycleIds] terurut menaik — lihat
  /// `CycleRepository.listCycleIds`) dan belum ditutup. Dibatasi ke siklus
  /// terakhir saja supaya urutan rollover tidak berlubang di tengah (siklus
  /// Maret terhapus tapi April masih ada, misalnya) — kalau mau menghapus
  /// siklus yang lebih lama, hapus dulu semua yang lebih baru satu per satu.
  bool get canDeleteCycle =>
      !cycle.isClosed &&
      existingCycleIds.isNotEmpty &&
      existingCycleIds.last == cycle.id;

  /// Total dan sisa, dihitung dari [cycle] lewat `CalculateCycleTotals`.
  CycleTotals get totals => CalculateCycleTotals()(cycle);

  /// Jumlah baris ber-`needsReview: true` — ditampilkan di ringkasan siklus
  /// (ADR-0008), supaya bulan tidak dianggap selesai selama masih menggantung.
  int get unreviewedCount =>
      cycle.incomeLines.where((l) => l.needsReview).length +
      cycle.budgetLines.where((l) => l.needsReview).length;

  /// Baris pemasukan ber-`id` [id] di [cycle], atau `null` kalau tidak ada.
  IncomeLine? findIncomeLine(String id) =>
      cycle.incomeLines.where((l) => l.id == id).firstOrNull;

  /// Baris anggaran ber-`id` [id] di [cycle], atau `null` kalau tidak ada.
  BudgetLine? findBudgetLine(String id) =>
      cycle.budgetLines.where((l) => l.id == id).firstOrNull;

  @override
  CycleState copyWith({
    MonthlyCycle? cycle,
    bool? isLoading,
    List<IncomeSource>? incomeSources,
    List<String>? existingCycleIds,
    List<CardSummary>? cards,
    UiEffect? effect,
  }) {
    return CycleState(
      cycle: cycle ?? this.cycle,
      isLoading: isLoading ?? this.isLoading,
      incomeSources: incomeSources ?? this.incomeSources,
      existingCycleIds: existingCycleIds ?? this.existingCycleIds,
      cards: cards ?? this.cards,
      effect: effect,
    );
  }

  /// Helper transisi state — berpindah ke [cycle] baru. Dipakai [CycleBloc]
  /// tiap kali berhasil memuat, menyimpan, rollover, atau membuka kembali
  /// siklus; `isLoading` bawaan `false` karena selalu dipanggil setelah
  /// operasi selesai.
  CycleState withCycle(
    MonthlyCycle cycle, {
    bool isLoading = false,
    List<String>? existingCycleIds,
    List<CardSummary>? cards,
    UiEffect? effect,
  }) => copyWith(
    cycle: cycle,
    isLoading: isLoading,
    existingCycleIds: existingCycleIds,
    cards: cards,
    effect: effect,
  );

  @override
  List<Object?> get props => [
    cycle,
    isLoading,
    incomeSources,
    existingCycleIds,
    cards,
  ];
}
