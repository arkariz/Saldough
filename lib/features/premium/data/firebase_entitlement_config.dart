import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';

/// [EntitlementConfig] di atas `firebase_remote_config` (ADR-041 §3.6, §3.13
/// butir 8).
///
/// Memakai singleton Remote Config yang sama dengan catatan rilis
/// (`app_update`), dengan **setelan ambil yang sama** supaya keduanya tidak
/// saling menimpa, tetapi gateway sendiri: hanya membaca kunci di
/// [EntitlementLimits.keys] dan tidak pernah menyetel nilai bawaan SDK. Nilai
/// bawaan hidup di [EntitlementLimits.defaults].
final class FirebaseEntitlementConfig implements EntitlementConfig {
  /// Membuat [FirebaseEntitlementConfig]; [remoteConfig] untuk uji.
  FirebaseEntitlementConfig({
    FirebaseRemoteConfig? remoteConfig,
    this.isRelease = kReleaseMode,
    String overrides = const String.fromEnvironment('ENTITLEMENT_OVERRIDES'),
  }) : _injected = remoteConfig,
       _overrides = isRelease ? const {} : parseEntitlementOverrides(overrides);

  /// Build rilis: pengganti nilai dimatikan.
  final bool isRelease;

  /// Nilai yang menimpa Remote Config di build non-rilis (uji lokal, mis.
  /// `plus_launch_at` supaya tombol beli hidup tanpa mengubah konsol).
  final Map<String, String> _overrides;

  /// Sama dengan `FirebaseRemoteConfigGateway` (`app_update`); fitur tidak
  /// boleh saling mengimpor (ADR-030), jadi nilainya diulang di sini.
  static const minimumFetchInterval = Duration(minutes: 30);

  /// Sama dengan `FirebaseRemoteConfigGateway` (`app_update`).
  static const fetchTimeout = Duration(seconds: 10);

  final FirebaseRemoteConfig? _injected;
  late final FirebaseRemoteConfig _rc = _injected ?? FirebaseRemoteConfig.instance;
  final _changes = StreamController<EntitlementLimits>.broadcast();
  StreamSubscription<void>? _updates;
  Future<void>? _configured;
  EntitlementLimits _current = EntitlementLimits.defaults;

  @override
  EntitlementLimits get current => _current;

  @override
  Stream<EntitlementLimits> get changes => _changes.stream;

  Future<void> _configure() => _configured ??= _rc.setConfigSettings(
    RemoteConfigSettings(fetchTimeout: fetchTimeout, minimumFetchInterval: minimumFetchInterval),
  );

  @override
  Future<void> refresh() async {
    try {
      await _configure();
      await _rc.fetchAndActivate();
    } on Object catch (e) {
      // Tanpa koneksi atau Firebase belum siap: tetap pakai nilai aktif
      // terakhir (atau bawaan).
      developer.log('Remote Config hak gagal diambil', error: e, name: 'Entitlements');
    }
    _reload();
    _listen();
  }

  /// Mendengar `onConfigUpdated` sekali, supaya perubahan langsung dari
  /// konsol berlaku tanpa menunggu pembukaan berikutnya.
  void _listen() {
    if (_updates != null) return;
    try {
      _updates = _rc.onConfigUpdated
          .asyncMap((_) => _rc.activate())
          .listen((_) => _reload(), onError: (Object _) {});
    } on Object {
      // Platform tanpa pembaruan langsung: cukup `refresh`.
    }
  }

  void _reload() {
    final EntitlementLimits next;
    try {
      next = EntitlementLimits.fromValues({
        for (final MapEntry(:key, :value) in _rc.getAll().entries)
          if (EntitlementLimits.keys.contains(key)) key: value.asString(),
        ..._overrides,
      });
    } on Object catch (e) {
      developer.log('Remote Config hak gagal dibaca', error: e, name: 'Entitlements');
      return;
    }
    if (next == _current) return;
    _current = next;
    _changes.add(next);
  }

  /// Melepas langganan; dipakai uji.
  Future<void> dispose() async {
    await _updates?.cancel();
    await _changes.close();
  }
}

/// Mengurai `kunci=nilai` dipisah koma atau titik koma dari
/// `--dart-define=ENTITLEMENT_OVERRIDES=...`; hanya kunci [EntitlementLimits.keys].
@visibleForTesting
Map<String, String> parseEntitlementOverrides(String raw) => {
  for (final part in raw.split(RegExp('[,;]')))
    if (part.split('=') case [final key, ...final rest] when EntitlementLimits.keys.contains(key.trim()) && rest.isNotEmpty)
      key.trim(): rest.join('=').trim(),
};
