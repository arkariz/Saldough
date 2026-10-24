import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/core/tutorial/onboarding_step.dart';
import 'package:saldough/core/tutorial/tutorial_progress_repository_impl.dart';
import 'package:saldough/features/premium/data/entitlement_cache_store.dart';
import 'package:saldough/features/premium/data/local_entitlements.dart';
import 'package:saldough/features/premium/data/local_trial_gift.dart';
import 'package:saldough/features/premium/data/quota_store.dart';
import 'package:saldough/features/premium/data/trial_store.dart';

final class _Config implements EntitlementConfig {
  @override
  EntitlementLimits current = EntitlementLimits.fromValues(const {'plus_launch_at': '2026-11-01'});

  @override
  Stream<EntitlementLimits> get changes => const Stream.empty();

  @override
  Future<void> refresh() async {}
}

/// Hadiah uji coba (D-1): kapan tampil, tanggal gajian, dan akhir uji coba.
void main() {
  late InMemoryKeyValueStorage storage;
  late LocalEntitlements entitlements;
  late LocalTrialGift gift;
  late FinancialMonthPreferenceRepositoryImpl preferences;
  final now = DateTime(2026, 11, 3, 9);

  setUp(() async {
    ActiveFinancialMonth.notifier.value = FinancialMonthSchedule.initial;
    addTearDown(() => ActiveFinancialMonth.notifier.value = FinancialMonthSchedule.initial);
    storage = InMemoryKeyValueStorage();
    preferences = FinancialMonthPreferenceRepositoryImpl(storage: storage);
    entitlements = LocalEntitlements(
      config: _Config(),
      trials: TrialStore(storage: storage),
      cache: EntitlementCacheStore(storage: storage),
      quotas: QuotaStore(storage: storage),
      schedule: () => ActiveFinancialMonth.schedule,
      now: () => now,
    );
    addTearDown(entitlements.dispose);
    gift = LocalTrialGift(
      entitlements: entitlements,
      trials: TrialStore(storage: storage),
      preferences: preferences,
      progress: TutorialProgressRepositoryImpl(storage: storage),
      now: () => now,
    );
  });

  test('tanpa akun atau tanpa uji coba: tidak ada hadiah', () async {
    expect(await gift.pending(), isNull);
  });

  test('sudah menjawab gajian di onboarding: tidak ditanya lagi', () async {
    await TutorialProgressRepositoryImpl(storage: storage).markOnboardingStepAnswered(OnboardingStep.period);
    await entitlements.setAccount(EntitlementAccount(uid: 'u1', createdAt: DateTime(2026, 11, 2)));
    expect((await gift.pending())!.needsPayday, isFalse);
  });

  test('uji coba baru: hadiah menunggu dan menanyakan gajian; ditandai tampil = tidak muncul lagi', () async {
    await entitlements.setAccount(EntitlementAccount(uid: 'u1', createdAt: DateTime(2026, 11, 2)));
    final info = await gift.pending();
    expect(info, isNotNull);
    expect(info!.needsPayday, isTrue);
    expect(info.start, DateTime(2026, 11, 2));
    await gift.markSeen();
    expect(await gift.pending(), isNull);
  });

  test('setPayday menyimpan jadwal, menandai diubah pengguna, dan menghitung ulang akhir uji coba', () async {
    await entitlements.setAccount(EntitlementAccount(uid: 'u1', createdAt: DateTime(2026, 11, 2)));
    final before = (await gift.pending())!.endsOn;
    final endsOn = await gift.setPayday(const FinancialMonthStart.day(25));
    expect(endsOn, isNotNull);
    expect(endsOn, isNot(before));
    expect(ActiveFinancialMonth.schedule.active, const FinancialMonthStart.day(25));
    expect(entitlements.current, TrialPlan(endsOn: endsOn!));
    expect((await preferences.loadOffer()).getOrElse((_) => throw StateError('x')).changedByUser, isTrue);
    final again = await gift.pending();
    expect(again!.needsPayday, isFalse, reason: 'sudah memilih gajian');
    expect(again.endsOn, endsOn);
  });

  test('sesudah hadiah ditampilkan tanggal akhir tidak bergeser lagi', () async {
    await entitlements.setAccount(EntitlementAccount(uid: 'u1', createdAt: DateTime(2026, 11, 2)));
    final before = (await gift.pending())!.endsOn;
    await gift.markSeen();
    final endsOn = await gift.setPayday(const FinancialMonthStart.day(25));
    expect(endsOn, before);
  });
}
