import 'package:saldough/shared/income/income.dart';
import 'package:state_management/state_management.dart';

/// State [IncomeSourceBloc]. `effect` tidak pernah masuk [props] (ADR-0003).
final class IncomeSourceState extends UiState<IncomeSourceState> {
  /// Membuat [IncomeSourceState].
  const IncomeSourceState({required this.sources, required this.isLoading, super.effect});

  /// State awal sebelum daftar sumber dimuat.
  factory IncomeSourceState.initial() => const IncomeSourceState(sources: [], isLoading: true);

  /// Seluruh sumber pemasukan terdaftar (FR-INC-001).
  final List<IncomeSource> sources;

  /// Sedang memuat/menyimpan.
  final bool isLoading;

  @override
  IncomeSourceState copyWith({List<IncomeSource>? sources, bool? isLoading, UiEffect? effect}) {
    return IncomeSourceState(
      sources: sources ?? this.sources,
      isLoading: isLoading ?? this.isLoading,
      effect: effect,
    );
  }

  @override
  List<Object?> get props => [sources, isLoading];
}
