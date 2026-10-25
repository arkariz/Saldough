import 'package:saldough/core/financial_month/financial_period.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/features/premium/data/local_entitlements.dart';
import 'package:saldough/features/premium/data/trial_store.dart';
import 'package:saldough/features/premium/domain/offering_policy.dart';
import 'package:saldough/features/premium/domain/plus_moments.dart';
import 'package:saldough/features/premium/domain/plus_purchasing.dart';

/// Berapa hari sebelum uji coba berakhir rekap nilai tampil (H-3).
const recapDaysBefore = 3;

/// [PlusMoments] di atas hak lokal, rekaman uji coba, dan pemakaian lokal
/// (FREEMIUM_PAYWALL §8.2). Tidak pernah melempar: bacaan yang gagal berarti
/// tidak ada momen.
final class LocalPlusMoments implements PlusMoments {
  /// Membuat [LocalPlusMoments]; [now] untuk uji.
  LocalPlusMoments({
    required this.entitlements,
    required this.trials,
    required this.usage,
    required this.purchasing,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// Hak lokal.
  final LocalEntitlements entitlements;

  /// Rekaman uji coba dan penanda momen.
  final TrialStore trials;

  /// Pemakaian lokal.
  final PlusUsage usage;

  /// Penawaran sesudah uji coba.
  final PlusPurchasing purchasing;

  final DateTime Function() _now;

  DateTime get _today {
    final n = _now();
    return DateTime(n.year, n.month, n.day);
  }

  String get _uid => entitlements.account?.uid ?? deviceMarkKey;

  Future<Set<String>> _marks() async => (await trials.marks(_uid)).getOrElse((_) => const {});

  @override
  Future<PlusCard?> card() async {
    final plan = entitlements.current;
    final marks = await _marks();
    if (plan is TrialPlan) {
      final account = entitlements.account;
      if (account == null || marks.contains('recap')) return null;
      final record = (await trials.recordFor(account.uid)).getOrElse((_) => null);
      if (record == null) return null;
      final left = record.endsOn.difference(_today).inDays;
      if (left < 0 || left > recapDaysBefore) return null;
      final card = PlusRecapCard(
        start: record.start,
        endsOn: record.endsOn,
        recorded: await usage.autoRecordedSince(record.start),
      );
      if (!marks.contains('recap_logged')) {
        await trials.addMark(account.uid, 'recap_logged');
        AppAnalytics.log(PremiumEvents.trialValueRecapShown);
      }
      return card;
    }
    if (plan.isPlus) return null;
    final status = await entitlements.quota(PlusFeature.smartInterpretation);
    final limit = status.limit;
    if (limit == null || !status.exhausted) return null;
    final period = financialPeriodOf(_now(), ActiveFinancialMonth.schedule);
    final card = PlusContextCard(limit: limit, periodKey: period.start.toIso8601String().substring(0, 10));
    return marks.contains(card.dismissKey) ? null : card;
  }

  @override
  Future<void> dismiss(PlusCard card) async {
    await trials.addMark(_uid, card.dismissKey);
  }

  @override
  Future<PlusDowngrade?> downgrade() async {
    final account = entitlements.account;
    if (account == null) return null;
    final record = (await trials.recordFor(account.uid)).getOrElse((_) => null);
    if (record == null || !_today.isAfter(record.endsOn)) return null;
    final marks = await _marks();
    if (marks.contains('downgrade')) return null;
    final plan = entitlements.current;
    if (plan is PlusPlan) {
      // Uji coba berakhir sementara Plus tetap berlaku (dibeli): hanya dicatat.
      if (plan.source == PlanSource.purchase) {
        await trials.addMark(account.uid, 'downgrade');
        AppAnalytics.log(PremiumEvents.trialEnded(outcome: 'purchased'));
      }
      return null;
    }
    final offered = purchasing.isSelling ? await purchasing.offered() : null;
    return PlusDowngrade(
      sources: await usage.notificationSources(),
      autoRules: await usage.autoRecordRules(),
      freePeriods: entitlements.limits.freeAnalysisPeriods,
      offer: offered?.offering == OfferingId.postTrial ? offered : null,
    );
  }

  @override
  Future<void> markDowngradeShown() async {
    final account = entitlements.account;
    if (account == null) return;
    await trials.addMark(account.uid, 'downgrade');
    AppAnalytics.log(PremiumEvents.trialEnded(outcome: 'lapsed'));
  }
}
