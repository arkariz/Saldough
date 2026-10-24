import 'package:saldough/features/premium/domain/purchase_models.dart';

/// Pintu layar premium ke pembelian Plus (ADR-041 §3.5): lapisan presentasi
/// hanya mengenal ini, bukan SDK atau penyimpanan. Tidak pernah melempar.
abstract interface class PlusPurchasing {
  /// Plus sudah dijual: tombol beli boleh tampil. Sebelumnya paywall hanya
  /// mengajak masuk akun (pra-peluncuran, ADR-041 §3.13).
  bool get isSelling;

  /// Paket yang ditawarkan sekarang; kosong bila belum dijual atau gagal dimuat.
  Future<OfferedPlans> offered();

  /// Membeli [option].
  Future<BuyResult> buy(PlanOption option);

  /// Memulihkan pembelian dari akun Google Play.
  Future<void> restore();
}

/// Tanpa sumber pembelian (build tanpa kunci RevenueCat, atau bukan Android).
final class NoPurchasing implements PlusPurchasing {
  /// Membuat [NoPurchasing].
  const NoPurchasing();

  @override
  bool get isSelling => false;

  @override
  Future<OfferedPlans> offered() async => OfferedPlans.none;

  @override
  Future<BuyResult> buy(PlanOption option) async => const BuyFailed(PurchaseFailure.other);

  @override
  Future<void> restore() async {}
}
