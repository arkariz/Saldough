import 'dart:async';
import 'dart:typed_data';

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/data_portability/domain/backup_summary.dart';
import 'package:saldough/features/data_portability/domain/restore_gateway.dart';
import 'package:saldough/features/data_portability/domain/restore_models.dart';

/// [RestoreGateway] palsu untuk uji alur pulihkan dan bagian Akun.
final class FakeRestoreGateway implements RestoreGateway {
  /// Membuat [FakeRestoreGateway].
  FakeRestoreGateway({this.safety});

  /// Cadangan pengaman yang berlaku; `null` = tidak ada.
  SafetyCopyInfo? safety;

  /// Bila di-set, `inspect` dan `inspectSafetyCopy` gagal dengan kode ini.
  FailureCode? inspectFailure;

  /// Bila di-set, `stage` gagal dengan kode ini.
  FailureCode? stageFailure;

  /// Bila di-set, `stage` menunggu ini selesai.
  Completer<void>? holdStage;

  /// Pratinjau yang dikembalikan; boleh diubah uji.
  RestorePreview preview = RestorePreview(
    source: RestoreKind.account,
    backup: const BackupSummary(transactions: 138, wallets: 4, firstDate: '2026-06-03', currency: 'IDR'),
    backupCreatedAt: DateTime(2026, 10, 12, 9),
    current: const BackupSummary(
      transactions: 142,
      wallets: 4,
      firstDate: '2026-06-03',
      currency: 'IDR',
      lastDate: '2026-10-20',
    ),
    isOlderThanCurrent: false,
    newCurrency: null,
    lostInboxDrafts: 0,
  );

  /// Sesi yang sudah disiapkan lewat [stage].
  final staged = <RestoreSession>[];

  /// Jumlah pemanggilan `inspect`.
  int inspected = 0;

  Either<Failure, RestoreSession> _session(RestoreKind source) {
    final code = inspectFailure;
    if (code != null) return left(BusinessRuleFailure(code: code, message: 'gagal'));
    return right(RestoreSession(preview: _withSource(source), docs: const {'wallet_all': '{}'}));
  }

  RestorePreview _withSource(RestoreKind source) => RestorePreview(
    source: source,
    backup: preview.backup,
    backupCreatedAt: preview.backupCreatedAt,
    current: preview.current,
    isOlderThanCurrent: preview.isOlderThanCurrent,
    newCurrency: preview.newCurrency,
    lostInboxDrafts: preview.lostInboxDrafts,
  );

  @override
  Future<Either<Failure, RestoreSession>> inspect(Uint8List bytes, {RestoreKind source = RestoreKind.account}) async {
    inspected++;
    return _session(source);
  }

  @override
  Future<Either<Failure, RestoreSession?>> inspectSafetyCopy() async {
    if (safety == null) return right(null);
    return _session(RestoreKind.undo).map<RestoreSession?>((s) => s);
  }

  @override
  Future<Either<Failure, SafetyCopyInfo?>> safetyCopy() async => right(safety);

  @override
  Future<Either<Failure, Unit>> stage(RestoreSession session) async {
    await holdStage?.future;
    final code = stageFailure;
    if (code != null) return left(BusinessRuleFailure(code: code, message: 'gagal'));
    staged.add(session);
    return right(unit);
  }
}
