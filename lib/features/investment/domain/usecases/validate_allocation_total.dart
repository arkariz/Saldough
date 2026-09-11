import 'package:saldough/features/investment/domain/entities/allocation_percentage.dart';

/// Memvalidasi total persentase [allocations] (FR-INV-003).
///
/// Nilai 0 sah — artinya bulan itu belum dialokasikan. Yang ditolak hanya
/// total selain 0 dan selain 100 (lihat DOMAIN_MODEL.md bagian "Invarian").
bool isValidAllocationTotal(List<AllocationPercentage> allocations) {
  final total = allocations.fold(0, (sum, a) => sum + a.percentage);
  return total == 0 || total == 100;
}
