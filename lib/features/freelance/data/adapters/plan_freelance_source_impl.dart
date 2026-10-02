import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/freelance/domain/repositories/freelance_repository.dart';
import 'package:saldough/features/freelance/domain/usecases/calculate_net_pay.dart';
import 'package:saldough/features/plan/domain/plan_sources.dart';
import 'package:saldough/shared/recurring/recurring.dart';

/// Implementasi port [PlanFreelanceSource] milik `plan` (ADR-0009): gaji
/// bersih tiap pembayaran yang belum diterima, dihitung [CalculateNetPay]
/// yang sama dengan Ikhtisar Freelance. Dompetnya belum diketahui sebelum
/// diterima, jadi hanya masuk perkiraan seluruh dompet.
final class PlanFreelanceSourceImpl implements PlanFreelanceSource {
  /// Membuat [PlanFreelanceSourceImpl].
  const PlanFreelanceSourceImpl({required this._repository});

  final FreelanceRepository _repository;

  @override
  Future<Either<Failure, List<UncertainIncome>>> unpaid() async {
    final payments = await _repository.listPayments();
    final entries = await _repository.listEntries();
    return payments.flatMap(
      (payments) => entries.map((entries) {
        final earned = <String, int>{for (final e in entries) e.id: e.earnedAmount};
        return [
          for (final payment in payments)
            if (!payment.isPaid)
              if (const CalculateNetPay()(
                    grossPay: payment.entryIds.fold(0, (sum, id) => sum + (earned[id] ?? 0)),
                    deductionRules: payment.deductionRules,
                  ).netPay
                  case final net when net > 0)
                (walletId: null, amount: net, date: payment.expectedDate),
        ];
      }),
    );
  }
}
