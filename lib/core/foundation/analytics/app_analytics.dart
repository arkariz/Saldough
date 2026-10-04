import 'dart:async';

import 'package:dependencies/dependencies.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Satu peristiwa analitik kustom (ADR-023). Parameternya tidak pernah
/// memuat nominal, nama, atau teks pengguna.
final class AnalyticsEvent extends Equatable {
  /// Membuat [AnalyticsEvent].
  const AnalyticsEvent(this.name, [this.parameters = const {}]);

  /// Nama `snake_case`.
  final String name;

  /// Parameter String atau angka.
  final Map<String, Object> parameters;

  @override
  List<Object?> get props => [name, parameters];
}

/// Pintu tunggal peristiwa analitik kustom. Diam bila Firebase belum
/// terinisialisasi (offline sejak pertama dibuka) dan tidak pernah
/// mengganggu alur pengguna.
abstract final class AppAnalytics {
  AppAnalytics._();

  /// Penampung pengganti untuk uji; `null` = Firebase.
  @visibleForTesting
  static void Function(AnalyticsEvent event)? debugSink;

  /// Mengirim [event].
  static void log(AnalyticsEvent event) {
    if (debugSink case final sink?) return sink(event);
    unawaited(_send(event));
  }

  static Future<void> _send(AnalyticsEvent event) async {
    try {
      if (Firebase.apps.isEmpty) return;
      await FirebaseAnalytics.instance.logEvent(name: event.name, parameters: event.parameters);
    } on Object {
      // Analitik tidak boleh menggagalkan apa pun.
    }
  }
}

/// Peristiwa Rencana R2 (ADR-036 §3.8), tanpa nominal.
abstract final class PlanEvents {
  PlanEvents._();

  /// Sakelar Ulangi tiap periode di formulir anggaran.
  static AnalyticsEvent budgetRepeatToggled({required bool on}) =>
      AnalyticsEvent('budget_repeat_toggled', {'on': on ? 'true' : 'false'});

  /// Periode anggaran rutin lahir sendiri.
  static AnalyticsEvent budgetPeriodBorn({required int count}) =>
      AnalyticsEvent('budget_period_born', {'count': count});

  /// Lingkup yang dipilih di dialog sunting anggaran rutin.
  static AnalyticsEvent budgetEditScope(String scope) => AnalyticsEvent('budget_edit_scope', {'scope': scope});

  /// Rutin ditautkan ke pos anggaran: `suggestion` (saran E9) atau `detail`.
  static AnalyticsEvent recurringBudgetLinked(String source) =>
      AnalyticsEvent('recurring_budget_linked', {'source': source});

  /// Bulan ini dilihat: 0 = bulan berjalan, 1–2 = ke depan.
  static AnalyticsEvent planViewed(int monthOffset) => AnalyticsEvent('plan_viewed', {'month_offset': monthOffset});

  /// Banner siapkan dana tampil.
  static const fundingWarningShown = AnalyticsEvent('funding_warning_shown');

  /// Catat otomatis rutin (ADR-037 §3.5): jumlahnya saja.
  static AnalyticsEvent autoRecorded(int count) => AnalyticsEvent('auto_recorded', {'count': count});

  /// Catat otomatis dibatalkan.
  static const autoRecordUndone = AnalyticsEvent('auto_record_undone');

  /// "Selesai meninjau" dengan jumlah langkah tercentang.
  static AnalyticsEvent monthReviewCompleted(int stepsDone) =>
      AnalyticsEvent('month_review_completed', {'steps_done': stepsDone});
}
