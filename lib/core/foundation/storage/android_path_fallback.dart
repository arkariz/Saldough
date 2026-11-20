import 'dart:developer' as developer;
import 'dart:io';

import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// Menyusun folder data aplikasi di Android tanpa `path_provider`.
///
/// Rilis 1.3.0/1.3.1 membawa `path_provider_android` 2.3.x (JNI) yang di
/// sebagian perangkat melempar `ClassNotFoundException: Landroid/content/Context;`
/// pada langkah pertama startup (storage). Native tidak bisa diubah lewat patch
/// Shorebird, jadi jalur cadangan ini hanya dipakai bila pemanggilan aslinya
/// gagal.
///
/// Jalur disusun dari UID proses (`/proc/self/status`, user = uid / 100000,
/// aturan Android) dan nama paket tetap, lalu **diverifikasi**: folder
/// `/data/user/<user>/<paket>` harus ada. Folder itu hanya ada untuk paket ini
/// di user ini, jadi jalurnya pasti folder data yang sama dengan yang dipakai
/// `path_provider` (mis. `app_flutter`); tebakan yang salah tidak mungkin lolos
/// dan database tidak akan terbuka kosong di tempat lain.
class AndroidDataDirResolver {
  /// Membuat penyusun; port bisa diganti di uji.
  const AndroidDataDirResolver({
    this.package = 'com.arkarizdev.tanukonomy',
    this.readStatus = _readProcStatus,
    this.exists = _directoryExists,
    this.create = _createDirectory,
  });

  /// Nama paket aplikasi.
  final String package;

  /// Membaca isi `/proc/self/status`.
  final Future<String> Function() readStatus;

  /// Apakah folder [path] ada.
  final bool Function(String path) exists;

  /// Membuat folder [path] (dan induknya).
  final void Function(String path) create;

  /// Jalur `<folder data paket>/<sub>`, atau `null` bila tidak bisa dipastikan
  /// (UID tak terbaca, atau folder data paket tidak ada).
  Future<String?> resolve(String sub) async {
    try {
      final uid = parseUid(await readStatus());
      if (uid == null) return null;
      final base = '/data/user/${uid ~/ 100000}/$package';
      if (!exists(base)) return null;
      final path = '$base/$sub';
      if (!exists(path)) create(path);
      return path;
    } on Object {
      return null;
    }
  }

  /// UID dari baris `Uid:` `/proc/self/status`, atau `null`.
  static int? parseUid(String status) {
    final match = RegExp(r'^Uid:\s+(\d+)', multiLine: true).firstMatch(status);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  static Future<String> _readProcStatus() => File('/proc/self/status').readAsString();
  static bool _directoryExists(String path) => Directory(path).existsSync();
  static void _createDirectory(String path) => Directory(path).createSync(recursive: true);
}

/// `PathProviderPlatform` yang meneruskan ke implementasi asli, dan hanya bila
/// itu melempar galat memakai [AndroidDataDirResolver]. Perangkat yang sehat
/// berjalan persis seperti tanpa pembungkus ini. Bila jalur cadangan tidak bisa
/// dipastikan, galat aslinya dilempar ulang (layar darurat seperti biasa).
class FallbackPathProvider extends PathProviderPlatform {
  /// Membuat pembungkus untuk [inner].
  FallbackPathProvider({
    required this.inner,
    this.resolver = const AndroidDataDirResolver(),
    this.onFallback,
  });

  /// Implementasi asli (di Android: `PathProviderAndroid`).
  final PathProviderPlatform inner;

  /// Penyusun jalur cadangan.
  final AndroidDataDirResolver resolver;

  /// Dipanggil tiap kali cadangan dipakai (mis. untuk dicatat ke Crashlytics).
  final void Function(Object error, String kind)? onFallback;

  /// Memasang pembungkus di Android; tidak berbuat apa pun di platform lain
  /// atau bila sudah terpasang. Panggil sebelum storage dibuka.
  static void installOnAndroid({void Function(Object error, String kind)? onFallback}) {
    if (!Platform.isAndroid) return;
    final current = PathProviderPlatform.instance;
    if (current is FallbackPathProvider) return;
    PathProviderPlatform.instance = FallbackPathProvider(inner: current, onFallback: onFallback);
  }

  Future<String?> _guard(Future<String?> Function() call, String sub, String kind) async {
    try {
      return await call();
    } on Object catch (error) {
      final fallback = await resolver.resolve(sub);
      if (fallback == null) rethrow;
      developer.log('path_provider gagal ($kind), memakai $fallback: $error', name: 'PathFallback');
      onFallback?.call(error, kind);
      return fallback;
    }
  }

  // Padanan `Context.getDir("flutter")`, `getCacheDir()`, `getFilesDir()`.
  @override
  Future<String?> getApplicationDocumentsPath() => _guard(inner.getApplicationDocumentsPath, 'app_flutter', 'documents');

  @override
  Future<String?> getTemporaryPath() => _guard(inner.getTemporaryPath, 'cache', 'temporary');

  @override
  Future<String?> getApplicationCachePath() => _guard(inner.getApplicationCachePath, 'cache', 'cache');

  @override
  Future<String?> getApplicationSupportPath() => _guard(inner.getApplicationSupportPath, 'files', 'support');

  @override
  Future<String?> getLibraryPath() => inner.getLibraryPath();

  @override
  Future<String?> getExternalStoragePath() => inner.getExternalStoragePath();

  @override
  Future<List<String>?> getExternalCachePaths() => inner.getExternalCachePaths();

  @override
  Future<List<String>?> getExternalStoragePaths({StorageDirectory? type}) => inner.getExternalStoragePaths(type: type);

  @override
  Future<String?> getDownloadsPath() => inner.getDownloadsPath();
}
