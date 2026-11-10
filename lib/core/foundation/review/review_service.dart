import 'dart:async';
import 'dart:developer' as developer;

import 'package:api_storage/api_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/foundation/review/review_thresholds.dart';

const _reviewKey = StorageKey(namespace: 'settings', name: 'review_prompt');

/// Pintu ke lembar ulasan Play (`in_app_review`); diganti saat uji.
abstract interface class ReviewGateway {
  /// Apakah lembar ulasan dalam aplikasi bisa diminta di perangkat ini.
  Future<bool> isAvailable();

  /// Meminta lembar ulasan. Selesai saat lembar ditutup, atau segera bila
  /// Play tidak menampilkannya (jatah habis).
  Future<void> requestReview();
}

/// [ReviewGateway] di atas `in_app_review`.
final class InAppReviewGateway implements ReviewGateway {
  /// Membuat [InAppReviewGateway].
  const InAppReviewGateway();

  @override
  Future<bool> isAvailable() => InAppReview.instance.isAvailable();

  @override
  Future<void> requestReview() => InAppReview.instance.requestReview();
}

/// Kemajuan menuju momen positif, disimpan di perangkat (bukan data
/// keuangan, tidak ikut cadangan).
@immutable
class ReviewProgress {
  /// Membuat [ReviewProgress].
  const ReviewProgress({
    this.recorded = 0,
    this.days = const [],
    this.lastRequestedAt,
    this.autoRequests = 0,
    this.optedOut = false,
  });

  /// Dari JSON tersimpan.
  factory ReviewProgress.fromJson(Map<String, dynamic> json) => ReviewProgress(
    recorded: json['recorded'] as int? ?? 0,
    days: [for (final d in json['days'] as List<dynamic>? ?? const []) d as String],
    lastRequestedAt: DateTime.tryParse(json['lastRequestedAt'] as String? ?? ''),
    autoRequests: json['autoRequests'] as int? ?? 0,
    optedOut: json['optedOut'] as bool? ?? false,
  );

  /// Jumlah transaksi dicatat sejak penghitungan dimulai.
  final int recorded;

  /// Hari (`yyyy-MM-dd`) saat ada pencatatan; paling banyak [maxDays] terakhir.
  final List<String> days;

  /// Terakhir kali lembar ulasan otomatis diminta.
  final DateTime? lastRequestedAt;

  /// Jumlah permintaan otomatis yang sudah dikirim.
  final int autoRequests;

  /// Pengguna sudah membuka baris Beri nilai di Akun (tanda ia sudah atau
  /// memang mau mengulas): permintaan otomatis berhenti selamanya.
  final bool optedOut;

  /// Batas hari yang disimpan.
  static const maxDays = 30;

  /// Salinan dengan perubahan.
  ReviewProgress copyWith({
    int? recorded,
    List<String>? days,
    DateTime? lastRequestedAt,
    int? autoRequests,
    bool? optedOut,
  }) => ReviewProgress(
    recorded: recorded ?? this.recorded,
    days: days ?? this.days,
    lastRequestedAt: lastRequestedAt ?? this.lastRequestedAt,
    autoRequests: autoRequests ?? this.autoRequests,
    optedOut: optedOut ?? this.optedOut,
  );

  /// Ke JSON.
  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'recorded': recorded,
    'days': days,
    'lastRequestedAt': lastRequestedAt?.toIso8601String(),
    'autoRequests': autoRequests,
    'optedOut': optedOut,
  };
}

/// Meminta ulasan Play dalam aplikasi.
///
/// Dua jalan: **ketukan pengguna** di Akun ([requestFromUser], jatuh ke
/// halaman toko bila lembar tidak muncul) dan **otomatis** sesudah momen
/// positif ([maybePrompt]): [ReviewThresholds.minRecorded] transaksi tercatat
/// di sedikitnya [ReviewThresholds.minDays] hari berbeda, paling sering sekali
/// per [ReviewThresholds.cooldownDays] dan paling banyak
/// [ReviewThresholds.maxAutoRequests] kali seumur pemakaian (dari Remote Config
/// lewat [config]). Membuka baris Akun menghentikannya selamanya, karena Play
/// tidak memberi tahu apakah pengguna sudah mengulas.
/// Permintaan otomatis tidak pernah terjadi di tengah pencatatan: hitungan
/// naik saat mencatat, permintaan baru dicoba saat aplikasi dibuka.
class ReviewService {
  /// Membuat [ReviewService]; [now] dan [gateway] untuk uji.
  ReviewService({
    required KeyValueStorage storage,
    this.gateway = const InAppReviewGateway(),
    this.config = const StaticReviewConfig(),
    DateTime Function()? now,
    this.shownThreshold = const Duration(milliseconds: 600),
  }) : _now = now ?? DateTime.now,
       _store = StoredValue<ReviewProgress>.json(
         key: _reviewKey,
         fromJson: ReviewProgress.fromJson,
         toJson: (p) => p.toJson(),
         storage: storage,
       );

