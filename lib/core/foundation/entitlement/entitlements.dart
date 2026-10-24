import 'package:dependencies/dependencies.dart';
import 'package:saldough/core/foundation/entitlement/entitlement_limits.dart';
import 'package:saldough/core/foundation/entitlement/plan_state.dart';
import 'package:saldough/core/foundation/entitlement/plus_feature.dart';

/// Keadaan jatah satu fitur pada satuan hitungnya (ADR-041 §3.7).
final class QuotaStatus extends Equatable {
  /// Membuat [QuotaStatus].
  const QuotaStatus({required this.used, this.limit});

  /// Tanpa batas (Plus tanpa batas wajar untuk fitur ini).
  static const unlimited = QuotaStatus(used: 0);

  /// Sudah terpakai pada satuan berjalan.
  final int used;

  /// Batas pada satuan berjalan; `null` = tanpa batas.
  final int? limit;

  /// Sisa, atau `null` bila tanpa batas.
  int? get remaining => switch (limit) {
    final limit? => (limit - used).clamp(0, limit),
    null => null,
  };

  /// Jatah habis.
  bool get exhausted => switch (limit) {
    final limit? => used >= limit,
    null => false,
  };

  @override
  List<Object?> get props => [used, limit];
}

/// Satu-satunya pintu fitur ke hak Plus (ADR-041 §3.1, §3.3). Fitur tidak
/// pernah bertanya ke RevenueCat atau Remote Config langsung.
///
/// Tidak satu pun metode melempar: gagal membaca hak berarti keadaan dihitung
/// dari yang masih diketahui, dan pencatatan tidak pernah terhalang. Hak tidak
/// pernah diperiksa di `RecordTransaction` (aturan 8).
abstract interface class Entitlements {
  /// Keadaan paket sekarang.
  PlanState get current;

  /// Memancar setiap kali [current] berubah.
  Stream<PlanState> get changes;

  /// Batas dan jatah yang berlaku.
  EntitlementLimits get limits;

  /// Fitur Plus [feature] terbuka penuh (uji coba atau Plus).
  bool can(PlusFeature feature);

  /// Boleh menambah satu lagi [feature] bila sudah ada [count]: selalu di
  /// Plus, di Gratis hanya di bawah batasnya (mis. template ke-2 saat
  /// [count] = 1 dan batas 1 → `false`).
  bool allows(PlusFeature feature, {required int count});

  /// Jatah [feature] pada satuan berjalan: per periode keuangan di Gratis,
  /// batas wajar per bulan di Plus.
  Future<QuotaStatus> quota(PlusFeature feature);

  /// Memakai satu jatah [feature] bila masih ada; `false` bila habis. Panggil
  /// sesudah hasilnya berhasil, atau kembalikan lewat [refund].
  Future<bool> tryUse(PlusFeature feature);

  /// Mengembalikan satu jatah [feature] yang gagal dipakai.
  Future<void> refund(PlusFeature feature);

  /// Menghitung ulang (mis. sesudah aplikasi kembali dibuka, atau hari
  /// berganti) dan mengambil batas terbaru.
  Future<void> refresh();
}
