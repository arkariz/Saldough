import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/data_portability/domain/file_transfer.dart';
import 'package:saldough/features/data_portability/presentation/bloc/backup_bloc.dart';
import 'package:saldough/features/data_portability/presentation/bloc/backup_state.dart';

import '../../helpers/fake_backup_gateway.dart';
import '../../helpers/fake_file_transfer.dart';

/// Alur lembar cadangkan (EXPORT_BACKUP §6.1): ringkasan → proses → siap →
/// simpan atau bagikan; "Cadangan terakhir" hanya bila tersimpan.
void main() {
  late FakeBackupGateway gateway;
  late FakeFileTransfer transfer;
  late BackupBloc bloc;

  setUp(() {
    gateway = FakeBackupGateway();
    transfer = FakeFileTransfer();
    bloc = BackupBloc(gateway: gateway, transfer: transfer);
  });

  tearDown(() => bloc.close());

  Future<void> reach(BackupPhase phase) => bloc.stream.firstWhere((s) => s.phase == phase);

  Future<void> toReady() async {
    bloc.add(const BackupStarted());
    await reach(BackupPhase.form);
    bloc.add(const BackupRequested());
    await reach(BackupPhase.ready);
  }

  test('dibuka: ringkasan dihitung dan tahap form', () async {
    bloc.add(const BackupStarted());
    final state = await bloc.stream.firstWhere((s) => s.phase == BackupPhase.form);
    expect(state.summary!.transactions, 142);
  });

  test('Cadangkan: busy lalu ready dengan berkas', () async {
    await toReady();
    expect(bloc.state.file!.name, 'tanukonomy-cadangan-2026-10-22.tkbak');
  });

  test('Simpan ke… yang berhasil: berkas disimpan, Cadangan terakhir dicatat, lembar selesai', () async {
    await toReady();
    bloc.add(const BackupSaveRequested());
    await bloc.stream.firstWhere((s) => s.finished);
    expect(transfer.saved, ['tanukonomy-cadangan-2026-10-22.tkbak']);
    expect(gateway.recorded, 1);
  });

  test('lembar simpan dibatalkan: catatan belum tersimpan, status tidak berubah, lembar tetap terbuka', () async {
    transfer.saveOutcome = TransferOutcome.cancelled;
    await toReady();
    bloc.add(const BackupSaveRequested());
    final state = await bloc.stream.firstWhere((s) => s.notSaved);
    expect(state.finished, isFalse);
    expect(gateway.recorded, 0);
    expect(gateway.lastBackup, isNull);
  });

  test('Bagikan yang tak terkonfirmasi: lembar selesai tetapi Cadangan terakhir TIDAK dicatat', () async {
    transfer.shareOutcome = TransferOutcome.unconfirmed;
    await toReady();
    bloc.add(const BackupShareRequested());
    await bloc.stream.firstWhere((s) => s.finished);
    expect(gateway.recorded, 0);
  });

  test('Bagikan yang berhasil mencatat Cadangan terakhir', () async {
    await toReady();
    bloc.add(const BackupShareRequested());
    await bloc.stream.firstWhere((s) => s.finished);
    expect(gateway.recorded, 1);
  });

  test('Batal saat busy: kembali ke form dan hasil yang menyusul dibuang', () async {
    final hold = gateway.holdCreate = Completer<void>();
    bloc.add(const BackupStarted());
    await reach(BackupPhase.form);
    bloc.add(const BackupRequested());
    await reach(BackupPhase.busy);
    bloc.add(const BackupCancelRequested());
    await reach(BackupPhase.form);
    hold.complete();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(bloc.state.phase, BackupPhase.form);
    expect(bloc.state.file, isNull, reason: 'hasil yang selesai sesudah batal dibuang');
  });

  test('gagal dibuat: kembali ke form dengan efek galat, tanpa berkas', () async {
    gateway.failCreate = true;
    bloc.add(const BackupStarted());
    await reach(BackupPhase.form);
    bloc.add(const BackupRequested());
    final state = await bloc.stream.firstWhere((s) => s.effect != null);
    expect(state.phase, BackupPhase.form);
    expect(state.file, isNull);
  });

  test('galat saat menyimpan tidak menutup lembar dan tidak mencatat Cadangan terakhir', () async {
    transfer.error = StateError('disk penuh');
    await toReady();
    bloc.add(const BackupSaveRequested());
    final state = await bloc.stream.firstWhere((s) => s.effect != null);
    expect(state.finished, isFalse);
    expect(gateway.recorded, 0);
  });
}
