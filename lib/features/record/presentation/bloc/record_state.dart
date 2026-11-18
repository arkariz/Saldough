import 'package:saldough/features/record/domain/record_defaults.dart';
import 'package:saldough/shared/budget_catalog/budget_catalog.dart';
import 'package:saldough/shared/investment/investment.dart';
import 'package:saldough/shared/savings_goal/savings_goal.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

/// State [RecordBloc].
final class RecordState extends UiState<RecordState> {
  /// Membuat [RecordState].
  const RecordState({
    required this.wallets,
    required this.isLoading,
    required this.isSaving,
    this.budgetItems = const [],
    this.defaults = const RecordDefaults(),
    this.loadFailed = false,
    this.saveCount = 0,
    this.transferOnlyWalletIds = const {},
    this.activeGoals = const [],
    this.rememberedSplit = const {},
    this.instruments = const [],
    this.investmentTrades = const [],
    super.effect,
  });

  /// State awal sebelum daftar dompet dimuat.
  factory RecordState.initial() => const RecordState(wallets: [], isLoading: true, isSaving: false);

  /// Seluruh dompet aktif, sebagai pilihan pada tiap formulir CATAT.
  final List<Wallet> wallets;

  /// Seluruh pos anggaran untuk pemilih di formulir pengeluaran dan transfer
  /// (T-4.4). Data sekunder: kalau gagal dimuat, daftarnya kosong dan CATAT
  /// tetap berjalan tanpa tautan anggaran.
  final List<BudgetItemOption> budgetItems;

  /// Dompet dan kategori bawaan dari transaksi terbaru (UX-2, UX-3). Data
  /// sekunder seperti [budgetItems]: gagal dibaca berarti tanpa isian bawaan.
  final RecordDefaults defaults;

  /// Sedang memuat daftar dompet.
  final bool isLoading;

  /// Sedang menyimpan transaksi — tombol Catat dinonaktifkan selagi ini
  /// `true` supaya tidak tercatat dobel kalau ditekan berkali-kali.
  final bool isSaving;

  /// `true` kalau pemuatan dompet TERAKHIR gagal (`Left`) — dibedakan dari
  /// `wallets` yang genuinely kosong, supaya `AppShellPage` tidak
  /// menampilkan pesan "belum ada dompet" yang menyesatkan saat masalah
  /// sesungguhnya adalah pembacaan yang gagal (lihat `_onWalletsLoaded`).
  final bool loadFailed;

  /// Jumlah transaksi yang berhasil disimpan bloc ini. Naik sesudah
  /// penyimpanan berhasil, supaya pemanggil CATAT tahu transaksinya tersimpan
  /// (kotak masuk Catat dari notifikasi, ADR-032 §3.6).
  final int saveCount;

  /// Dompet milik tujuan tabungan: hanya ditawarkan di formulir transfer,
  /// tidak di pemasukan dan pengeluaran (ADR-048 §8.2a).
  final Set<String> transferOnlyWalletIds;

  /// Dompet untuk pemilih pemasukan dan pengeluaran.
  List<Wallet> get incomeExpenseWallets => wallets.where((w) => !transferOnlyWalletIds.contains(w.id)).toList();

  /// Tujuan Active yang dompetnya aktif, untuk mode bagi CATAT › Transfer
  /// (ADR-048 §9.3), urut seperti di tab Dompet.
  final List<SavingsGoal> activeGoals;

  /// Persen pembagian terakhir (`goalId` → persen, ADR-048 §9.3).
  final Map<String, int> rememberedSplit;

  /// Ringkasan instrumen untuk jenis Investasi (ADR-049 §3.7).
  final List<InstrumentSummary> instruments;

  /// Semua transaksi investasi, untuk "Dimiliki n pada tanggal" (rupa B-97
  /// §4.5).
  final List<InvestmentTransaction> investmentTrades;

  @override
  RecordState copyWith({
    List<Wallet>? wallets,
    List<BudgetItemOption>? budgetItems,
    RecordDefaults? defaults,
    bool? isLoading,
    bool? isSaving,
    bool? loadFailed,
    int? saveCount,
    Set<String>? transferOnlyWalletIds,
    List<SavingsGoal>? activeGoals,
    Map<String, int>? rememberedSplit,
    List<InstrumentSummary>? instruments,
    List<InvestmentTransaction>? investmentTrades,
    UiEffect? effect,
  }) {
    return RecordState(
      wallets: wallets ?? this.wallets,
      budgetItems: budgetItems ?? this.budgetItems,
      defaults: defaults ?? this.defaults,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      loadFailed: loadFailed ?? this.loadFailed,
      saveCount: saveCount ?? this.saveCount,
      transferOnlyWalletIds: transferOnlyWalletIds ?? this.transferOnlyWalletIds,
      activeGoals: activeGoals ?? this.activeGoals,
      rememberedSplit: rememberedSplit ?? this.rememberedSplit,
      instruments: instruments ?? this.instruments,
      investmentTrades: investmentTrades ?? this.investmentTrades,
      effect: effect,
    );
  }

  @override
  List<Object?> get props => [
    wallets,
    budgetItems,
    defaults,
    isLoading,
    isSaving,
    loadFailed,
    saveCount,
    transferOnlyWalletIds,
    activeGoals,
    rememberedSplit,
    instruments,
    investmentTrades,
  ];
}
