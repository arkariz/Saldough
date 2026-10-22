import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/features/data_portability/data/backup_codec.dart';
import 'package:saldough/features/data_portability/data/backup_scope.dart';
import 'package:saldough/features/data_portability/data/backup_validator.dart';
import 'package:saldough/features/data_portability/domain/backup_failure_codes.dart';
import 'package:saldough/features/data_portability/domain/backup_gateway.dart';
import 'package:saldough/features/data_portability/domain/backup_models.dart';
import 'package:saldough/features/data_portability/domain/backup_registry.dart';
import 'package:saldough/features/data_portability/domain/backup_summary.dart';
import 'package:saldough/features/data_portability/domain/export_models.dart';

/// Versi dan nomor build aplikasi untuk amplop cadangan.
typedef AppVersionInfo = ({String version, int build});

/// Kunci penyimpanan status "Cadangan terakhir": milik perangkat, tidak ikut
/// cadangan (ia mencatat aksi di perangkat ini, bukan data keuangan).
const lastBackupStorageKey = StorageKey(namespace: 'settings', name: 'last_backup');

/// Membuat cadangan seluruh data (ADR-040 §3.2-§3.3, §3.5).
final class BackupService with RepositoryGuard implements BackupGateway {
  /// Membuat [BackupService]. [fileStem] dipanggil saat cadangan dibuat supaya
  /// mengikuti bahasa aplikasi (`cadangan` atau `backup`).
  BackupService({
    required this._storage,
    required this._registry,
    required this._appInfo,
    required this._fileStem,
    this._now = DateTime.now,
  });

  final KeyValueStorage _storage;
  final BackupRegistry _registry;
  final Future<AppVersionInfo> Function() _appInfo;
  final String Function() _fileStem;
  final DateTime Function() _now;

  @override
  Failure? mapCustomError(Object error) =>
      error is BackupException ? BusinessRuleFailure(code: error.code, message: error.message) : null;

  @override
  Future<Either<Failure, BackupSummary>> summary() => guard(() async {
    final docs = await BackupScope.collect(_storage, _registry);
    return BackupValidator.summarize(docs, _registry);
  });

  @override
  Future<Either<Failure, BackupFile>> create({ExportCancel? cancel}) => guard(() async {
    final docs = await BackupScope.collect(_storage, _registry);
    _throwIfCancelled(cancel);

    final info = await _appInfo();
    final createdAt = _now();
    final summary = BackupValidator.summarize(docs, _registry);
    final bytes = await _encodeInIsolate(docs, createdAt, info, summary, _registry);
    _throwIfCancelled(cancel);

    return BackupFile(
      name: 'tanukonomy-${_fileStem()}-${_day(createdAt)}.${BackupCodec.extension}',
      bytes: bytes,
      summary: summary,
      createdAt: createdAt,
    );
  });

  @override
  Future<Either<Failure, DateTime?>> lastBackupAt() => guard(() async {
    final raw = await _storage.read(lastBackupStorageKey.value);
    if (raw == null) return null;
    final at = (jsonDecode(raw) as Map<String, dynamic>)['at'];
    return at is String ? DateTime.tryParse(at) : null;
  });

  @override
  Future<Either<Failure, Unit>> recordBackup() => guardVoid(
    () => _storage.write(lastBackupStorageKey.value, '{"schemaVersion":1,"at":"${_now().toIso8601String()}"}'),
  );

  static void _throwIfCancelled(ExportCancel? cancel) {
    if (cancel != null && cancel.isCancelled) {
      throw const BackupException(BackupFailureCodes.cancelled, 'dibatalkan pengguna');
    }
  }

  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Membuat berkas dan memeriksanya lagi di isolate: dekompresi, amplop,
/// checksum, versi, dan rujukan. Cadangan yang tidak lolos tidak diserahkan
/// (R-1–R-3 berlaku juga untuk berkas buatan sendiri).
///
/// Fungsi tingkat atas dengan argumen eksplisit, bukan closure di dalam
/// metode, supaya `this` (dan penyimpanan yang tak bisa dikirim antar isolate)
/// tidak ikut terbawa.
Future<Uint8List> _encodeInIsolate(
  Map<String, String> docs,
  DateTime createdAt,
  AppVersionInfo info,
  BackupSummary summary,
  BackupRegistry registry,
) => Isolate.run(() {
  final bytes = BackupCodec.encode(
    docs: docs,
    createdAt: createdAt,
    appVersion: info.version,
    appBuild: info.build,
    summary: summary,
  );
  BackupValidator.validate(BackupCodec.decode(bytes), registry);
  return bytes;
});
