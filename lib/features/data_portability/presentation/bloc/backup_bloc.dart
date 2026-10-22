import 'dart:async';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:dependencies/dependencies.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/data_portability/domain/backup_gateway.dart';
import 'package:saldough/features/data_portability/domain/export_models.dart';
import 'package:saldough/features/data_portability/domain/file_transfer.dart';
import 'package:saldough/features/data_portability/presentation/bloc/backup_state.dart';
import 'package:state_management/state_management.dart';

part 'backup_event.dart';

/// MIME berkas cadangan.
const backupMimeType = 'application/octet-stream';

/// Bloc lembar cadangkan sekarang (EXPORT_BACKUP §6.1).
///
/// "Cadangan terakhir" diperbarui hanya bila penyimpanan terkonfirmasi
/// (`TransferOutcome.done`); dibatalkan atau tak terkonfirmasi tidak
/// memperbaruinya (ADR-040 §3.5).
final class BackupBloc extends Bloc<BackupEvent, BackupState> {
  /// Membuat [BackupBloc].
  BackupBloc({required this._gateway, required this._transfer}) : super(const BackupState()) {
    on<BackupStarted>(_onStarted);
    on<BackupRequested>(_onRequested);
    on<BackupCancelRequested>(_onCancel);
    on<BackupSaveRequested>((event, emit) => _deliver(emit, _transfer.saveAs));
    on<BackupShareRequested>((event, emit) => _deliver(emit, _transfer.share));
  }

  final BackupGateway _gateway;
  final FileTransfer _transfer;
  ExportCancel? _running;

  UiEffect get _errorEffect => ShowSnackBarEffect(message: t.dataPortability.backupError, severity: .error);

  Future<void> _onStarted(BackupStarted event, Emitter<BackupState> emit) async {
    switch (await _gateway.summary()) {
      case Left():
        emit(state.copyWith(phase: BackupPhase.form, effect: _errorEffect));
      case Right(value: final summary):
        emit(state.copyWith(phase: BackupPhase.form, summary: summary));
    }
  }

  Future<void> _onRequested(BackupRequested event, Emitter<BackupState> emit) async {
    if (state.phase != BackupPhase.form) return;
    final cancel = _running = ExportCancel();
    emit(state.copyWith(phase: BackupPhase.busy, notSaved: false));
    final result = await _gateway.create(cancel: cancel);
    // Dibatalkan pengguna: hasilnya dibuang, lembar sudah kembali ke form.
    if (cancel.isCancelled) return;
    _running = null;
    switch (result) {
      case Right(value: final file):
        emit(state.copyWith(phase: BackupPhase.ready, file: () => file));
      case Left(value: final failure):
        developer.log('Cadangan gagal dibuat', error: failure.message, name: 'BackupBloc');
        emit(state.copyWith(phase: BackupPhase.form, effect: _errorEffect));
    }
  }

  void _onCancel(BackupCancelRequested event, Emitter<BackupState> emit) {
    _running?.cancel();
    _running = null;
    emit(state.copyWith(phase: BackupPhase.form));
  }

  Future<void> _deliver(
    Emitter<BackupState> emit,
    Future<TransferOutcome> Function({required String fileName, required Uint8List bytes, required String mimeType})
    action,
  ) async {
    final file = state.file;
    if (file == null) return;
    try {
      final outcome = await action(fileName: file.name, bytes: file.bytes, mimeType: backupMimeType);
      // Dicatat sesudah penyimpanan terjawab, bukan saat berkas dibuat:
      // `saved` hanya benar bila terkonfirmasi.
      AppAnalytics.log(
        DataPortabilityEvents.backupCreated(
          rows: state.summary?.transactions ?? 0,
          saved: outcome == TransferOutcome.done,
        ),
      );
      switch (outcome) {
        case TransferOutcome.cancelled:
          emit(state.copyWith(notSaved: true));
        case TransferOutcome.done:
          await _gateway.recordBackup();
          emit(state.copyWith(finished: true));
        case TransferOutcome.unconfirmed:
          emit(state.copyWith(finished: true));
      }
    } on Object {
      emit(state.copyWith(effect: _errorEffect));
    }
  }

  @override
  Future<void> close() {
    _running?.cancel();
    return super.close();
  }
}
