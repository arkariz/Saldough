import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/data_portability/domain/backup_failure_codes.dart';
import 'package:saldough/features/data_portability/domain/restore_models.dart';
import 'package:saldough/features/data_portability/presentation/bloc/restore_bloc.dart';
import 'package:saldough/features/data_portability/presentation/bloc/restore_state.dart';

import '../../helpers/fake_file_transfer.dart';
import '../../helpers/fake_restore_gateway.dart';

/// Alur pulihkan (EXPORT_BACKUP §7.1): periksa → pratinjau → siapkan → mulai ulang.
void main() {
  late FakeRestoreGateway gateway;
  late FakeFileTransfer transfer;
  late RestoreBloc bloc;
  late List<bool> reboots;

  setUp(() {
    gateway = FakeRestoreGateway(
      safety: SafetyCopyInfo(createdAt: DateTime(2026, 10, 22), expiresAt: DateTime(2026, 11, 21)),
    );
    transfer = FakeFileTransfer();
    reboots = [];
    bloc = RestoreBloc(
      gateway: gateway,
      transfer: transfer,
      reboot: ({required onboarding}) async => reboots.add(onboarding),
    );
  });

  tearDown(() => bloc.close());

  Future<RestoreState> reach(RestorePhase phase) => bloc.stream.firstWhere((s) => s.phase == phase);

  RestoreStarted fileStart() => RestoreStarted(bytes: Uint8List.fromList([1]), source: RestoreKind.account);

  test('berkas sah: pratinjau dengan sesinya', () async {
    bloc.add(fileStart());
    final state = await reach(RestorePhase.preview);
    expect(state.session!.preview.backup.transactions, 138);
    expect(state.source, RestoreKind.account);
  });

  test('berkas ditolak: galat sesuai kode, data tidak diminta untuk disiapkan', () async {
    for (final (code, kind) in [
      (BackupFailureCodes.invalid, RestoreErrorKind.invalid),
      (BackupFailureCodes.inconsistent, RestoreErrorKind.invalid),
      (BackupFailureCodes.newer, RestoreErrorKind.newer),
    ]) {
      final b = RestoreBloc(
        gateway: gateway..inspectFailure = code,
        transfer: transfer,
        reboot: ({required onboarding}) async {},
      )..add(fileStart());
      final state = await b.stream.firstWhere((s) => s.phase == RestorePhase.error);
      expect(state.error, kind, reason: '$code');
      await b.close();
    }
    expect(gateway.staged, isEmpty);
  });

  test('Kembalikan: pratinjau dari cadangan pengaman; tanpa cadangan pengaman → galat', () async {
    bloc.add(const RestoreStarted(bytes: null, source: RestoreKind.undo));
    final state = await reach(RestorePhase.preview);
    expect(state.session!.preview.source, RestoreKind.undo);

    final none = RestoreBloc(
      gateway: FakeRestoreGateway(),
      transfer: transfer,
      reboot: ({required onboarding}) async {},
    )..add(const RestoreStarted(bytes: null, source: RestoreKind.undo));
    expect((await none.stream.firstWhere((s) => s.phase == RestorePhase.error)).error, RestoreErrorKind.other);
    await none.close();
  });

  test('Ganti data: menyiapkan penggantian lalu memulai ulang aplikasi', () async {
    bloc.add(fileStart());
    await reach(RestorePhase.preview);
    bloc.add(const RestoreConfirmed());
    await reach(RestorePhase.running);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(gateway.staged, hasLength(1));
    expect(reboots, [false]);
  });

  test('dari onboarding: boot ulang menandai onboarding (daftar langkah tanpa cadangan pengaman)', () async {
    bloc.add(RestoreStarted(bytes: Uint8List.fromList([1]), source: RestoreKind.onboarding));
    await reach(RestorePhase.preview);
    bloc.add(const RestoreConfirmed());
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(reboots, [true]);
  });

  test('menyiapkan gagal (ruang penuh): galat space, tidak memulai ulang', () async {
    gateway.stageFailure = BackupFailureCodes.space;
    bloc.add(fileStart());
    await reach(RestorePhase.preview);
    bloc.add(const RestoreConfirmed());
    final state = await reach(RestorePhase.error);
    expect(state.error, RestoreErrorKind.space);
    expect(reboots, isEmpty);
  });

  test('Ganti data hanya berlaku dari pratinjau: dua kali ditekan hanya menyiapkan sekali', () async {
    final hold = gateway.holdStage = Completer<void>();
    bloc.add(fileStart());
    await reach(RestorePhase.preview);
    bloc
      ..add(const RestoreConfirmed())
      ..add(const RestoreConfirmed());
    await reach(RestorePhase.running);
    hold.complete();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(gateway.staged, hasLength(1));
    expect(reboots, hasLength(1));
  });

  test('Pilih berkas lain dari galat: memeriksa berkas baru; pemilih ditutup tidak mengubah apa pun', () async {
    gateway.inspectFailure = BackupFailureCodes.invalid;
    bloc.add(fileStart());
    await reach(RestorePhase.error);

    bloc.add(const RestoreOtherFileRequested());
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(bloc.state.phase, RestorePhase.error, reason: 'pemilih ditutup tanpa memilih');

    gateway.inspectFailure = null;
    transfer.picked = Uint8List.fromList([9]);
    bloc.add(const RestoreOtherFileRequested());
    await reach(RestorePhase.preview);
    expect(gateway.inspected, 2);
  });
}
