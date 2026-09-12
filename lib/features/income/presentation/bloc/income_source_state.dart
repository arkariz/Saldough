import 'package:saldough/shared/income/income.dart';
import 'package:state_management/state_management.dart';

/// State [IncomeSourceBloc]. `effect` tidak pernah masuk [props] (ADR-0003).
final class IncomeSourceState extends UiState<IncomeSourceState> {
  /// Membuat [IncomeSourceState].
  const IncomeSourceState({
    required this.sources,
    required this.isLoading,
    this.openBookHours = const {},
    super.effect,
  });

  /// State awal sebelum daftar sumber dimuat.
  factory IncomeSourceState.initial() => const IncomeSourceState(sources: [], isLoading: true);

  /// Seluruh sumber pemasukan terdaftar (FR-INC-001).
  final List<IncomeSource> sources;

  /// Sedang memuat/menyimpan.
  final bool isLoading;

  /// Jumlah jam buku TERBUKA tiap sumber freelance, `sourceId` → jam.
  /// Sumber tanpa buku terbuka tidak muncul sebagai kunci (lihat
  /// `IncomeWorklogGateway`) — dipakai tile sumber freelance menampilkan
  /// ringkasan buku berjalannya sendiri (laporan pemilik: alur sumber
  /// freelance → catat jam terasa terputus, titik masuknya tersembunyi).
  final Map<String, int> openBookHours;

  @override
  IncomeSourceState copyWith({
    List<IncomeSource>? sources,
    bool? isLoading,
    Map<String, int>? openBookHours,
    UiEffect? effect,
  }) {
    return IncomeSourceState(
      sources: sources ?? this.sources,
      isLoading: isLoading ?? this.isLoading,
      openBookHours: openBookHours ?? this.openBookHours,
      effect: effect,
    );
  }

  @override
  List<Object?> get props => [sources, isLoading, openBookHours];
}
