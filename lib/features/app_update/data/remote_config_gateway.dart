import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:saldough/features/app_update/domain/services/release_note_parser.dart';

/// Pintu ke Remote Config untuk catatan rilis; dipisah dari SDK supaya
/// [ReleaseNotesRepositoryImpl] bisa diuji tanpa Firebase.
abstract interface class RemoteConfigGateway {
  /// Mengambil dan mengaktifkan nilai terbaru (tunduk pada batas frekuensi
  /// SDK); `true` bila ada nilai baru yang diaktifkan. Melempar bila gagal.
  Future<bool> fetchAndActivate();

  /// Nilai string parameter entri catatan yang sedang aktif.
  Map<String, String> noteValues();

  /// Server pernah berhasil dibaca (status pengambilan terakhir sukses).
  bool get hasFetched;

  /// Sinyal nilai baru diaktifkan saat aplikasi terbuka.
  Stream<void> get updates;
}

/// [RemoteConfigGateway] di atas `firebase_remote_config` (ADR-039 §3.3
/// butir 4): nilai bawaan kosong, interval ambil 30 menit (di bawah batas
/// throttle klien), dan `onConfigUpdated` untuk perubahan langsung.
final class FirebaseRemoteConfigGateway implements RemoteConfigGateway {
  /// Membuat [FirebaseRemoteConfigGateway]; [remoteConfig] untuk uji.
  FirebaseRemoteConfigGateway({FirebaseRemoteConfig? remoteConfig}) : _injected = remoteConfig;

  /// Interval minimum antar pengambilan dari server.
  static const minimumFetchInterval = Duration(minutes: 30);

  final FirebaseRemoteConfig? _injected;

  /// Dibuat malas: Firebase yang gagal diinisialisasi hanya membuat pemakaian
  /// pertama gagal (ditangkap pemanggil), bukan membuat gateway gagal dibangun.
  late final FirebaseRemoteConfig _rc = _injected ?? FirebaseRemoteConfig.instance;
  Future<void>? _configured;

  Future<void> _configure() => _configured ??= _rc.setConfigSettings(
    RemoteConfigSettings(fetchTimeout: const Duration(seconds: 10), minimumFetchInterval: minimumFetchInterval),
  );

  @override
  Future<bool> fetchAndActivate() async {
    await _configure();
    return _rc.fetchAndActivate();
  }

  @override
  Map<String, String> noteValues() => {
    for (final entry in _rc.getAll().entries)
      if (entry.key.startsWith(releaseNoteKeyPrefix)) entry.key: entry.value.asString(),
  };

  @override
  bool get hasFetched => _rc.lastFetchStatus == RemoteConfigFetchStatus.success;

  @override
  Stream<void> get updates => _rc.onConfigUpdated.asyncMap((_) => _rc.activate()).handleError((Object _) {});
}
