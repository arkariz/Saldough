import 'dart:developer' as developer;

import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/features/premium/data/purchases_gateway.dart';
import 'package:saldough/features/premium/data/revenuecat_plan_source.dart';
import 'package:saldough/features/premium/data/trial_store.dart';
import 'package:saldough/features/premium/domain/offering_policy.dart';
import 'package:saldough/features/premium/domain/purchase_models.dart';

/// Beli dan pulihkan langganan Plus (ADR-041 §3.5, P-9): tanpa UI, dipakai
/// layar paywall (T-23.17). Tidak mensyaratkan akun; hak terikat ke akun Google
/// Play dan bisa dipulihkan, dan ikut berpindah bila pengguna kemudian masuk
/// (RevenueCat memindahkan hak anonim).
///
/// Tidak pernah melempar: galat jaringan atau SDK menjadi hasil kosong atau
/// [BuyFailed].
final class PremiumPurchases {
  /// Membuat [PremiumPurchases]. [uid] = akun yang sedang masuk, atau `null`.
  PremiumPurchases({
    required this.gateway,
    required this.source,
    required this.trials,
    required this.config,
    required this.uid,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// Pintu ke SDK.
  final PurchasesGateway gateway;

  /// Tempat hasil pembelian disalin ke cache hak.
  final RevenueCatPlanSource source;

  /// Rekaman uji coba, untuk jendela penawaran sesudah uji coba.
  final TrialStore trials;

  /// Batas dan jendela penawaran dari Remote Config.
  final EntitlementConfig config;

  /// Akun yang sedang masuk.
  final String? Function() uid;

  final DateTime Function() _now;

  /// Plus sudah dijual: `plus_launch_at` terisi dan sudah tiba. Sebelum itu
  /// tombol beli tidak tampil (ADR-041 §3.13 butir 1).
  bool get isSelling {
    final launch = config.current.plusLaunchAt;
    return launch != null && !_now().isBefore(launch);
  }

  /// Offering yang berlaku sekarang menurut [selectOffering].
  Future<OfferingId> currentOffering() async {
    final limits = config.current;
    final account = uid();
    final trial = account == null
        ? null
        : (await trials.recordFor(account)).getOrElse((_) => null);
    return selectOffering(
      now: _now(),
      founderUntil: limits.founderUntil,
      trialEndsOn: trial?.endsOn,
      postTrialHours: limits.postTrialOfferHours,
    );
  }

  /// Paket yang ditawarkan sekarang. Offering Pendiri atau sesudah uji coba
  /// yang kosong di RevenueCat jatuh ke offering biasa, supaya tombol beli
  /// tidak pernah kosong karena salah setelan.
  Future<OfferedPlans> offered() async {
    if (!isSelling) return OfferedPlans.none;
    try {
      final chosen = await currentOffering();
      var options = await gateway.options(chosen.id);
      var offering = chosen;
      if (options.isEmpty && chosen != OfferingId.standard) {
        offering = OfferingId.standard;
        options = await gateway.options(offering.id);
      }
      if (options.isEmpty) return OfferedPlans.none;
      final sorted = [...options]
        ..sort((a, b) => a.kind.index.compareTo(b.kind.index));
      return OfferedPlans(offering: offering, options: sorted);
    } on Object catch (e) {
      developer.log('Penawaran Plus gagal dimuat', error: e, name: 'Purchases');
      return OfferedPlans.none;
    }
  }

  /// Membeli [option]; berhasil menyalin hak baru ke cache sehingga Plus
  /// berlaku tanpa menunggu penyegaran.
  Future<BuyResult> buy(PlanOption option) async {
    if (!isSelling) return const BuyFailed(PurchaseFailure.other);
    try {
      final outcome = await gateway.purchase(option);
      if (outcome.result is BuyDone) await source.apply(outcome.snapshot);
      return outcome.result;
    } on Object catch (e) {
      developer.log('Pembelian gagal', error: e, name: 'Purchases');
      return const BuyFailed(PurchaseFailure.other);
    }
  }

  /// Memulihkan pembelian dari akun Google Play (ponsel baru). Selalu tersedia,
  /// juga sebelum Plus dijual: penguji dengan hak promosi pun terbantu.
  Future<void> restore() => source.restore();
}
