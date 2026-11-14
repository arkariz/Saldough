import 'dart:async';

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/data_portability/domain/backup_gateway.dart';
import 'package:saldough/features/data_portability/domain/backup_models.dart';
import 'package:saldough/features/data_portability/domain/backup_summary.dart';
import 'package:saldough/features/data_portability/domain/export_models.dart';

/// Sinyal "cadangan baru saja tersimpan" untuk mesin tonggak (stempel Cadangan
/// pertama, ADR-046 §3.4). Satu instans di akar.
final class BackupRecorded {
  final _controller = StreamController<void>.broadcast();

  /// Memancar tiap kali cadangan tercatat tersimpan.
  Stream<void> get stream => _controller.stream;

  /// Memberi tahu pendengar.
  void notify() => _controller.add(null);
}

/// [BackupGateway] yang meneruskan semuanya ke [_inner] dan memberi sinyal ke
/// [_signal] sesudah [recordBackup] berhasil. Fitur cadangan tidak mengenal
/// mesin tonggak; akar komposisi yang menyambungkannya (ADR-030).
final class BackupRecordedGateway implements BackupGateway {
  /// Membuat [BackupRecordedGateway].
  const BackupRecordedGateway(this._inner, this._signal);

  final BackupGateway _inner;
  final BackupRecorded _signal;

  @override
  Future<Either<Failure, BackupSummary>> summary() => _inner.summary();

  @override
  Future<Either<Failure, BackupFile>> create({ExportCancel? cancel}) => _inner.create(cancel: cancel);

  @override
  Future<Either<Failure, DateTime?>> lastBackupAt() => _inner.lastBackupAt();

  @override
  Future<Either<Failure, Unit>> recordBackup() async {
    final result = await _inner.recordBackup();
    if (result.isRight()) _signal.notify();
    return result;
  }
}
