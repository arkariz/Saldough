import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/shared/budget_catalog/budget_catalog.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

/// State [TransactionBloc].
final class TransactionState extends UiState<TransactionState> {
  /// Membuat [TransactionState].
  const TransactionState({
    required this.period,
    required this.wallets,
    required this.rawTransactions,
    required this.typeFilter,
    required this.walletFilter,
    required this.categoryFilter,
    required this.categoryOptions,
    required this.groups,
    required this.typeCounts,
    required this.isLoading,
    this.budgetItems = const [],
    this.searchQuery = '',
    this.loadFailed = false,
    this.isCurrent = true,
    this.canGoBack = false,
    this.availableMonths = const [],
    this.crossMonthScannedMonths = const [],
    this.crossMonthGroups = const [],
    this.isSearchingCrossMonth = false,
    this.crossMonthExhausted = false,
    super.effect,
  });

  /// State awal, sebelum periode berjalan dimuat.
  factory TransactionState.initial() {
    return TransactionState(
      period: ActiveFinancialMonth.periodOf(DateTime.now()),
      wallets: const [],
      rawTransactions: const [],
      typeFilter: TransactionTypeFilter.all,
      walletFilter: null,
      categoryFilter: null,
      categoryOptions: const [],
      groups: const [],
      typeCounts: const {},
      isLoading: true,
    );
  }

  /// Periode keuangan yang sedang ditampilkan (ADR-038), dibagi dengan segmen
  /// Analisis. Keanggotaannya lewat `periodDateOf`; urutan hari tetap menurut
  /// `date`.
  final FinancialPeriod period;

  /// [period] adalah periode berjalan: panah maju nonaktif.
  final bool isCurrent;

  /// Ada periode yang lebih lama untuk dilihat (sampai periode yang memuat
  /// bulan pertama pencatatan).
  final bool canGoBack;

  /// Seluruh dompet (aktif maupun tidak) -- untuk penyaring dompet dan
  /// penerjemah `walletId` -> nama pada tiap baris.
  final List<Wallet> wallets;

  /// Seluruh pos anggaran — untuk baris "Anggaran" di rincian transaksi
  /// (T-4.11) dan pemilih pos saat menyunting (T-4.4). Data sekunder:
  /// kosong kalau gagal dimuat.
  final List<BudgetItemOption> budgetItems;

  /// Pos anggaran ber-`itemId` [itemId], atau `null` kalau tidak ada lagi
  /// (anggarannya sudah dihapus).
  BudgetItemOption? budgetItemOf(String? itemId) {
    if (itemId == null) return null;
    for (final option in budgetItems) {
      if (option.itemId == itemId) return option;
    }
    return null;
  }

  /// Transaksi bulan [period] APA ADANYA dari repository, belum tersaring.
  /// Sumber kebenaran untuk [categoryOptions] dan ringkasan bulan (yang
  /// sengaja tidak ikut terpangkas filter -- lihat `TransactionListPage`).
  final List<Transaction> rawTransactions;

  /// Filter jenis aktif.
  final TransactionTypeFilter typeFilter;

  /// `id` dompet yang aktif difilter, `null` berarti semua dompet.
  final String? walletFilter;

  /// Id kategori yang aktif difilter, `null` berarti semua kategori.
  final String? categoryFilter;

  /// Id kategori DISTINCT yang benar-benar muncul di [rawTransactions], urut
  /// nama (ADR-026) -- bukan seluruh daftar kategori. Dihitung ulang tiap [rawTransactions]
  /// berubah (bulan baru dimuat), bukan tiap filter berubah.
  final List<String> categoryOptions;

  /// Transaksi bulan ini SETELAH seluruh filter ([typeFilter], [walletFilter],
  /// [categoryFilter]) diterapkan, dikelompokkan per tanggal, terbaru dulu.
  /// Dihitung sekali di bloc tiap kali salah satu input di atas berubah --
  /// bukan di widget tiap `build()` -- lihat catatan performa di
  /// `TransactionBloc._recomputed`.
  final List<TransactionDateGroup> groups;

  /// Jumlah transaksi per jenis, dihitung dari transaksi yang sudah tersaring
  /// [walletFilter]/[categoryFilter] TAPI BELUM [typeFilter] -- inilah yang
  /// membuat angka pada tiap chip jenis (mis. "Semua 42") tetap berarti walau
  /// jenisnya sendiri belum dipilih.
  final Map<TransactionTypeFilter, int> typeCounts;