  /// Pintu ke plugin.
  final ReviewGateway gateway;

  /// Sumber syarat permintaan otomatis (Remote Config di aplikasi).
  final ReviewConfig config;

  /// Permintaan yang selesai lebih cepat dari ini dianggap tidak ditampilkan
  /// Play (jatah habis): tak ada orang yang menutup lembar secepat itu.
  final Duration shownThreshold;

  final DateTime Function() _now;
  final StoredValue<ReviewProgress> _store;

  static String _dayOf(DateTime t) =>
      '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

  Future<ReviewProgress> _read() async => await _store.read() ?? const ReviewProgress();

  /// Menambah hitungan satu transaksi yang baru dicatat.
  Future<void> noteRecorded() async {
    try {
      final progress = await _read();
      final today = _dayOf(_now());
      final days = progress.days.contains(today) ? progress.days : [...progress.days, today];
      await _store.write(
        progress.copyWith(
          recorded: progress.recorded + 1,
          days: days.length > ReviewProgress.maxDays ? days.sublist(days.length - ReviewProgress.maxDays) : days,
        ),
      );
    } on Object catch (e) {
      developer.log('Hitungan ulasan gagal disimpan', error: e, name: 'Review');
    }
  }

  /// Apakah [progress] memenuhi syarat permintaan otomatis.
  bool isEligible(ReviewProgress progress) {
    final rules = config.thresholds;
    if (progress.optedOut || progress.autoRequests >= rules.maxAutoRequests) return false;
    if (progress.recorded < rules.minRecorded || progress.days.length < rules.minDays) return false;
    final last = progress.lastRequestedAt;
    return last == null || _now().difference(last) >= rules.cooldown;
  }

  /// Meminta lembar ulasan bila syaratnya terpenuhi dan lembar tersedia.
  /// Mengembalikan `true` bila permintaan dikirim.
  Future<bool> maybePrompt() async {
    try {
      final progress = await _read();
      if (!isEligible(progress) || !await gateway.isAvailable()) return false;
      // Dicatat sebelum meminta: Play tidak memberi tahu apakah lembar tampil,
      // jadi gagal tetap menghitung sebagai percobaan (hindari mengulang tiap buka).
      await _store.write(progress.copyWith(lastRequestedAt: _now(), autoRequests: progress.autoRequests + 1));
      AppAnalytics.log(ActivationEvents.reviewRequested('auto'));
      await gateway.requestReview();
      return true;
    } on Object catch (e) {
      developer.log('Permintaan ulasan otomatis gagal', error: e, name: 'Review');
      return false;
    }
  }

  /// Pengguna menyentuh baris Beri nilai: tak perlu lagi diminta otomatis.
  Future<void> _optOut() async {
    try {
      final progress = await _read();
      if (!progress.optedOut) await _store.write(progress.copyWith(optedOut: true));
    } on Object catch (e) {
      developer.log('Penanda berhenti ulasan gagal disimpan', error: e, name: 'Review');
    }
  }

  /// Ketukan pengguna: coba lembar ulasan; bila tidak tersedia atau tidak
  /// ditampilkan Play, buka halaman toko lewat [openStore]. Mengembalikan
  /// `false` hanya bila halaman toko pun gagal dibuka.
  Future<bool> requestFromUser({required Future<bool> Function() openStore}) async {
    await _optOut();
    try {
      if (await gateway.isAvailable()) {
        final started = _now();
        AppAnalytics.log(ActivationEvents.reviewRequested('row'));
        await gateway.requestReview();
        if (_now().difference(started) >= shownThreshold) return true;
      }
    } on Object catch (e) {
      developer.log('Lembar ulasan gagal, membuka toko', error: e, name: 'Review');
    }
    return openStore();
  }
}

/// Akses statis ke [ReviewService] aktif, dipasang akar komposisi. Statis
/// seperti `AppAnalytics`, supaya pencatat transaksi tidak perlu membawa
/// layanan ini; tanpa pemasangan semuanya diam.
abstract final class ReviewPrompt {
  ReviewPrompt._();

  static ReviewService? _service;

  /// Memasang [service]; `null` melepas (uji).
  // ignore: use_setters_to_change_properties
  static void install(ReviewService? service) => _service = service;

  /// Satu transaksi baru tercatat.
  static void noteRecorded() {
    final service = _service;
    if (service != null) unawaited(service.noteRecorded());
  }

  /// Mencoba permintaan otomatis.
  static Future<bool> maybePrompt() async => await _service?.maybePrompt() ?? false;

  /// Ketukan pengguna; tanpa layanan langsung membuka toko.
  static Future<bool> requestFromUser({required Future<bool> Function() openStore}) =>
      _service?.requestFromUser(openStore: openStore) ?? openStore();
}
