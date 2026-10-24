import 'dart:async';
import 'dart:developer' as developer;

import 'package:di/di.dart';
import 'package:flutter/widgets.dart';
import 'package:saldough/app/premium/plan_override.dart';
import 'package:saldough/core/financial_month/financial_period.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/core/presentation/plan/active_plan.dart';
import 'package:saldough/features/premium/data/entitlement_cache_store.dart';
import 'package:saldough/features/premium/data/firebase_entitlement_config.dart';
import 'package:saldough/features/premium/data/local_entitlements.dart';
import 'package:saldough/features/premium/data/quota_store.dart';
import 'package:saldough/features/premium/data/trial_store.dart';
import 'package:saldough/shared/auth/auth.dart';

/// Mendaftarkan hak Plus ke [container] (ADR-041 §3.1). Malas: tidak ada yang
/// menyentuh Firebase sampai [startEntitlements] atau pemakai pertama.
void registerEntitlements(GetIt container) {
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

/// Menghubungkan hak ke status masuk akun dan siklus hidup aplikasi (ADR-041
/// §3.3, §3.4). Dipanggil bootstrap sesudah jadwal periode keuangan dimuat;
/// aman dipanggil ulang saat boot ulang (langganan lama dilepas).
Future<void> startEntitlements(GetIt container) async {
  await _authSubscription?.cancel();
  _lifecycle?.dispose();

  final entitlements = container<LocalEntitlements>();
  // ADR-041 §3.10: pengganti uji (tanpa efek di rilis); perubahannya
  // menghitung ulang paket.
  // Gerbang tampilan membaca paket lewat `ActivePlan` (ADR-041 §3.8).
  await _planSubscription?.cancel();
  ActivePlan.notifier.value = entitlements.current;
  _planSubscription = entitlements.changes.listen((state) => ActivePlan.notifier.value = state);
  final planOverride = container<PlanOverrideController>();
  await planOverride.load();
  planOverride.addListener(() => unawaited(entitlements.recompute()));
  final auth = container<AuthRepository>();
  AppUser? user;
  try {
    user = auth.currentUser;
    _authSubscription = auth.authStateChanges().listen(
      (next) => unawaited(entitlements.setAccount(_accountOf(next))),
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
  unawaited(entitlements.refresh());
  _lifecycle = AppLifecycleListener(
    onResume: () => unawaited(entitlements.refresh()),
  );
}

EntitlementAccount? _accountOf(AppUser? user) => user == null
    ? null
    : EntitlementAccount(uid: user.uid, createdAt: user.createdAt);