  /// Kata kunci pencarian aktif, kosong kalau tidak sedang mencari. Ikut
  /// menyaring [groups] dan [typeCounts], tapi TIDAK [rawTransactions].
  final String searchQuery;

  /// Sedang memuat transaksi bulan berjalan.
  final bool isLoading;

  /// `true` kalau pembacaan TERAKHIR (dompet atau transaksi) gagal --
  /// dibedakan dari [rawTransactions] yang genuinely kosong, supaya layar
  /// tidak menampilkan keadaan kosong yang menyesatkan saat masalah
  /// sesungguhnya adalah pembacaan yang gagal.
  final bool loadFailed;

  /// Bulan yang pernah punya transaksi, terurut naik -- diisi sekali dari
  /// `TransactionRepository.listAvailableMonths()` saat pencarian lintas
  /// bulan pertama kali diminta (T-8.2). Kosong berarti belum pernah diminta.
  final List<DateTime> availableMonths;

  /// Bulan sebelum [period] yang SUDAH dipindai pencarian lintas bulan,
  /// terlepas dari filter/kata kunci yang mana -- direset ke kosong tiap kali
  /// filter, kata kunci, atau bulan berubah (lihat `TransactionBloc._recomputed`),
  /// karena hasil pindaian lama tidak lagi berarti untuk kriteria yang baru.
  final List<DateTime> crossMonthScannedMonths;

  /// Transaksi dari [crossMonthScannedMonths] yang cocok dengan filter dan
  /// kata kunci aktif, dikelompokkan per tanggal seperti [groups].
  final List<TransactionDateGroup> crossMonthGroups;

  /// Sedang memindai satu tumpuk bulan sebelumnya (T-8.2).
  final bool isSearchingCrossMonth;

  /// `true` kalau seluruh bulan sebelum [period] di [availableMonths] sudah
  /// habis dipindai -- tombol "Cari lebih jauh" disembunyikan sesudah ini.
  final bool crossMonthExhausted;

  @override
  TransactionState copyWith({
    FinancialPeriod? period,
    bool? isCurrent,
    bool? canGoBack,
    List<Wallet>? wallets,
    List<BudgetItemOption>? budgetItems,
    List<Transaction>? rawTransactions,
    TransactionTypeFilter? typeFilter,
    String? walletFilter,
    String? categoryFilter,
    List<String>? categoryOptions,
    List<TransactionDateGroup>? groups,
    Map<TransactionTypeFilter, int>? typeCounts,
    String? searchQuery,
    bool? isLoading,
    bool? loadFailed,
    List<DateTime>? availableMonths,
    List<DateTime>? crossMonthScannedMonths,
    List<TransactionDateGroup>? crossMonthGroups,
    bool? isSearchingCrossMonth,
    bool? crossMonthExhausted,
    UiEffect? effect,
  }) {
    return TransactionState(
      period: period ?? this.period,
      isCurrent: isCurrent ?? this.isCurrent,
      canGoBack: canGoBack ?? this.canGoBack,
      wallets: wallets ?? this.wallets,
      budgetItems: budgetItems ?? this.budgetItems,
      rawTransactions: rawTransactions ?? this.rawTransactions,
      typeFilter: typeFilter ?? this.typeFilter,
      walletFilter: walletFilter ?? this.walletFilter,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      categoryOptions: categoryOptions ?? this.categoryOptions,
      groups: groups ?? this.groups,
      typeCounts: typeCounts ?? this.typeCounts,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      loadFailed: loadFailed ?? this.loadFailed,
      availableMonths: availableMonths ?? this.availableMonths,
      crossMonthScannedMonths: crossMonthScannedMonths ?? this.crossMonthScannedMonths,
      crossMonthGroups: crossMonthGroups ?? this.crossMonthGroups,
      isSearchingCrossMonth: isSearchingCrossMonth ?? this.isSearchingCrossMonth,
      crossMonthExhausted: crossMonthExhausted ?? this.crossMonthExhausted,
      effect: effect,
    );
  }

  @override
  List<Object?> get props => [
    period,
    isCurrent,
    canGoBack,
    wallets,
    budgetItems,
    rawTransactions,
    typeFilter,
    walletFilter,
    categoryFilter,
    categoryOptions,
    groups,
    typeCounts,
    searchQuery,
    isLoading,
    loadFailed,
    availableMonths,
    crossMonthScannedMonths,
    crossMonthGroups,
    isSearchingCrossMonth,
    crossMonthExhausted,
  ];
}
