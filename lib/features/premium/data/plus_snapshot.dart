import 'package:dependencies/dependencies.dart';

/// Id entitlement tunggal di RevenueCat (ADR-041 §3.5).
const plusEntitlementId = 'plus';

/// Keadaan entitlement `plus` yang dilaporkan RevenueCat, lepas dari SDK
/// (ADR-041 §3.2, §3.3).
final class PlusSnapshot extends Equatable {
  /// Membuat [PlusSnapshot].
  const PlusSnapshot({
    required this.isActive,
    this.isPromotional = false,
    this.expiration,
    this.billingIssueSince,
  });

  /// Entitlement aktif sekarang.
  final bool isActive;

  /// Asalnya hak promosi RevenueCat (hadiah penguji, akun peninjau), bukan
  /// pembelian Play.
  final bool isPromotional;

  /// Akhir periode; `null` = tanpa tanggal berakhir.
  final DateTime? expiration;

  /// Sejak kapan Play melaporkan masalah pembayaran, atau `null`.
  final DateTime? billingIssueSince;

  /// Aktif tetapi ada masalah pembayaran: masa tenggang Play, tetap Plus.
  bool get inGrace => isActive && billingIssueSince != null;

  /// Tidak aktif karena masalah pembayaran: langganan ditahan.
  bool get onHold => !isActive && billingIssueSince != null;

  @override
  List<Object?> get props => [isActive, isPromotional, expiration, billingIssueSince];
}
