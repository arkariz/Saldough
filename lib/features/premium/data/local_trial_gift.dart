import 'dart:developer' as developer;

import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/core/tutorial/onboarding_step.dart';
import 'package:saldough/core/tutorial/tutorial_progress.dart';
import 'package:saldough/core/tutorial/tutorial_progress_repository.dart';
import 'package:saldough/features/premium/data/local_entitlements.dart';
import 'package:saldough/features/premium/data/trial_store.dart';
import 'package:saldough/features/premium/domain/trial_gift.dart';

/// [TrialGift] di atas hak lokal, rekaman uji coba, dan preferensi periode.
///
/// Menyimpan tanggal gajian seperti onboarding menyimpannya tetapi lewat
/// `changedOn`, jadi periode berjalan menjadi periode peralihan; anggaran
/// berulang tidak dipindahkan (itu hanya lewat lembar Awal bulan keuangan).
final class LocalTrialGift implements TrialGift {
  /// Membuat [LocalTrialGift]; [now] untuk uji.
  LocalTrialGift({
    required this.entitlements,
    required this.trials,
    required this.preferences,
    required this.progress,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// Hak lokal (akun, uji coba berjalan).
  final LocalEntitlements entitlements;

  /// Rekaman uji coba.
  final TrialStore trials;

  /// Preferensi periode keuangan.
  final FinancialMonthPreferenceRepository preferences;

  /// Kemajuan onboarding (langkah periode).
  final TutorialProgressRepository progress;

  final DateTime Function() _now;

  @override
  Future<TrialGiftInfo?> pending() async {
    final account = entitlements.account;
    final plan = entitlements.current;
    if (account == null || plan is! TrialPlan) return null;
    if ((await trials.giftSeen(account.uid)).getOrElse((_) => true)) return null;
    final record = (await trials.recordFor(account.uid)).getOrElse((_) => null);
    if (record == null) return null;
    final offer = (await preferences.loadOffer()).getOrElse(
      (_) => (changedByUser: true, offeredRuleIds: const <String>{}, paydayCardAnswered: false),
    );
    final tutorial = (await progress.load()).getOrElse((_) => TutorialProgress.empty);
    // Onboarding mencatat jawaban gajian per langkah, tanpa menandai `changedByUser`.
    final answeredInOnboarding = tutorial.answeredSteps.contains(OnboardingStep.period);
    return TrialGiftInfo(
      start: record.start,
      endsOn: record.endsOn,
      needsPayday: !offer.changedByUser && !answeredInOnboarding,
      minDays: entitlements.limits.trialMinDays,
    );
  }

  @override
  Future<DateTime?> setPayday(FinancialMonthStart start) async {
    try {
      final updated = ActiveFinancialMonth.schedule.changedOn(_now(), start);
      if ((await preferences.save(updated)).isLeft()) return null;
      final offer = (await preferences.loadOffer()).getOrElse(
        (_) => (changedByUser: false, offeredRuleIds: const <String>{}, paydayCardAnswered: false),
      );
      await preferences.saveOffer((
        changedByUser: true,
        offeredRuleIds: offer.offeredRuleIds,
        paydayCardAnswered: offer.paydayCardAnswered,
      ));
      ActiveFinancialMonth.notifier.value = updated;
      return await entitlements.reanchorTrial();
    } on Object catch (e) {
      developer.log('Tanggal gajian gagal disimpan', error: e, name: 'TrialGift');
      return null;
    }
  }

  @override
  Future<void> markSeen() async {
    final account = entitlements.account;
    if (account != null) await trials.markGiftSeen(account.uid);
  }
}
