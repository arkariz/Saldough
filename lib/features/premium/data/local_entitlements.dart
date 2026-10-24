import 'dart:async';
import 'dart:developer' as developer;

import 'package:dependencies/dependencies.dart';
import 'package:saldough/core/financial_month/financial_period.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/features/premium/data/entitlement_cache_store.dart';
import 'package:saldough/features/premium/data/quota_store.dart';
import 'package:saldough/features/premium/data/trial_store.dart';

/// Akun yang sedang masuk, sebatas yang dibutuhkan hak (ADR-041 §3.4).
final class EntitlementAccount extends Equatable {
  /// Membuat [EntitlementAccount].
  const EntitlementAccount({required this.uid, this.createdAt});

  /// Pengenal akun.
  final String uid;

  /// Saat akun dibuat menurut server, bila diketahui.
  final DateTime? createdAt;

  @override
  List<Object?> get props => [uid, createdAt];
}

/// [Entitlements] dari sumber lokal (ADR-041 §3.3, §3.4, §3.7, §3.13): batas
/// dari [EntitlementConfig], uji coba dan jatah dari penyimpanan, hak
/// RevenueCat dari cache (pengisinya menyusul di T-23.14), dan akun yang
/// diberikan akar komposisi lewat [setAccount].
///
/// Tidak pernah melempar: galat penyimpanan dicatat dan diperlakukan sebagai
/// "tidak diketahui".
final class LocalEntitlements implements Entitlements {
  /// Membuat [LocalEntitlements].
  LocalEntitlements({
    required this._config,
    required this._trials,
    required this._cache,
    required this._quotas,
    required this._schedule,
    PlanOverride Function()? override,
    DateTime Function()? now,
  }) : _override = override ?? (() => PlanOverride.auto),
       _now = now ?? DateTime.now {
    _current = _resolve();
    _configSub = _config.changes.listen((_) => unawaited(_recompute()));
  }

  final EntitlementConfig _config;
  final TrialStore _trials;
  final EntitlementCacheStore _cache;
  final QuotaStore _quotas;
  final FinancialMonthSchedule Function() _schedule;
  final PlanOverride Function() _override;
  final DateTime Function() _now;
  final _changes = StreamController<PlanState>.broadcast();
  late final StreamSubscription<EntitlementLimits> _configSub;

  EntitlementAccount? _account;
  TrialRecord? _trial;
  CachedPlus? _cached;
  late PlanState _current;

  @override
  PlanState get current => _current;

  @override
  Stream<PlanState> get changes => _changes.stream;

  @override
  EntitlementLimits get limits => _config.current;

  /// Akun yang sedang masuk, atau `null`.
  EntitlementAccount? get account => _account;

  /// Mengganti akun yang masuk (dari status masuk akun). Sesudah Plus
  /// diluncurkan, akun yang belum punya uji coba langsung dimulai uji cobanya
  /// (ADR-041 §3.4).
  Future<void> setAccount(EntitlementAccount? account) async {
    _account = account;
    _trial = null;
    await _recompute();
  }

  /// Memuat ulang cache hak RevenueCat; dipanggil sesudah adaptor menulisnya.
  Future<void> reloadCache() => _recompute();

  /// Menghitung ulang keadaan, mis. sesudah pengganti uji berubah.
  Future<void> recompute() => _recompute();

  @override
  bool can(PlusFeature feature) => _current.isPlus;

  @override
  bool allows(PlusFeature feature, {required int count}) =>
      _current.isPlus || count < limits.freeAllowance(feature);

  @override
  Future<QuotaStatus> quota(PlusFeature feature) async {
    final (scope, bucket, limit) = _quotaFor(feature);
    if (limit == null) return QuotaStatus.unlimited;
    final used = (await _quotas.used(scope, bucket, feature)).fold((f) {
      developer.log('Jatah gagal dibaca', error: f, name: 'Entitlements');
      return 0;
    }, (used) => used);
    return QuotaStatus(used: used, limit: limit);
  }

