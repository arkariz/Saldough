import 'dart:developer' as developer;

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Syarat permintaan ulasan otomatis. Nilai dari Remote Config; [defaults]
/// dipakai bila server tidak terjangkau atau nilainya tidak sah.
@immutable
class ReviewThresholds {
  /// Membuat [ReviewThresholds].
  const ReviewThresholds({
    required this.minRecorded,
    required this.minDays,
    required this.cooldownDays,
    required this.maxAutoRequests,
  });

  /// Membaca [values] (nama parameter -> string). Nilai yang hilang, bukan
  /// bilangan bulat, atau di luar batas diganti bawaannya.
  factory ReviewThresholds.fromValues(Map<String, String> values) {
    int read(String key, int fallback, int max, {int min = 1}) {
      final parsed = int.tryParse(values[key]?.trim() ?? '');
      return parsed == null || parsed < min || parsed > max ? fallback : parsed;
    }

    return ReviewThresholds(
      minRecorded: read(minRecordedKey, defaults.minRecorded, 1000),
      // Paling banyak `ReviewProgress.maxDays` hari yang disimpan.
      minDays: read(minDaysKey, defaults.minDays, 30),
      cooldownDays: read(cooldownDaysKey, defaults.cooldownDays, 3650),
      // 0 = tidak pernah meminta otomatis.
      maxAutoRequests: read(maxAutoRequestsKey, defaults.maxAutoRequests, 20, min: 0),
    );
  }

  /// Nama parameter Remote Config: transaksi tercatat minimal.
  static const minRecordedKey = 'review_min_recorded';

  /// Nama parameter Remote Config: hari pencatatan berbeda minimal.
  static const minDaysKey = 'review_min_days';

  /// Nama parameter Remote Config: jeda hari antarpermintaan otomatis.
  static const cooldownDaysKey = 'review_cooldown_days';

  /// Nama parameter Remote Config: jumlah total permintaan otomatis (0 = mati).
  static const maxAutoRequestsKey = 'review_max_auto_requests';

  /// Seluruh nama parameter.
  static const Set<String> keys = {minRecordedKey, minDaysKey, cooldownDaysKey, maxAutoRequestsKey};

  /// Nilai bila Remote Config belum ada: 10 transaksi, 2 hari, jeda 90 hari,
  /// paling banyak 2 permintaan otomatis.
  static const defaults = ReviewThresholds(minRecorded: 10, minDays: 2, cooldownDays: 90, maxAutoRequests: 2);

  /// Transaksi tercatat minimal.
  final int minRecorded;

  /// Hari pencatatan berbeda minimal.
  final int minDays;

  /// Jeda hari antarpermintaan otomatis.
  final int cooldownDays;

  /// Jumlah total permintaan otomatis sepanjang pemakaian; 0 = mati.
  final int maxAutoRequests;

  /// Jeda sebagai [Duration].
  Duration get cooldown => Duration(days: cooldownDays);

  @override
  bool operator ==(Object other) =>
      other is ReviewThresholds &&
      other.minRecorded == minRecorded &&
      other.minDays == minDays &&
      other.cooldownDays == cooldownDays &&
      other.maxAutoRequests == maxAutoRequests;

  @override
  int get hashCode => Object.hash(minRecorded, minDays, cooldownDays, maxAutoRequests);
}

/// Sumber [ReviewThresholds].
abstract interface class ReviewConfig {
  /// Syarat yang berlaku sekarang.
  ReviewThresholds get thresholds;
}

/// [ReviewConfig] tetap, dipakai uji dan bila Firebase tidak ada.
final class StaticReviewConfig implements ReviewConfig {
  /// Membuat [StaticReviewConfig].
  const StaticReviewConfig([this.thresholds = ReviewThresholds.defaults]);

  @override
  final ReviewThresholds thresholds;
}

/// [ReviewConfig] di atas `firebase_remote_config`.
///
/// Hanya **membaca** nilai yang sudah aktif di singleton Remote Config yang
/// sama dengan catatan rilis dan hak Plus; tidak mengambil dan tidak
/// mengubah setelan ambil, jadi tidak saling menimpa. Sebelum pengambilan
/// pertama selesai (pembukaan pertama sesudah pasang) nilai bawaan berlaku.
final class FirebaseReviewConfig implements ReviewConfig {
  /// Membuat [FirebaseReviewConfig]; [remoteConfig] untuk uji.
  FirebaseReviewConfig({FirebaseRemoteConfig? remoteConfig}) : _injected = remoteConfig;

  final FirebaseRemoteConfig? _injected;

  @override
  ReviewThresholds get thresholds {
    try {
      final rc = _injected ?? FirebaseRemoteConfig.instance;
      return ReviewThresholds.fromValues({
        for (final MapEntry(:key, :value) in rc.getAll().entries)
          if (ReviewThresholds.keys.contains(key)) key: value.asString(),
      });
    } on Object catch (e) {
      developer.log('Remote Config ulasan gagal dibaca', error: e, name: 'Review');
      return ReviewThresholds.defaults;
    }
  }
}
