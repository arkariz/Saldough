import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

/// State [RecordBloc].
final class RecordState extends UiState<RecordState> {
  /// Membuat [RecordState].
  const RecordState({required this.wallets, required this.isLoading, required this.isSaving, super.effect});

  /// State awal sebelum daftar dompet dimuat.
  factory RecordState.initial() => const RecordState(wallets: [], isLoading: true, isSaving: false);

  /// Seluruh dompet aktif, sebagai pilihan pada tiap formulir CATAT.
  final List<Wallet> wallets;

  /// Sedang memuat daftar dompet.
  final bool isLoading;

  /// Sedang menyimpan transaksi — tombol Catat dinonaktifkan selagi ini
  /// `true` supaya tidak tercatat dobel kalau ditekan berkali-kali.
  final bool isSaving;

  @override
  RecordState copyWith({List<Wallet>? wallets, bool? isLoading, bool? isSaving, UiEffect? effect}) {
    return RecordState(
      wallets: wallets ?? this.wallets,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      effect: effect,
    );
  }

  @override
  List<Object?> get props => [wallets, isLoading, isSaving];
}
