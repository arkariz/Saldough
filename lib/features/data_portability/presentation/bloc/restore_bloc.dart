import 'dart:async';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/data_portability/domain/backup_failure_codes.dart';
import 'package:saldough/features/data_portability/domain/file_transfer.dart';
import 'package:saldough/features/data_portability/domain/restore_gateway.dart';
import 'package:saldough/features/data_portability/domain/restore_models.dart';
import 'package:saldough/features/data_portability/domain/restore_reboot.dart';
import 'package:saldough/features/data_portability/presentation/bloc/restore_state.dart';
import 'package:state_management/state_management.dart';

part 'restore_event.dart';

/// Bloc alur pulihkan (EXPORT_BACKUP §7.1): periksa → pratinjau → (dialog di
/// UI) → siapkan penggantian → mulai ulang aplikasi.
///
/// Bloc ini tidak pernah menulis data hidup. [RestoreConfirmed] hanya
/// menyiapkan penggantian dan memicu boot ulang; penerapan dilakukan jalur
/// pemulihan jurnal di bootstrap (ADR-040 §3.4).
final class RestoreBloc extends Bloc<RestoreEvent, RestoreState> {
  /// Membuat [RestoreBloc].
  RestoreBloc({required this._gateway, required this._transfer, required this._reboot}) : super(const RestoreState()) {
    on<RestoreStarted>(_onStarted);
    on<RestoreOtherFileRequested>(_onOtherFile);
    on<RestoreConfirmed>(_onConfirmed);
  }

  final RestoreGateway _gateway;
  final FileTransfer _transfer;
  final RestoreReboot _reboot;

  Future<void> _onStarted(RestoreStarted event, Emitter<RestoreState> emit) async {
    emit(state.copyWith(phase: RestorePhase.inspecting, source: event.source));
    final bytes = event.bytes;
    final result = event.source == RestoreKind.undo || bytes == null
        ? await _gateway.inspectSafetyCopy()
        : (await _gateway.inspect(bytes, source: event.source)).map<RestoreSession?>((s) => s);
    _showInspection(emit, result);
  }

  Future<void> _onOtherFile(RestoreOtherFileRequested event, Emitter<RestoreState> emit) async {
    final bytes = await _transfer.pickBackup();
    // Pemilih ditutup: tetap di halaman galat.
    if (bytes == null) return;
    emit(state.copyWith(phase: RestorePhase.inspecting, error: () => null));
    _showInspection(emit, (await _gateway.inspect(bytes)).map<RestoreSession?>((s) => s));
  }

  void _showInspection(Emitter<RestoreState> emit, Either<Failure, RestoreSession?> result) {
    switch (result) {
      case Left(value: final failure):
        developer.log('Pemeriksaan cadangan gagal', error: failure.message, name: 'RestoreBloc');
        emit(state.copyWith(phase: RestorePhase.error, error: () => _kindOf(failure)));
      case Right(value: null):
        emit(state.copyWith(phase: RestorePhase.error, error: () => RestoreErrorKind.other));
      case Right(value: final session?):
        emit(state.copyWith(phase: RestorePhase.preview, session: () => session, error: () => null));
    }
  }

  Future<void> _onConfirmed(RestoreConfirmed event, Emitter<RestoreState> emit) async {
    final session = state.session;
    if (state.phase != RestorePhase.preview || session == null) return;
    emit(state.copyWith(phase: RestorePhase.running));
    switch (await _gateway.stage(session)) {
      case Left(value: final failure):
        developer.log('Penyiapan pemulihan gagal', error: failure.message, name: 'RestoreBloc');
        emit(state.copyWith(phase: RestorePhase.error, error: () => _kindOf(failure)));
      case Right():
        // Data hidup belum disentuh sampai di sini. Boot ulang menjalankan
        // jalur pemulihan jurnal yang menerapkan penggantian.
        unawaited(_reboot(onboarding: session.preview.source == RestoreKind.onboarding));
    }
  }

  static RestoreErrorKind _kindOf(Failure failure) => switch (failure.code) {
    BackupFailureCodes.invalid || BackupFailureCodes.inconsistent => RestoreErrorKind.invalid,
    BackupFailureCodes.newer => RestoreErrorKind.newer,
    BackupFailureCodes.space => RestoreErrorKind.space,
    _ => RestoreErrorKind.other,
  };
}
