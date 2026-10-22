import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/data_portability/domain/backup_failure_codes.dart';

/// Pencocok untuk `expect(() => ..., throwsBackup(BackupFailureCodes.invalid))`.
Matcher throwsBackup(Object code) => throwsA(isA<BackupException>().having((e) => e.code, 'code', code));
