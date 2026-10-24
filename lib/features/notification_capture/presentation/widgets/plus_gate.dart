import 'package:flutter/widgets.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/presentation/plan/active_plan.dart';
import 'package:saldough/features/premium/presentation/navigation/premium_route_keys.dart';

/// Gerbang Plus untuk Catat dari notifikasi (ADR-041 §3.8): Gratis hanya
/// sumber pertama, tanpa tingkat otomatis, dan tanpa pola baru. Hanya
/// menentukan apakah aksi boleh jalan; tidak pernah mengubah data.

/// Menambah satu sumber lagi ke [count] sumber yang sudah ada melewati batas
/// Gratis.
bool exceedsFreeSources(int count) => !ActivePlan.isPlus && count >= ActivePlan.limits.value.freeNotificationSources;

/// Paket bukan Plus, jadi tingkat otomatis dan pola baru terkunci.
bool get plusLocked => !ActivePlan.isPlus;

/// Membuka paywall untuk gerbang notifikasi.
Future<void> openNotificationPaywall(BuildContext context) =>
    context.pushRoute(PremiumRouteKeys.paywall, const PaywallInput(PaywallTrigger.notificationSource));
