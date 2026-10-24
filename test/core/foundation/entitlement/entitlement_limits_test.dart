import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';

/// Batas dari Remote Config dengan bawaan lokal (ADR-041 §3.6).
void main() {
  test('tanpa nilai: sama dengan bawaan; pra-peluncuran', () {
    final limits = EntitlementLimits.fromValues(const {});
    expect(limits, EntitlementLimits.defaults);
    expect(limits.plusLaunchAt, isNull);
  });

  test('nilai sah dipakai', () {
    final limits = EntitlementLimits.fromValues(const {
      'free_smart_interpretations': '40',
      'free_projects': '3',
      'trial_min_days': '10',
      'plus_launch_at': '2026-12-01T10:00:00+07:00',
      'founder_until': '2027-03-01',
    });
    expect(limits.freeSmartInterpretations, 40);
    expect(limits.freeProjects, 3);
    expect(limits.trialMinDays, 10);
    expect(limits.plusLaunchAt, DateTime.parse('2026-12-01T10:00:00+07:00'));
    expect(limits.founderUntil, DateTime(2027, 3));
  });

  test('nilai tidak sah memakai bawaan, tidak pernah nol karena galat', () {
    final limits = EntitlementLimits.fromValues(const {
      'free_smart_interpretations': '-1',
      'free_projects': 'dua',
      'taste_ask': '2.5',
      'free_budget_templates': '',
      'plus_launch_at': 'besok',
    });
    expect(limits.freeSmartInterpretations, 30);
    expect(limits.freeProjects, 2);
    expect(limits.tasteAsk, 3);
    expect(limits.freeBudgetTemplates, 1);
    expect(limits.plusLaunchAt, isNull);
  });

  test('nol yang sengaja dari server dihormati', () {
    expect(
      EntitlementLimits.fromValues(const {'taste_guardian': '0'}).tasteGuardian,
      0,
    );
  });

  test('jatah Gratis per fitur; otomasi tidak tersedia di Gratis', () {
    const d = EntitlementLimits.defaults;
    expect(d.freeAllowance(PlusFeature.notificationSources), 1);
    expect(d.freeAllowance(PlusFeature.smartInterpretation), 30);
    expect(d.freeAllowance(PlusFeature.analysisHistory), 6);
    expect(d.freeAllowance(PlusFeature.budgetTemplates), 1);
    expect(d.freeAllowance(PlusFeature.freelanceProjects), 2);
    expect(d.freeAllowance(PlusFeature.recurringAutomation), 0);
    expect(d.freeAllowance(PlusFeature.notificationAutoRecord), 0);
    expect(d.fairUse(PlusFeature.smartInterpretation), 1000);
    expect(d.fairUse(PlusFeature.budgetTemplates), isNull);
  });

  test('setiap kunci yang dibaca terdaftar di keys', () {
    expect(EntitlementLimits.keys, hasLength(16));
  });
}
