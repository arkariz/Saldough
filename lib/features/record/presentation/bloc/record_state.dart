import 'package:saldough/features/record/domain/budget_item_catalog.dart';
import 'package:saldough/features/record/domain/record_defaults.dart';
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

  @override
  RecordState copyWith({
    List<Wallet>? wallets,
    List<BudgetItemOption>? budgetItems,
    RecordDefaults? defaults,
    bool? isLoading,
    bool? isSaving,
    bool? loadFailed,
    UiEffect? effect,
  }) {
    return RecordState(
      wallets: wallets ?? this.wallets,
      budgetItems: budgetItems ?? this.budgetItems,
      defaults: defaults ?? this.defaults,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      loadFailed: loadFailed ?? this.loadFailed,
      effect: effect,
    );
  }

  @override
  List<Object?> get props => [wallets, budgetItems, defaults, isLoading, isSaving, loadFailed];
}
