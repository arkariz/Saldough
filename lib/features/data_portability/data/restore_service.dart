import 'dart:convert';
import 'dart:typed_data';

import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/features/data_portability/data/backup_codec.dart';
import 'package:saldough/features/data_portability/data/backup_scope.dart';
import 'package:saldough/features/data_portability/data/backup_validator.dart';
import 'package:saldough/features/data_portability/data/restore_engine.dart';
import 'package:saldough/features/data_portability/domain/backup_failure_codes.dart';
import 'package:saldough/features/data_portability/domain/backup_registry.dart';
import 'package:saldough/features/data_portability/domain/backup_summary.dart';
import 'package:saldough/features/data_portability/domain/restore_gateway.dart';
import 'package:saldough/features/data_portability/domain/restore_models.dart';

/// Kunci kotak masuk tangkapan notifikasi; tidak ikut cadangan, tetapi
/// jumlah drafnya disebut di pratinjau karena ikut terganti (R-10).
const _inboxKey = 'capture_inbox';

/// Memulihkan data dari cadangan (ADR-040 §3.4).
final class RestoreService with RepositoryGuard implements RestoreGateway {
  /// Membuat [RestoreService].
  RestoreService({required this._storage, required this._engine, required this._registry});

  final KeyValueStorage _storage;
  final RestoreEngine _engine;
  final BackupRegistry _registry;

  @override
  Failure? mapCustomError(Object error) =>
      error is BackupException ? BusinessRuleFailure(code: error.code, message: error.message) : null;

  @override
  Future<Either<Failure, RestoreSession>> inspect(Uint8List bytes, {RestoreKind source = RestoreKind.account}) =>
      guard(() async {
        final contents = BackupCodec.decode(bytes);
        BackupValidator.validate(contents, _registry);
        final backup = BackupValidator.summarize(contents.docs, _registry);
        final current = await _currentSummary();
        return RestoreSession(
          preview: RestorePreview(
            source: source,
            backup: backup,
            backupCreatedAt: contents.createdAt,
            current: current,
            isOlderThanCurrent: source != RestoreKind.onboarding && _isOlder(backup, contents.createdAt, current),
            newCurrency: _currencyChange(backup, current),
            lostInboxDrafts: source == RestoreKind.onboarding ? 0 : await _inboxDrafts(),
          ),
          docs: contents.docs,
        );
      });

  @override
  Future<Either<Failure, RestoreSession?>> inspectSafetyCopy() => guard(() async {
    final info = await _engine.safetyCopy();
    if (info == null) return null;
    final docs = await _engine.safetyDocs();
    if (docs == null) return null;
    final backup = BackupValidator.summarize(docs, _registry);
    final current = await _currentSummary();
    return RestoreSession(
      preview: RestorePreview(
        source: RestoreKind.undo,
        backup: backup,
        backupCreatedAt: info.createdAt,
        current: current,
        isOlderThanCurrent: false,
        newCurrency: _currencyChange(backup, current),
        lostInboxDrafts: await _inboxDrafts(),
      ),
      docs: docs,
    );
  });

  @override
  Future<Either<Failure, SafetyCopyInfo?>> safetyCopy() => guard(() async {
    final info = await _engine.safetyCopy();
    return info == null ? null : SafetyCopyInfo(createdAt: info.createdAt, expiresAt: info.expiresAt);
  });

  @override
  Future<Either<Failure, Unit>> stage(RestoreSession session) => guardVoid(
    () => _engine.stage(
      incoming: session.docs,
      kind: session.preview.source,
      backupCreatedAt: session.preview.backupCreatedAt,
    ),
  );

  Future<BackupSummary> _currentSummary() async =>
      BackupValidator.summarize(await BackupScope.collect(_storage, _registry), _registry);

  /// Lebih lama dari data sekarang: transaksi lebih sedikit, atau transaksi
  /// terakhir di ponsel ini lebih baru dari tanggal cadangan dibuat.
  static bool _isOlder(BackupSummary backup, DateTime createdAt, BackupSummary current) {
    if (current.transactions > backup.transactions) return true;
    final lastNow = current.lastDate;
    if (lastNow == null) return false;
    final day = DateTime(createdAt.year, createdAt.month, createdAt.day);
    return DateTime.parse(lastNow).isAfter(day);
  }

  static String? _currencyChange(BackupSummary backup, BackupSummary current) {
    final next = backup.currency;
    final now = current.currency ?? 'IDR';
    return next != null && next != now ? next : null;
  }

  Future<int> _inboxDrafts() async {
    final raw = await _storage.read(_inboxKey);
    if (raw == null) return 0;
    final json = jsonDecode(raw);
    if (json is! Map<String, dynamic>) return 0;
    final items = json['items'];
    return items is List ? items.length : 0;
  }
}
