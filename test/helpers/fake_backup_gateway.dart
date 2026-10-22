import 'dart:async';
import 'dart:typed_data';

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/data_portability/domain/backup_failure_codes.dart';
import 'package:saldough/features/data_portability/domain/backup_gateway.dart';
import 'package:saldough/features/data_portability/domain/backup_models.dart';
import 'package:saldough/features/data_portability/domain/backup_summary.dart';
import 'package:saldough/features/data_portability/domain/export_models.dart';

/// [BackupGateway] palsu untuk uji lembar dan bagian Akun.
final class FakeBackupGateway implements BackupGateway {
  /// Membuat [FakeBackupGateway].
  FakeBackupGateway({this.lastBackup, this.failCreate = false});

  /// Ringkasan yang dikembalikan.
  BackupSummary summaryValue = const BackupSummary(
    transactions: 142,
    wallets: 4,
    firstDate: '2026-06-03',
    currency: 'IDR',
  );

  /// Nilai "Cadangan terakhir".
  DateTime? lastBackup;

  /// Bila `true`, `create` gagal.
  bool failCreate;

  /// Bila di-set, `create` menunggu sampai ini selesai (menahan tahap busy).
  Completer<void>? holdCreate;

  /// Berapa kali `recordBackup` dipanggil.
  int recorded = 0;

  @override
  Future<Either<Failure, BackupSummary>> summary() async => right(summaryValue);

  @override
  Future<Either<Failure, BackupFile>> create({ExportCancel? cancel}) async {
    await holdCreate?.future;
    if (failCreate) return left(const BusinessRuleFailure(code: BackupFailureCodes.invalid, message: 'gagal'));
    if (cancel != null && cancel.isCancelled) {
      return left(const BusinessRuleFailure(code: BackupFailureCodes.cancelled, message: 'batal'));
    }
    return right(
      BackupFile(
        name: 'tanukonomy-cadangan-2026-10-22.tkbak',
        bytes: Uint8List.fromList([1, 2, 3]),
        summary: summaryValue,
        createdAt: DateTime(2026, 10, 22, 9),
      ),
    );
  }

  @override
  Future<Either<Failure, DateTime?>> lastBackupAt() async => right(lastBackup);

  @override
  Future<Either<Failure, Unit>> recordBackup() async {
    recorded++;
    lastBackup = DateTime(2026, 10, 22, 9);
    return right(unit);
  }
}
