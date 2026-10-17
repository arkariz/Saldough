import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/features/analysis/domain/period_summary.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

/// Keadaan layar Analisis untuk satu periode (FR-ANL-001).
final class AnalysisState extends UiState<AnalysisState> {
  /// Membuat [AnalysisState].
  const AnalysisState({
    required this.period,
    required this.summary,
    required this.isCurrent,
    required this.canGoBack,
    required this.hasAnyTransactions,
    required this.isLoading,
    this.loadFailed = false,
    this.selectedKey,
    this.othersOpen = false,
    this.kind = CategoryKind.expense,
    this.walletId,
    this.wallets = const [],
    super.effect,
  });

  /// Keadaan awal untuk [period], sebelum apa pun dimuat.
  factory AnalysisState.initial(FinancialPeriod period) => AnalysisState(
    period: period,
    summary: null,
    isCurrent: true,
    canGoBack: false,
    hasAnyTransactions: false,
    isLoading: true,
  );

  /// Periode yang sedang dilihat (ADR-038).
  final FinancialPeriod period;

  /// Ringkasan pengeluaran [period]; `null` sebelum termuat atau bila belum
  /// ada transaksi sama sekali.
  final PeriodSummary? summary;

  /// [period] adalah periode berjalan: panah maju nonaktif, Analisis tidak
  /// membuat perkiraan.
  final bool isCurrent;

  /// Ada periode yang lebih lama untuk dilihat (sampai periode yang memuat
  /// bulan pertama pencatatan).
  final bool canGoBack;

  /// Sudah ada transaksi tercatat satu pun (keadaan kosong bila belum).
  final bool hasAnyTransactions;

  /// Sedang memuat untuk pertama kali.
  final bool isLoading;

  /// Pemuatan pertama gagal.
  final bool loadFailed;

  /// Kunci baris yang dipilih di donat atau legenda ([AnalysisGroup.key]), atau
  /// `null`. Tidak disimpan: pindah periode mengosongkannya.
  final String? selectedKey;

  /// Anggota Lainnya sedang dibuka.
  final bool othersOpen;

  /// Jenis yang dianalisis. Diingat selama layar hidup; pintu Beranda selalu
  /// membuka layar baru, jadi selalu mulai di pengeluaran.
  final CategoryKind kind;

  /// Dompet yang disaring, atau `null` = semua dompet.
  final String? walletId;

  /// Dompet yang bisa dipilih penyaring (aktif maupun tidak: transaksinya
  /// tetap dihitung, B-5).
  final List<Wallet> wallets;

  /// Baris yang dipilih, atau `null`.
  AnalysisGroup? get selected => selectedKey == null ? null : summary?.groupOf(selectedKey!);

  /// Salinan dengan pilihan [key] dan keadaan [othersOpen] (`key` `null` = tanpa pilihan).
  AnalysisState withSelection(String? key, {required bool othersOpen}) => AnalysisState(
    period: period,
    summary: summary,
    isCurrent: isCurrent,
    canGoBack: canGoBack,
    hasAnyTransactions: hasAnyTransactions,
    isLoading: isLoading,
    loadFailed: loadFailed,
    selectedKey: key,
    othersOpen: othersOpen,
    kind: kind,
    walletId: walletId,
    wallets: wallets,
  );

  /// Salinan dengan jenis [kind] dan dompet [walletId] baru (`null` = semua);
  /// pilihan baris dikosongkan karena barisnya berganti.
  AnalysisState withControls({required CategoryKind kind, required String? walletId, PeriodSummary? summary}) =>
      AnalysisState(
        period: period,
        summary: summary ?? this.summary,
        isCurrent: isCurrent,
        canGoBack: canGoBack,
        hasAnyTransactions: hasAnyTransactions,
        isLoading: isLoading,
        loadFailed: loadFailed,
        kind: kind,
        walletId: walletId,
        wallets: wallets,
      );

  @override
  AnalysisState copyWith({bool? isLoading, bool? loadFailed, UiEffect? effect}) => AnalysisState(
    period: period,
    summary: summary,
    isCurrent: isCurrent,
    canGoBack: canGoBack,
    hasAnyTransactions: hasAnyTransactions,
    isLoading: isLoading ?? this.isLoading,
    loadFailed: loadFailed ?? this.loadFailed,
    selectedKey: selectedKey,
    othersOpen: othersOpen,
    kind: kind,
    walletId: walletId,
    wallets: wallets,
    effect: effect,
  );

  @override
  List<Object?> get props => [
    period,
    summary,
    isCurrent,
    canGoBack,
    hasAnyTransactions,
    isLoading,
    loadFailed,
    selectedKey,
    othersOpen,
    kind,
    walletId,
    wallets,
  ];
}
