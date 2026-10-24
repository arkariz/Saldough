import 'dart:async';
import 'dart:developer' as developer;

import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:saldough/features/premium/data/plus_snapshot.dart';

/// Pintu ke RevenueCat, dipisah dari SDK supaya [RevenueCatPlanSource] bisa
/// diuji tanpa platform (ADR-041 §3.1, §3.5). Semua metode melempar bila SDK
/// gagal; pemanggil menangkapnya (hak lama tetap berlaku).
abstract interface class PurchasesGateway {
  /// Menyiapkan SDK dengan kunci publik. Dipanggil sekali.
  Future<void> configure();

  /// Mengikat pengguna RevenueCat ke [uid] akun Firebase; hak anonim
  /// dipindahkan oleh RevenueCat.
  Future<PlusSnapshot?> logIn(String uid);

  /// Kembali ke pengguna anonim.
  Future<PlusSnapshot?> logOut();

  /// Keadaan terkini; `null` = RevenueCat tidak mengenal entitlement `plus`
  /// untuk pengguna ini.
  Future<PlusSnapshot?> fetch();

  /// Memulihkan pembelian dari akun Google Play (ponsel baru).
  Future<PlusSnapshot?> restore();

  /// Pembaruan keadaan dari SDK (pembelian, perpanjangan, kedaluwarsa).
  Stream<PlusSnapshot?> get updates;
}

/// Memetakan [info] (entitlement `plus` dari SDK) ke [PlusSnapshot].
/// `null` bila entitlement itu tidak ada.
PlusSnapshot? snapshotOfEntitlement(EntitlementInfo? info) {
  if (info == null) return null;
  return PlusSnapshot(
    isActive: info.isActive,
    isPromotional: info.store == Store.promotional,
    expiration: info.expirationDate == null ? null : DateTime.tryParse(info.expirationDate!)?.toLocal(),
    billingIssueSince: info.billingIssueDetectedAt == null
        ? null
        : DateTime.tryParse(info.billingIssueDetectedAt!)?.toLocal(),
  );
}

/// [PurchasesGateway] di atas `purchases_flutter`. Kunci SDK dari
/// `--dart-define=REVENUECAT_ANDROID_KEY` (ADR-041 §3.5, P-6).
final class PurchasesFlutterGateway implements PurchasesGateway {
  /// Membuat [PurchasesFlutterGateway] dengan kunci publik [apiKey].
  PurchasesFlutterGateway({required this.apiKey});

  /// Kunci SDK RevenueCat (publik).
  final String apiKey;

  final _updates = StreamController<PlusSnapshot?>.broadcast();
  bool _configured = false;

  @override
  Stream<PlusSnapshot?> get updates => _updates.stream;

  PlusSnapshot? _of(CustomerInfo info) => snapshotOfEntitlement(info.entitlements.all[plusEntitlementId]);

  @override
  Future<void> configure() async {
    if (_configured) return;
    await Purchases.configure(PurchasesConfiguration(apiKey));
    _configured = true;
    Purchases.addCustomerInfoUpdateListener((info) {
      try {
        _updates.add(_of(info));
      } on Object catch (e) {
        developer.log('Pembaruan RevenueCat gagal dibaca', error: e, name: 'Purchases');
      }
    });
  }

  @override
  Future<PlusSnapshot?> logIn(String uid) async => _of((await Purchases.logIn(uid)).customerInfo);

  @override
  Future<PlusSnapshot?> logOut() async => _of(await Purchases.logOut());

  @override
  Future<PlusSnapshot?> fetch() async => _of(await Purchases.getCustomerInfo());

  @override
  Future<PlusSnapshot?> restore() async => _of(await Purchases.restorePurchases());
}
