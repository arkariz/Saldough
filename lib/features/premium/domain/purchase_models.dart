import 'package:dependencies/dependencies.dart';
import 'package:saldough/features/premium/domain/offering_policy.dart';

/// Paket langganan yang bisa dibeli (ADR-041 §3.5). [id] sama dengan
/// identifier package di offering RevenueCat dan nilai `plan` di analitik.
enum PlusPlanKind {
  /// Bulanan, Rp25.000.
  monthly('monthly'),

  /// Tahunan, Rp179.000.
  yearly('yearly'),

  /// Tahunan Harga Pendiri, terkunci selamanya.
  yearlyFounder('yearly_founder'),

  /// Tahunan dengan harga perkenalan tahun pertama (penawaran sesudah uji coba).
  yearlyIntro('yearly_intro');

  const PlusPlanKind(this.id);

  /// Identifier package.
  final String id;

  /// Paket dari identifier package; `null` bila tidak dikenal.
  static PlusPlanKind? fromId(String id) =>
      values.where((k) => k.id == id).firstOrNull;
}

/// Satu pilihan paket di layar beli. Harga ditampilkan dari [priceText] (string
/// harga toko), tidak pernah dari kode atau Remote Config (ADR-041 §3.5).
final class PlanOption extends Equatable {
  /// Membuat [PlanOption]; [handle] milik gateway (paket SDK).
  const PlanOption({
    required this.kind,
    required this.priceText,
    required this.handle,
  });

  /// Jenis paket.
  final PlusPlanKind kind;

  /// Harga dari toko, mis. "Rp179.000".
  final String priceText;

  /// Rujukan buram untuk gateway.
  final Object handle;

  @override
  List<Object?> get props => [kind, priceText, handle];
}

/// Alasan pembelian gagal (ADR-041 §3.12, `purchase_failed.reason`).
enum PurchaseFailure {
  /// Tanpa koneksi atau server tidak terjangkau.
  network('network'),

  /// Masalah di Play atau metode pembayaran.
  billing('billing'),

  /// Lainnya.
  other('other');

  const PurchaseFailure(this.analyticsName);

  /// Nilai parameter `reason`.
  final String analyticsName;
}

/// Hasil satu percobaan beli.
sealed class BuyResult {
  const BuyResult();
}

/// Pembelian berhasil.
final class BuyDone extends BuyResult {
  /// Membuat [BuyDone].
  const BuyDone();
}

/// Pengguna menutup layar pembayaran Play; bukan galat.
final class BuyCancelled extends BuyResult {
  /// Membuat [BuyCancelled].
  const BuyCancelled();
}

/// Pembelian gagal.
final class BuyFailed extends BuyResult {
  /// Membuat [BuyFailed].
  const BuyFailed(this.reason);

  /// Alasannya.
  final PurchaseFailure reason;
}

/// Pilihan yang ditawarkan sekarang: offering terpilih dan paketnya.
final class OfferedPlans extends Equatable {
  /// Membuat [OfferedPlans].
  const OfferedPlans({required this.offering, required this.options});

  /// Belum dijual atau tidak ada yang bisa ditawarkan.
  static const none = OfferedPlans(offering: null, options: []);

  /// Offering terpilih; `null` bila belum dijual.
  final OfferingId? offering;

  /// Paket yang bisa dibeli, bulanan lebih dulu.
  final List<PlanOption> options;

  /// Tidak ada yang ditawarkan.
  bool get isEmpty => options.isEmpty;

  @override
  List<Object?> get props => [offering, options];
}
