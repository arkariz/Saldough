import 'dart:async';
import 'dart:developer' as developer;

import 'package:di/di.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:saldough/app/premium/plan_override.dart';
import 'package:saldough/core/financial_month/financial_period.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/core/presentation/plan/active_plan.dart';
import 'package:saldough/features/premium/data/entitlement_cache_store.dart';
import 'package:saldough/features/premium/data/firebase_entitlement_config.dart';
import 'package:saldough/features/premium/data/local_entitlements.dart';
import 'package:saldough/features/premium/data/premium_purchases.dart';
import 'package:saldough/features/premium/data/purchases_gateway.dart';
import 'package:saldough/features/premium/data/quota_store.dart';
import 'package:saldough/features/premium/data/revenuecat_plan_source.dart';
import 'package:saldough/features/premium/data/trial_store.dart';
import 'package:saldough/shared/auth/auth.dart';

/// Kunci SDK RevenueCat (publik), disuntikkan lewat
/// `--dart-define=REVENUECAT_ANDROID_KEY=...` di kedua lane rilis (ADR-041
/// §3.5, P-6). Kosong: tidak ada sumber RevenueCat, hak hanya dari uji coba
/// dan pra-peluncuran.
const _revenueCatKey = String.fromEnvironment('REVENUECAT_ANDROID_KEY');

/// Mendaftarkan hak Plus ke [container] (ADR-041 §3.1). Malas: tidak ada yang
/// menyentuh Firebase sampai [startEntitlements] atau pemakai pertama.
///
/// [revenueCatKey] dan [platform] untuk uji; bawaannya kunci build dan
/// platform berjalan. RevenueCat hanya didaftarkan di Android dengan kunci.
void registerEntitlements(
  GetIt container, {
  String revenueCatKey = _revenueCatKey,
  TargetPlatform? platform,
}) {
  if (revenueCatKey.isNotEmpty && (platform ?? defaultTargetPlatform) == TargetPlatform.android) {
    container
      ..registerLazySingleton<PurchasesGateway>(() => PurchasesFlutterGateway(apiKey: revenueCatKey))
      ..registerLazySingleton<RevenueCatPlanSource>(
        () => RevenueCatPlanSource(
          gateway: container<PurchasesGateway>(),
          cache: EntitlementCacheStore(storage: container()),
          onChanged: container<LocalEntitlements>().reloadCache,
        ),
      )
      ..registerLazySingleton<PremiumPurchases>(
        () => PremiumPurchases(
          gateway: container<PurchasesGateway>(),
          source: container<RevenueCatPlanSource>(),
          trials: TrialStore(storage: container()),
          config: container<EntitlementConfig>(),
          uid: () => container<LocalEntitlements>().account?.uid,
        ),
      );
  }
  container
    ..registerLazySingleton<EntitlementConfig>(FirebaseEntitlementConfig.new)
    ..registerLazySingleton<PlanOverrideController>(
      () => PlanOverrideController(storage: container()),
    )
    ..registerLazySingleton<LocalEntitlements>(
      () => LocalEntitlements(
        config: container<EntitlementConfig>(),
        trials: TrialStore(storage: container()),
        cache: EntitlementCacheStore(storage: container()),
        quotas: QuotaStore(storage: container()),
        schedule: () => ActiveFinancialMonth.schedule,
        override: () => container<PlanOverrideController>().value,
      ),
    )
    ..registerLazySingleton<Entitlements>(() => container<LocalEntitlements>());
}

StreamSubscription<AppUser?>? _authSubscription;
AppLifecycleListener? _lifecycle;
StreamSubscription<PlanState>? _planSubscription;
StreamSubscription<EntitlementLimits>? _limitsSubscription;
RevenueCatPlanSource? _revenueCat;

/// Menghubungkan hak ke status masuk akun dan siklus hidup aplikasi (ADR-041
/// §3.3, §3.4). Dipanggil bootstrap sesudah jadwal periode keuangan dimuat;
/// aman dipanggil ulang saat boot ulang (langganan lama dilepas).
Future<void> startEntitlements(GetIt container) async {
  await _authSubscription?.cancel();
  _lifecycle?.dispose();

  await _revenueCat?.dispose();
  final entitlements = container<LocalEntitlements>();
  final revenueCat = _revenueCat = container.isRegistered<RevenueCatPlanSource>()
      ? container<RevenueCatPlanSource>()
      : null;
  // ADR-041 §3.10: pengganti uji (tanpa efek di rilis); perubahannya
  // menghitung ulang paket.
  // Gerbang tampilan membaca paket lewat `ActivePlan` (ADR-041 §3.8).
  await _planSubscription?.cancel();
  ActivePlan.notifier.value = entitlements.current;
  _planSubscription = entitlements.changes.listen((state) => ActivePlan.notifier.value = state);
  await _limitsSubscription?.cancel();
  ActivePlan.limits.value = entitlements.limits;
  _limitsSubscription = container<EntitlementConfig>().changes.listen((limits) => ActivePlan.limits.value = limits);
  final planOverride = container<PlanOverrideController>();
  await planOverride.load();
  planOverride.addListener(() => unawaited(entitlements.recompute()));
  final auth = container<AuthRepository>();
  AppUser? user;
  try {
    user = auth.currentUser;
    _authSubscription = auth.authStateChanges().listen(
      (next) => unawaited(_accountChanged(entitlements, revenueCat, next)),
      onError: (Object e) => developer.log(
        'Status masuk akun gagal didengar',
        error: e,
        name: 'Entitlements',
      ),
    );
  } on Object catch (e) {
    // Firebase belum siap (luring sejak pertama dibuka): tanpa akun = Gratis
    // atau pra-peluncuran, tidak menghalangi aplikasi terbuka.
    developer.log(
      'Status masuk akun tidak tersedia',
      error: e,
      name: 'Entitlements',
    );
  }
  await entitlements.setAccount(_accountOf(user));
  // Hak RevenueCat disalin ke cache di latar; tidak menunda layar pertama.
  if (revenueCat != null) {
    unawaited(
      revenueCat.start().then((_) => revenueCat.setUser(user?.uid)),
    );
  }
  unawaited(entitlements.refresh());
  _lifecycle = AppLifecycleListener(
    onResume: () {
      unawaited(entitlements.refresh());
      if (revenueCat != null) unawaited(revenueCat.refresh());
    },
  );
}

Future<void> _accountChanged(LocalEntitlements entitlements, RevenueCatPlanSource? revenueCat, AppUser? user) async {
  await entitlements.setAccount(_accountOf(user));
  await revenueCat?.setUser(user?.uid);
}

EntitlementAccount? _accountOf(AppUser? user) => user == null
    ? null
    : EntitlementAccount(uid: user.uid, createdAt: user.createdAt);
