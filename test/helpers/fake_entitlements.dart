import 'dart:async';

import 'package:saldough/core/foundation/entitlement/entitlement.dart';

/// [Entitlements] palsu untuk uji gerbang: keadaan diatur lewat [state],
/// jatah dihitung dalam memori.
final class FakeEntitlements implements Entitlements {
  /// Membuat [FakeEntitlements]; bawaan Gratis.
  FakeEntitlements({
    this._state = const FreePlan(),
    this.limits = EntitlementLimits.defaults,
  });

  /// Plus penuh (sumber pra-peluncuran).
  factory FakeEntitlements.plus() =>
      FakeEntitlements(state: const PlusPlan(source: PlanSource.prelaunch));

  final _changes = StreamController<PlanState>.broadcast();
  PlanState _state;

  @override
  EntitlementLimits limits;

  /// Pemakaian jatah per fitur.
  final used = <PlusFeature, int>{};

  /// Jumlah panggilan [refresh].
  int refreshed = 0;

  /// Mengganti keadaan dan memancarkannya.
  void emit(PlanState next) {
    _state = next;
    _changes.add(next);
  }

  @override
  PlanState get current => _state;

  @override
  Stream<PlanState> get changes => _changes.stream;

  @override
  bool can(PlusFeature feature) => _state.isPlus;

  @override
  bool allows(PlusFeature feature, {required int count}) =>
      _state.isPlus || count < limits.freeAllowance(feature);

  @override
  Future<QuotaStatus> quota(PlusFeature feature) async {
    final limit = _state.isPlus
        ? limits.fairUse(feature)
        : limits.freeAllowance(feature);
    return limit == null
        ? QuotaStatus.unlimited
        : QuotaStatus(used: used[feature] ?? 0, limit: limit);
  }

  @override
  Future<bool> tryUse(PlusFeature feature) async {
    final status = await quota(feature);
    if (status.exhausted) return false;
    if (status.limit != null) used[feature] = (used[feature] ?? 0) + 1;
    return true;
  }

  @override
  Future<void> refund(PlusFeature feature) async {
    final n = used[feature] ?? 0;
    if (n > 0) used[feature] = n - 1;
  }

  @override
  Future<void> refresh() async => refreshed++;
}
