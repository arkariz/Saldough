import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/app/milestone/backup_recorded_gateway.dart';
import 'package:saldough/features/data_portability/domain/backup_gateway.dart';

final class _Inner implements BackupGateway {
  _Inner({this.fail = false});
  final bool fail;

  @override
  Future<Either<Failure, Unit>> recordBackup() async =>
      fail ? const Left(SystemFailure(code: FailureCode.unknown, message: 'x')) : const Right(unit);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('cadangan tercatat: sinyal dipancarkan', () async {
    final signal = BackupRecorded();
    var count = 0;
    signal.stream.listen((_) => count++);
    await BackupRecordedGateway(_Inner(), signal).recordBackup();
    await Future<void>.delayed(Duration.zero);
    expect(count, 1);
  });

  test('gagal mencatat: tanpa sinyal', () async {
    final signal = BackupRecorded();
    var count = 0;
    signal.stream.listen((_) => count++);
    final result = await BackupRecordedGateway(_Inner(fail: true), signal).recordBackup();
    await Future<void>.delayed(Duration.zero);
    expect(result.isLeft(), isTrue);
    expect(count, 0);
  });
}
