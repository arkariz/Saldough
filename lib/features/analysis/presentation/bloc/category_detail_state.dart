import 'dart:math' as math;

import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/features/analysis/domain/category_detail.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

/// Keadaan layar Rincian kategori satu periode (A5, T-19.5).
final class CategoryDetailState extends UiState<CategoryDetailState> {
  /// Membuat [CategoryDetailState].
  const CategoryDetailState({
    required this.period,
    required this.kind,
    required this.isLoading,
    this.name = '',
    this.isArchived = false,
    this.detail,
    this.groups = const [],
    this.wallets = const [],
    this.hasMore = false,
    this.trendSelected,
    this.loadFailed = false,
    super.effect,
  });

  /// Periode yang dirinci.
  final FinancialPeriod period;

  /// Jenis kategori: pengeluaran atau pemasukan.
  final CategoryKind kind;

  /// Nama kategori (atau Freelance); kosong sebelum termuat.
  final String name;

  /// Kategori sudah diarsipkan (tetap dihitung, ditandai).
  final bool isArchived;

  /// Rincian angka; `null` sebelum termuat.
  final CategoryDetail? detail;

  /// Transaksi periode ini, terbaru dulu, paling banyak 20, per hari.
  final List<TransactionDateGroup> groups;

  /// Seluruh dompet, untuk nama dompet tiap baris.
  final List<Wallet> wallets;

  /// Ada lebih dari 20 transaksi (tautan "Lihat semua transaksi" tetap selalu ada).
  final bool hasMore;

  /// Indeks kolom tren terpilih; `null` = periode yang dirinci (terakhir).
  final int? trendSelected;

  /// Sedang memuat pertama kali.
  final bool isLoading;

  /// Pemuatan pertama gagal.
  final bool loadFailed;

  /// Peta id → dompet.
  Map<String, Wallet> get walletsById => {for (final w in wallets) w.id: w};

  /// Indeks kolom tren yang terpilih.
  int get trendIndex {
    final length = detail?.trend.length ?? 0;
    return math.max(0, math.min(trendSelected ?? length - 1, length - 1));
  }

  /// Salinan dengan kolom tren [index] terpilih.
  CategoryDetailState withTrendSelected(int index) => CategoryDetailState(
    period: period,
    kind: kind,
    isLoading: isLoading,
    name: name,
    isArchived: isArchived,
    detail: detail,
    groups: groups,
    wallets: wallets,
    hasMore: hasMore,
    trendSelected: index,
    loadFailed: loadFailed,
  );

  @override
  CategoryDetailState copyWith({
    bool? isLoading,
    bool? loadFailed,
    UiEffect? effect,
  }) => CategoryDetailState(
    period: period,
    kind: kind,
    isLoading: isLoading ?? this.isLoading,
    name: name,
    isArchived: isArchived,
    detail: detail,
    groups: groups,
    wallets: wallets,
    hasMore: hasMore,
    trendSelected: trendSelected,
    loadFailed: loadFailed ?? this.loadFailed,
    effect: effect,
  );

  @override
  List<Object?> get props => [
    period,
    kind,
    name,
    isArchived,
    detail,
    groups,
    wallets,
    hasMore,
    trendSelected,
    isLoading,
    loadFailed,
  ];
}
