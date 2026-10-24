import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/services.dart' show PlatformException;
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:saldough/features/premium/data/plus_snapshot.dart';
import 'package:saldough/features/premium/domain/purchase_models.dart';

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

  /// Paket di offering [offeringId] (identifier RevenueCat); kosong bila
  /// offering tidak ada atau tidak punya paket yang dikenal.
  Future<List<PlanOption>> options(String offeringId);

  /// Membeli [option]. Hasil berhasil membawa keadaan terbaru; pembatalan
  /// pengguna dan galat dikembalikan sebagai hasil, bukan dilempar.
  Future<({BuyResult result, PlusSnapshot? snapshot})> purchase(PlanOption option);
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

  @override
  Future<List<PlanOption>> options(String offeringId) async {
    final offering = (await Purchases.getOfferings()).all[offeringId];
    return [
      for (final package in offering?.availablePackages ?? const <Package>[])
        if (PlusPlanKind.fromId(package.identifier) case final kind?)
          _optionOf(kind, package),
    ];
  }

  /// Harga perkenalan menggantikan harga biasa hanya di paket `yearly_intro`;
  /// harga biasa tetap ditampilkan (dicoret) di sampingnya.
  PlanOption _optionOf(PlusPlanKind kind, Package package) {
    final product = package.storeProduct;
    final intro = kind == PlusPlanKind.yearlyIntro ? product.introductoryPrice : null;
    return PlanOption(
      kind: kind,
      priceText: intro?.priceString ?? product.priceString,
      regularPriceText: intro == null ? null : product.priceString,
      perMonthText: product.pricePerMonthString,
      handle: package,
    );
  }

  @override
  Future<({BuyResult result, PlusSnapshot? snapshot})> purchase(PlanOption option) async {
    final handle = option.handle;
    if (handle is! Package) return (result: const BuyFailed(PurchaseFailure.other), snapshot: null);
    try {
      final done = await Purchases.purchase(PurchaseParams.package(handle));
      return (result: const BuyDone(), snapshot: _of(done.customerInfo));
    } on PlatformException catch (e) {
      return (result: purchaseResultOfCode(PurchasesErrorHelper.getErrorCode(e)), snapshot: null);
    }
  }
}

/// Memetakan kode galat SDK ke hasil beli: pembatalan pengguna bukan galat.
BuyResult purchaseResultOfCode(PurchasesErrorCode code) => switch (code) {
  PurchasesErrorCode.purchaseCancelledError => const BuyCancelled(),
  PurchasesErrorCode.paymentPendingError => const BuyPending(),
  PurchasesErrorCode.networkError || PurchasesErrorCode.offlineConnectionError => const BuyFailed(
    PurchaseFailure.network,
  ),
  PurchasesErrorCode.storeProblemError ||
  PurchasesErrorCode.purchaseNotAllowedError ||
  PurchasesErrorCode.purchaseInvalidError ||
  PurchasesErrorCode.productAlreadyPurchasedError => const BuyFailed(PurchaseFailure.billing),
  _ => const BuyFailed(PurchaseFailure.other),
};
