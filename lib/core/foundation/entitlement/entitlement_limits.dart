import 'package:dependencies/dependencies.dart';
import 'package:saldough/core/foundation/entitlement/plus_feature.dart';

/// Batas, jatah, dan jendela penawaran Plus (ADR-041 §3.6). Nilai dari Remote
/// Config; [defaults] dipakai bila server tidak terjangkau atau nilainya tidak
/// sah, sehingga batas tidak pernah nol atau tak terbatas karena galat.
final class EntitlementLimits extends Equatable {
  /// Membuat [EntitlementLimits].
  const EntitlementLimits({
    required this.freeNotificationSources,
    required this.freeSmartInterpretations,
    required this.tasteAsk,
    required this.tasteGuardian,
    required this.freeAnalysisPeriods,
    required this.freeBudgetTemplates,
    required this.freeProjects,
    required this.fairUseInterpretations,
    required this.fairUsePhoto,
    required this.fairUseAsk,
    required this.paywallMaxPerDay,
    required this.paywallMaxPerPeriod,
    required this.trialMinDays,
    required this.postTrialOfferHours,
    this.plusLaunchAt,
    this.founderUntil,
  });

  /// Membaca [values] (nama parameter → string). Nilai yang hilang, bukan
  /// angka bulat, atau negatif diganti bawaannya; tanggal yang tidak sah
  /// dianggap kosong.
  factory EntitlementLimits.fromValues(Map<String, String> values) {
    const d = defaults;
    int count(String key, int fallback) {
      final parsed = int.tryParse(values[key]?.trim() ?? '');
      return parsed == null || parsed < 0 ? fallback : parsed;
    }

    DateTime? date(String key) {
      final raw = values[key]?.trim() ?? '';
      return raw.isEmpty ? null : DateTime.tryParse(raw);
    }

    return EntitlementLimits(
      freeNotificationSources: count(
        'free_notification_sources',
        d.freeNotificationSources,
      ),
      freeSmartInterpretations: count(
        'free_smart_interpretations',
        d.freeSmartInterpretations,
      ),
      tasteAsk: count('taste_ask', d.tasteAsk),
      tasteGuardian: count('taste_guardian', d.tasteGuardian),
      freeAnalysisPeriods: count(
        'free_analysis_periods',
        d.freeAnalysisPeriods,
      ),
      freeBudgetTemplates: count(
        'free_budget_templates',
        d.freeBudgetTemplates,
      ),
      freeProjects: count('free_projects', d.freeProjects),
      fairUseInterpretations: count(
        'plus_fair_use_interpretations',
        d.fairUseInterpretations,
      ),
      fairUsePhoto: count('plus_fair_use_photo', d.fairUsePhoto),
      fairUseAsk: count('plus_fair_use_ask', d.fairUseAsk),
      paywallMaxPerDay: count('paywall_max_per_day', d.paywallMaxPerDay),
      paywallMaxPerPeriod: count(
        'paywall_max_per_period',
        d.paywallMaxPerPeriod,
      ),
      trialMinDays: count('trial_min_days', d.trialMinDays),
      postTrialOfferHours: count(
        'post_trial_offer_hours',
        d.postTrialOfferHours,
      ),
      plusLaunchAt: date('plus_launch_at'),
      founderUntil: date('founder_until'),
    );
  }

  /// Nilai bawaan lokal (ADR-041 §3.6).
  static const defaults = EntitlementLimits(
    freeNotificationSources: 1,
    freeSmartInterpretations: 30,
    tasteAsk: 3,
    tasteGuardian: 1,
    freeAnalysisPeriods: 6,
    freeBudgetTemplates: 1,
    freeProjects: 2,
    fairUseInterpretations: 1000,
    fairUsePhoto: 150,
    fairUseAsk: 300,
    paywallMaxPerDay: 1,
    paywallMaxPerPeriod: 3,
    trialMinDays: 14,
    postTrialOfferHours: 48,
  );

  /// Nama parameter Remote Config, dipakai adaptor untuk memfilter.
  static const keys = {
    'free_notification_sources',
    'free_smart_interpretations',
    'taste_ask',
    'taste_guardian',
    'free_analysis_periods',
    'free_budget_templates',
    'free_projects',
    'plus_fair_use_interpretations',
    'plus_fair_use_photo',
    'plus_fair_use_ask',
    'paywall_max_per_day',
    'paywall_max_per_period',
    'trial_min_days',
    'post_trial_offer_hours',
    'plus_launch_at',
    'founder_until',
  };

  /// Aplikasi sumber notifikasi di Gratis.
  final int freeNotificationSources;

  /// Tafsir cerdas per periode di Gratis, termasuk foto struk (KT-P14).
  final int freeSmartInterpretations;

  /// Jatah cicip Tanya Tanuki per periode.
  final int tasteAsk;

  /// Jatah cicip Penjaga per periode.
  final int tasteGuardian;

  /// Periode Analisis di Gratis.
  final int freeAnalysisPeriods;

  /// Template anggaran di Gratis (semua template dihitung).
  final int freeBudgetTemplates;

  /// Proyek freelance di Gratis (semua proyek dihitung, ADR-041 §3.13).
  final int freeProjects;

  /// Batas wajar tafsir cerdas per bulan untuk Plus (tidak ditampilkan).
  final int fairUseInterpretations;

  /// Batas wajar foto struk per bulan untuk Plus.
  final int fairUsePhoto;

  /// Batas wajar Tanya Tanuki per bulan untuk Plus.
  final int fairUseAsk;

  /// Paywall kontekstual paling banyak per hari.
  final int paywallMaxPerDay;

  /// Paywall kontekstual paling banyak per periode.
  final int paywallMaxPerPeriod;

  /// Sisa hari minimum periode berjalan untuk uji coba (§8.1).
  final int trialMinDays;

  /// Lama penawaran sesudah uji coba, dalam jam.
  final int postTrialOfferHours;

  /// Saat Plus mulai dijual; `null` = pra-peluncuran (§3.13).
  final DateTime? plusLaunchAt;

  /// Akhir jendela Harga Pendiri.
  final DateTime? founderUntil;

  /// Jatah [feature] per periode di Gratis; `0` = tidak tersedia di Gratis.
  int freeAllowance(PlusFeature feature) => switch (feature) {
    PlusFeature.notificationSources => freeNotificationSources,
    PlusFeature.smartInterpretation => freeSmartInterpretations,
    PlusFeature.analysisHistory => freeAnalysisPeriods,
    PlusFeature.budgetTemplates => freeBudgetTemplates,
    PlusFeature.freelanceProjects => freeProjects,
    PlusFeature.ask => tasteAsk,
    PlusFeature.guardian => tasteGuardian,
    PlusFeature.notificationAutoRecord || PlusFeature.recurringAutomation => 0,
  };

  /// Batas wajar bulanan [feature] untuk Plus, atau `null` bila tidak ada.
  int? fairUse(PlusFeature feature) => switch (feature) {
    PlusFeature.smartInterpretation => fairUseInterpretations,
    PlusFeature.ask => fairUseAsk,
    _ => null,
  };

  @override
  List<Object?> get props => [
    freeNotificationSources,
    freeSmartInterpretations,
    tasteAsk,
    tasteGuardian,
    freeAnalysisPeriods,
    freeBudgetTemplates,
    freeProjects,
    fairUseInterpretations,
    fairUsePhoto,
    fairUseAsk,
    paywallMaxPerDay,
    paywallMaxPerPeriod,
    trialMinDays,
    postTrialOfferHours,
    plusLaunchAt,
    founderUntil,
  ];
}
