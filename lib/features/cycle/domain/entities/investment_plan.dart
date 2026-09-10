import 'package:dependencies/dependencies.dart';
import 'package:saldough/features/cycle/domain/entities/allocation.dart';

/// Rencana pembagian sisa siklus ke pos tujuan.
final class InvestmentPlan extends Equatable {
  /// Membuat [InvestmentPlan].
  const InvestmentPlan({
    required this.returnDeposit,
    required this.allocations,
  });

  /// Rencana kosong — tanpa tambahan dana dan tanpa alokasi.
  factory InvestmentPlan.empty() => const InvestmentPlan(returnDeposit: 0, allocations: []);

  /// Tambahan dana dalam sen. Nol kalau tidak ada.
  final int returnDeposit;

  /// Pembagian per pos.
  final List<Allocation> allocations;

  /// Salinan [InvestmentPlan] dengan field yang disebutkan diganti.
  InvestmentPlan copyWith({int? returnDeposit, List<Allocation>? allocations}) {
    return InvestmentPlan(
      returnDeposit: returnDeposit ?? this.returnDeposit,
      allocations: allocations ?? this.allocations,
    );
  }

  @override
  List<Object?> get props => [returnDeposit, allocations];
}
