import 'package:saldough/features/budget/domain/entities/budget_template.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

/// State `BudgetTemplateBloc`.
final class BudgetTemplateState extends UiState<BudgetTemplateState> {
  /// Membuat [BudgetTemplateState].
  const BudgetTemplateState({
    required this.templates,
    required this.wallets,
    required this.isLoading,
    this.loadFailed = false,
    super.effect,
  });

  /// State awal, sebelum apa pun dimuat.
  factory BudgetTemplateState.initial() => const BudgetTemplateState(templates: [], wallets: [], isLoading: true);

  /// Seluruh template, aktif maupun tidak, urutan simpan.
  final List<BudgetTemplate> templates;

  /// Seluruh dompet — pilihan dan nama dompet tujuan pos transfer.
  final List<Wallet> wallets;

  /// Sedang memuat untuk pertama kali.
  final bool isLoading;

  /// Pembacaan terakhir gagal.
  final bool loadFailed;

  /// Dompet aktif, pilihan dompet tujuan pos transfer baru.
  List<Wallet> get activeWallets => wallets.where((w) => w.isActive).toList();

  /// Dompet ber-`id` [id], atau `null`.
  Wallet? walletOf(String? id) => wallets.where((w) => w.id == id).firstOrNull;

  @override
  BudgetTemplateState copyWith({
    List<BudgetTemplate>? templates,
    List<Wallet>? wallets,
    bool? isLoading,
    bool? loadFailed,
    UiEffect? effect,
  }) {
    return BudgetTemplateState(
      templates: templates ?? this.templates,
      wallets: wallets ?? this.wallets,
      isLoading: isLoading ?? this.isLoading,
      loadFailed: loadFailed ?? this.loadFailed,
      effect: effect,
    );
  }

  @override
  List<Object?> get props => [templates, wallets, isLoading, loadFailed];
}