  @override
  Future<bool> tryUse(PlusFeature feature) async {
    final status = await quota(feature);
    if (status.exhausted) {
      if (!_current.isPlus) AppAnalytics.log(PremiumEvents.tasteQuotaExhausted(feature: feature.name));
      return false;
    }
    if (_current.isPlus) AppAnalytics.log(PremiumEvents.plusFeatureUsed(feature: feature.name));
    if (status.limit == null) return true;
    final (scope, bucket, _) = _quotaFor(feature);
    final added = await _quotas.add(scope, bucket, feature, 1);
    // Gagal menyimpan pemakaian tidak menghalangi pengguna.
    if (added.isLeft()) {
      developer.log('Jatah gagal disimpan', name: 'Entitlements');
    }
    return true;
  }

  @override
  Future<void> refund(PlusFeature feature) async {
    final (scope, bucket, limit) = _quotaFor(feature);
    if (limit == null) return;
    await _quotas.add(scope, bucket, feature, -1);
  }

  @override
  Future<void> refresh() async {
    await _config.refresh();
    await _recompute();
  }

  /// Satuan, ember, dan batas jatah [feature] untuk paket sekarang.
  (QuotaScope, DateTime, int?) _quotaFor(PlusFeature feature) {
    final now = _now();
    if (_current.isPlus) {
      return (
        QuotaScope.plusMonth,
        DateTime(now.year, now.month),
        limits.fairUse(feature),
      );
    }
    return (
      QuotaScope.freePeriod,
      financialPeriodOf(now, _schedule()).start,
      limits.freeAllowance(feature),
    );
  }

  Future<void> _recompute() async {
    final account = _account;
    _cached = (await _cache.load()).fold((f) {
      developer.log('Cache hak gagal dibaca', error: f, name: 'Entitlements');
      return _cached;
    }, (cached) => cached);
    if (account != null) {
      _trial =
          (await _trials.recordFor(account.uid)).getOrElse((_) => null) ??
          await _startTrial(account);
    }
    final next = _resolve();
    if (next == _current) return;
    _current = next;
    _changes.add(next);
  }

  /// Memulai uji coba [account] bila Plus sudah diluncurkan dan akun belum
  /// punya uji coba (ADR-041 §3.4); `null` bila belum boleh.
  Future<TrialRecord?> _startTrial(EntitlementAccount account) async {
    final launchAt = limits.plusLaunchAt;
    final now = _now();
    if (launchAt == null || now.isBefore(launchAt)) return null;
    final createdAt = account.createdAt;
    final isNewAccount =
        createdAt != null &&
        !createdAt.isBefore(
          DateTime(launchAt.year, launchAt.month, launchAt.day),
        );
    final firstSeen = isNewAccount
        ? null
        : (await _trials.markFirstSeen(
            account.uid,
            now,
          )).getOrElse((_) => DateTime(now.year, now.month, now.day));
    final start = trialAnchor(
      launchAt: launchAt,
      accountCreatedAt: createdAt,
      firstSeenLocal: firstSeen,
    );
    if (start == null) return null;
    final record = TrialRecord(
      uid: account.uid,
      start: start,
      endsOn: trialEndsOn(start, _schedule(), minDays: limits.trialMinDays),
    );
    final saved = (await _trials.save(record)).getOrElse((_) => record);
    // Hanya uji coba yang baru dibuat; yang sudah ada dikembalikan apa adanya.
    if (saved == record) {
      AppAnalytics.log(PremiumEvents.trialStarted(days: record.endsOn.difference(record.start).inDays + 1));
    }
    return saved;
  }

  PlanState _resolve() => resolvePlan(
    now: _now(),
    launchAt: limits.plusLaunchAt,
    signedInUid: _account?.uid,
    trial: _trial,
    cached: _cached,
    override: _override(),
  );

  /// Melepas langganan; dipakai uji dan boot ulang.
  Future<void> dispose() async {
    await _configSub.cancel();
    await _changes.close();
  }
}
