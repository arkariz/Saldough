import 'dart:async';

import 'package:dependencies/dependencies.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
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

  /// Penampung pengganti untuk uji properti pengguna; `null` = Firebase.
  @visibleForTesting
  static void Function(String name, String value)? debugUserPropertySink;

  /// Penampung pengganti untuk uji kunci diagnostik; `null` = Crashlytics.
  @visibleForTesting
  static void Function(String key, Object value)? debugDiagnosticSink;

  /// Memasang properti pengguna Analytics ([name] `snake_case`, [value]
  /// String); diam bila Firebase belum siap.
  static void setUserProperty(String name, String value) {
    if (debugUserPropertySink case final sink?) return sink(name, value);
    unawaited(_setUserProperty(name, value));
  }

  /// Memasang kunci kustom Crashlytics supaya laporan galat bisa dipilah
  /// (mis. nomor pembaruan kecil); diam bila Firebase belum siap.
  static void setDiagnostic(String key, Object value) {
    if (debugDiagnosticSink case final sink?) return sink(key, value);
    unawaited(_setDiagnostic(key, value));
  }

  /// Mengirim [event].
  static void log(AnalyticsEvent event) {
    if (debugSink case final sink?) return sink(event);
    unawaited(_send(event));
  }

  static Future<void> _setUserProperty(String name, String value) async {
    try {
      if (Firebase.apps.isEmpty) return;
      await FirebaseAnalytics.instance.setUserProperty(name: name, value: value);
    } on Object {
      // Analitik tidak boleh menggagalkan apa pun.
    }
  }

  static Future<void> _setDiagnostic(String key, Object value) async {
    try {
      if (Firebase.apps.isEmpty) return;
      await FirebaseCrashlytics.instance.setCustomKey(key, value);
    } on Object {
      // Diagnostik tidak boleh menggagalkan apa pun.
    }
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

/// Peristiwa rutin R1 (ADR-035 §7) dan R3 (ADR-037 §3.5), tanpa nominal.
abstract final class RecurringEvents {
  RecurringEvents._();

  /// Rutin dibuat: `record` (Ulangi di CATAT) atau `make_recurring`.
  static AnalyticsEvent created(String source) => AnalyticsEvent('recurring_created', {'source': source});

  /// Kemunculan dicatat: `one_tap` atau `record_all`.
  static AnalyticsEvent occurrenceRecorded(String method, {int count = 1}) =>
      AnalyticsEvent('occurrence_recorded', {'method': method, 'count': count});

  /// Kemunculan dilewati.
  static const occurrenceSkipped = AnalyticsEvent('occurrence_skipped');

  /// Kemunculan ditautkan ke transaksi yang ada, oleh pengguna.
  static const occurrenceLinked = AnalyticsEvent('occurrence_linked', {'by': 'user'});

  /// Kemunculan ditautkan otomatis dari catat notifikasi.
  static const occurrenceLinkedAuto = AnalyticsEvent('occurrence_linked', {'by': 'auto'});

  /// Tautan otomatis dilepas pengguna.
  static const occurrenceUnlinked = AnalyticsEvent('occurrence_unlinked');

  /// "Belum terjadi" pada autodebet belum terlihat (E3).
  static const unseenNotYet = AnalyticsEvent('occurrence_unseen_action', {'action': 'not_yet'});

  /// Kartu rutin menganggur (W6): `keep`, `pause`, `end`.
  static AnalyticsEvent idleAction(String action) => AnalyticsEvent('recurring_idle_action', {'action': action});

  /// Sakelar catat otomatis: `form` atau `detail`.
  static AnalyticsEvent autoRecordToggled({required bool on, required String where}) =>
      AnalyticsEvent('auto_record_toggled', {'on': on ? 'true' : 'false', 'where': where});

  /// Kenaikan harga dari notifikasi (W3): `update` atau `keep`.
  static AnalyticsEvent priceIncreaseAction(String action) =>
      AnalyticsEvent('price_increase_action', {'action': action});

  /// Saran Sepertinya rutin: `accept` atau `dismiss`.
  static AnalyticsEvent suggestionAction(String action) =>
      AnalyticsEvent('recurring_suggestion_action', {'action': action});
}

/// Peristiwa periode keuangan (FINANCIAL_PERIOD §8A, ADR-038), tanpa nominal
/// dan tanpa tanggal.
abstract final class PeriodEvents {
  PeriodEvents._();

  /// Lembar Awal bulan keuangan terbuka: `plan`, `account`, atau `offer`.
  static AnalyticsEvent sheetOpened(String source) =>
      AnalyticsEvent('financial_month_sheet_opened', {'source': source});

  /// Awal bulan keuangan tersimpan. [day] `1`…`28` atau `last`;
  /// [transitionDays] 0 bila periode berjalan tidak menjadi peralihan.
  static AnalyticsEvent changed({
    required String source,
    required String day,
    required int transitionDays,
    required int movedBudgets,
    required int keptBudgets,
  }) => AnalyticsEvent('financial_month_changed', {
    'source': source,
    'day': day,
    'transition_days': transitionDays,
    'moved_budgets': movedBudgets,
    'kept_budgets': keptBudgets,
  });

  /// Tawaran awal bulan dari rutin gajian (F2): `shown`, `accepted`, atau
  /// `dismissed`.
  static AnalyticsEvent offer(String action) => AnalyticsEvent('financial_month_offer', {'action': action});

  /// Transaksi ditautkan ke kemunculan rutin, oleh pengguna atau otomatis:
  /// selisih hari kalender antara [transactionDate] dan [occurrenceDate]
  /// sebagai ember, bukan tanggalnya (batas atribusi P-4). [via] jalurnya
  /// (`edit`, `link`, `auto`, `one_tap`, `record_all`), supaya nol yang
  /// dibuat sistem bisa dipisahkan dari sebaran yang diukur (T-18.19).
  static AnalyticsEvent recurrenceDateGap(DateTime transactionDate, DateTime occurrenceDate, {required String via}) =>
      AnalyticsEvent('recurrence_date_gap', {'bucket': gapBucket(transactionDate, occurrenceDate), 'via': via});

  /// `0`, `1-3`, `4-7`, `8-14`, atau `15+` hari, ke arah mana pun.
  static String gapBucket(DateTime a, DateTime b) {
    final days = DateTime.utc(a.year, a.month, a.day).difference(DateTime.utc(b.year, b.month, b.day)).inDays.abs();
    return switch (days) {
      0 => '0',
      <= 3 => '1-3',
      <= 7 => '4-7',
      <= 14 => '8-14',
      _ => '15+',
    };
  }
}

/// Peristiwa Analisis keuangan (FINANCIAL_ANALYSIS §13A, T-19.9). Tanpa
/// nominal dan tanpa nama kategori buatan pengguna (`custom`); dikirim dari
/// tindakan atau bloc, sekali per kejadian, tidak dari `build()`.
abstract final class AnalysisEvents {
  AnalysisEvents._();

  /// Layar Analisis terbuka: [source] `history`, `home`, atau `lookback`;
  /// [kind] `expense` atau `income`; [transition] periode peralihan.
  static AnalyticsEvent viewed({required String source, required String kind, required bool transition}) =>
      AnalyticsEvent('analysis_viewed', {'source': source, 'kind': kind, 'transition': transition ? 'true' : 'false'});

  /// Pindah periode: [via] `stepper` atau `trend` (tautan Lihat analisis).
  static AnalyticsEvent periodChanged(String via) => AnalyticsEvent('analysis_period_changed', {'via': via});

  /// Pindah Pengeluaran/Pemasukan.
  static AnalyticsEvent kindSwitched(String kind) => AnalyticsEvent('analysis_kind_switched', {'kind': kind});

  /// Penyaring dompet berubah: [filtered] `true` bila satu dompet.
  static AnalyticsEvent walletFiltered({required bool filtered}) =>
      AnalyticsEvent('analysis_wallet_filtered', {'filtered': filtered ? 'true' : 'false'});

  /// Sorotan yang tampil di periode yang dibuka (0…3), sekali per periode.
  static AnalyticsEvent highlightsShown(int count) => AnalyticsEvent('analysis_highlights_shown', {'count': count});

  /// Rincian kategori dibuka: [category] `<builtInKey>`, `custom`, `none`,
  /// `freelance`, atau `others`; [from] `link` atau `highlight`.
  static AnalyticsEvent categoryOpened({required String category, required String from}) =>
      AnalyticsEvent('analysis_category_opened', {'category': category, 'from': from});

  /// Lihat semua transaksi dari Rincian kategori.
  static const seeAllOpened = AnalyticsEvent('analysis_see_all_opened');

  /// Beri kategori diketuk dari Tanpa kategori.
  static const uncategorizedFixOpened = AnalyticsEvent('analysis_uncategorized_fix_opened');
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

  /// Segmen Rencana dibuka: `thisMonth`, `budget`, `recurring`.
  static AnalyticsEvent planSegmentViewed(String segment) => AnalyticsEvent('plan_viewed', {'segment': segment});

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

/// Peristiwa pengumuman pembaruan (APP_UPDATE §8, ADR-039), tanpa data
/// pribadi atau keuangan.
abstract final class UpdateEvents {
  UpdateEvents._();

  /// Nama properti pengguna dan kunci Crashlytics nomor pembaruan kecil
  /// yang berjalan (0 = tanpa tambalan).
  static const patchNumberKey = 'patch_number';

  /// Banner tampil (sekali per keadaan per sesi). [kind] `store` atau `patch`;
  /// [stage] `available`, `downloading`, `downloaded`, atau `ready`;
  /// [hasVersion] = chip versi ikut tampil (ukuran keandalan Remote Config).
  static AnalyticsEvent bannerShown({required String kind, required String stage, required bool hasVersion}) =>
      AnalyticsEvent('update_banner_shown', {
        'kind': kind,
        'stage': stage,
        'has_version': hasVersion ? 'true' : 'false',
      });

  /// Ketukan Perbarui / Pasang sekarang / Nanti (×) / Oke. [action] `update`,
  /// `install`, atau `dismiss`; [source] `home` atau `account`.
  static AnalyticsEvent bannerAction({required String kind, required String action, required String source}) =>
      AnalyticsEvent('update_banner_action', {'kind': kind, 'action': action, 'source': source});

  /// Pembukaan pertama sesudah versi berubah (bukan pemasangan pertama).
  static AnalyticsEvent appUpdated({
    required String kind,
    required int fromBuild,
    required int toBuild,
    required int toPatch,
  }) => AnalyticsEvent('app_updated', {
    'kind': kind,
    'from_build': fromBuild,
    'to_build': toBuild,
    'to_patch': toPatch,
  });

  /// Lembar atau daftar Apa yang baru dibuka; [source] `auto` atau `account`.
  static AnalyticsEvent whatsNewViewed({required int build, required int patch, required String source}) =>
      AnalyticsEvent('whats_new_viewed', {'build': build, 'patch': patch, 'source': source});
}

/// Peristiwa penemuan fitur (FEATURE_DISCOVERY §9, Fase 21): jawaban langkah
/// onboarding, fitur yang dinyalakan, dan pemakaian pintu permanen. Tanpa
/// nominal, nama kategori buatan, nama aplikasi, atau isi notifikasi
/// (ADR-023).
abstract final class DiscoveryEvents {
  DiscoveryEvents._();

  /// Langkah wajib onboarding dijawab. [step] `period` atau `reminder`;
  /// [choice] `confirmed` (Pakai tanggal), `turned_on`, atau `not_now`.
  static AnalyticsEvent stepAnswered({required String step, required String choice}) =>
      AnalyticsEvent('onboarding_step_answered', {'step': step, 'choice': choice});

  /// Fitur benar-benar menyala. [feature] `notification` atau `reminder`;
  /// [via] `onboarding`, `home_row`, `quick_start`, `account`, atau `rutin`.
  static AnalyticsEvent featureEnabled({required String feature, required String via}) =>
      AnalyticsEvent('feature_enabled', {'feature': feature, 'via': via});

  /// Kartu Kotak masuk notifikasi diketuk. [state] `unset`, `active`,
  /// `permission`, atau `off`; [surface] `home`, `inbox`, atau `account`;
  /// [action] `quick_start`, `manage`, atau `teach_pattern`.
  static AnalyticsEvent notificationRowTapped({
    required String state,
    required String surface,
    required String action,
  }) => AnalyticsEvent('notification_row_tapped', {'state': state, 'surface': surface, 'action': action});

  /// Mulai cepat selesai; hanya jumlah aplikasi, tanpa namanya.
  static AnalyticsEvent quickStartCompleted({required int appsCount}) =>
      AnalyticsEvent('quick_start_completed', {'apps_count': appsCount});

  /// Tombol permanen pengingat diketuk. [surface] `home`, `rutin_segment`,
  /// atau `rutin_detail`; [state] `off` atau `permission`.
  static AnalyticsEvent buttonTapped({required String feature, required String surface, required String state}) =>
      AnalyticsEvent('discovery_button_tapped', {'feature': feature, 'surface': surface, 'state': state});

  /// Kartu tawaran gajian: [action] `shown`, `accepted`, atau `closed`.
  static AnalyticsEvent paydayCard(String action) => AnalyticsEvent('discovery_payday_card', {'action': action});
}

/// Peristiwa ekspor, cadangan, dan pemulihan (EXPORT_BACKUP §12, Fase 22).
/// Hanya jenis dan ember jumlah baris; tanpa nominal, nama, atau isi data
/// (ADR-023).
abstract final class DataPortabilityEvents {
  DataPortabilityEvents._();

  /// Ember jumlah baris: `<100`, `<1000`, `<10000`, atau `10000+`.
  static String rowsBucket(int rows) => switch (rows) {
    < 100 => '<100',
    < 1000 => '<1000',
    < 10000 => '<10000',
    _ => '10000+',
  };

  /// Berkas ekspor sudah dibuat. [format] `xlsx` atau `csv`.
  static AnalyticsEvent exportCreated({required String format, required int rows}) =>
      AnalyticsEvent('export_created', {'format': format, 'rows_bucket': rowsBucket(rows)});

  /// Berkas cadangan dibuat; [saved] `true` bila penyimpanannya terkonfirmasi.
  static AnalyticsEvent backupCreated({required int rows, required bool saved}) =>
      AnalyticsEvent('backup_created', {'rows_bucket': rowsBucket(rows), 'saved': saved});

  /// Pemulihan dimulai (penggantian disiapkan). [surface] `account`,
  /// `onboarding`, atau `undo`.
  static AnalyticsEvent restoreStarted({required String surface}) =>
      AnalyticsEvent('restore_started', {'surface': surface});

  /// Pemulihan selesai dan data sudah diterapkan.
  static AnalyticsEvent restoreCompleted({required String surface}) =>
      AnalyticsEvent('restore_completed', {'surface': surface});

  /// Pemulihan gagal; [reason] `invalid`, `newer`, `inconsistent`, `space`,
  /// atau `other`.
  static AnalyticsEvent restoreFailed({required String surface, required String reason}) =>
      AnalyticsEvent('restore_failed', {'surface': surface, 'reason': reason});
}
