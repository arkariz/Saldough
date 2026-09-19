import 'package:dependencies/dependencies.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

/// Jenis transaksi yang disaring layar riwayat (FR-TXN-004). `all` bukan
/// "tanpa filter" di level data -- ia satu pilihan chip seperti tiga
/// lainnya, hanya kebetulan tidak mengecualikan apa pun berdasarkan jenis.
enum TransactionTypeFilter {
  /// Semua jenis.
  all,

  /// Hanya `IncomeTransaction`.
  income,

  /// Hanya `ExpenseTransaction`.
  expense,

  /// Hanya `TransferTransaction`.
  transfer,
}

/// Satu kelompok transaksi pada tanggal [date] yang sama, sudah tersaring
/// dan terurut (terbaru dulu) sesuai filter aktif saat kelompok ini dihitung.
final class TransactionDateGroup extends Equatable {
  /// Membuat [TransactionDateGroup].
  const TransactionDateGroup({
    required this.date,
    required this.netSen,
    required this.transactions,
  });

  /// Tanggal kelompok ini, waktu diabaikan (`day`-precision).
  final DateTime date;

  /// Jumlah pemasukan dikurangi pengeluaran pada tanggal ini. Transfer
  /// TIDAK ikut dihitung (CLAUDE.md aturan 7) -- boleh negatif.
  final int netSen;

  /// Transaksi pada tanggal ini, terbaru dulu.
  final List<Transaction> transactions;

  @override
  List<Object?> get props => [date, netSen, transactions];
}

/// State [TransactionBloc].
final class TransactionState extends UiState<TransactionState> {
  /// Membuat [TransactionState].
  const TransactionState({
    required this.month,
    required this.wallets,
    required this.rawTransactions,
    required this.typeFilter,
    required this.walletFilter,
    required this.categoryFilter,
    required this.categoryOptions,
    required this.groups,
    required this.typeCounts,
    required this.isLoading,
    this.searchQuery = '',
    this.loadFailed = false,
    super.effect,
  });

  /// State awal, sebelum bulan berjalan dimuat.
  factory TransactionState.initial() {
    final now = DateTime.now();
    return TransactionState(
      month: DateTime(now.year, now.month),
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

  /// Bulan yang sedang ditampilkan (tanggal selalu 1, jam diabaikan).
  final DateTime month;

  /// Seluruh dompet (aktif maupun tidak) -- untuk penyaring dompet dan
  /// penerjemah `walletId` -> nama pada tiap baris.
  final List<Wallet> wallets;

  /// Transaksi bulan [month] APA ADANYA dari repository, belum tersaring.
  /// Sumber kebenaran untuk [categoryOptions] dan ringkasan bulan (yang
  /// sengaja tidak ikut terpangkas filter -- lihat `TransactionListPage`).
  final List<Transaction> rawTransactions;

  /// Filter jenis aktif.
  final TransactionTypeFilter typeFilter;

  /// `id` dompet yang aktif difilter, `null` berarti semua dompet.
  final String? walletFilter;

  /// Kunci kategori yang aktif difilter, `null` berarti semua kategori.
  final String? categoryFilter;

  /// Kunci kategori DISTINCT yang benar-benar muncul di [rawTransactions] --
  /// bukan daftar tetap (`PROJECT_GLOSSARY.md` §"Konvensi penamaan": kategori
  /// adalah data bebas, bukan enum). Dihitung ulang tiap [rawTransactions]
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

  @override
  TransactionState copyWith({
    DateTime? month,
    List<Wallet>? wallets,
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
    UiEffect? effect,
  }) {
    return TransactionState(
      month: month ?? this.month,
      wallets: wallets ?? this.wallets,
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
      effect: effect,
    );
  }

  @override
  List<Object?> get props => [
    month,
    wallets,
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
  ];
}
