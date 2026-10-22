import 'dart:async';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:dependencies/dependencies.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/data_portability/domain/backup_failure_codes.dart';
import 'package:saldough/features/data_portability/domain/export_gateway.dart';
import 'package:saldough/features/data_portability/domain/export_models.dart';
import 'package:saldough/features/data_portability/domain/file_transfer.dart';
import 'package:saldough/features/data_portability/presentation/bloc/export_state.dart';
import 'package:state_management/state_management.dart';

part 'export_event.dart';

/// Bloc lembar ekspor ke spreadsheet (EXPORT_BACKUP §5.1). Selalu seluruh data
/// saat ini; tanpa pilihan rentang.
final class ExportBloc extends Bloc<ExportEvent, ExportState> {
  /// Membuat [ExportBloc].
  ExportBloc({required this._service, required this._transfer}) : super(const ExportState()) {
    on<ExportStarted>(_onStarted);
    on<ExportFormatChanged>((event, emit) => emit(state.copyWith(format: event.format)));
    on<ExportRequested>(_onRequested);
    on<ExportCancelRequested>(_onCancel);
    on<ExportSaveRequested>((event, emit) => _deliver(emit, _transfer.saveAs));
    on<ExportShareRequested>((event, emit) => _deliver(emit, _transfer.share));
  }

  final ExportGateway _service;
  final FileTransfer _transfer;
  ExportCancel? _running;

  UiEffect get _errorEffect => ShowSnackBarEffect(message: t.dataPortability.exportError, severity: .error);

  Future<void> _onStarted(ExportStarted event, Emitter<ExportState> emit) async {
    switch (await _service.preview()) {
      case Left():
        emit(state.copyWith(phase: ExportPhase.form, effect: _errorEffect));
      case Right(value: final preview):
        emit(state.copyWith(phase: preview.count == 0 ? ExportPhase.empty : ExportPhase.form, preview: preview));
    }
  }

  Future<void> _onRequested(ExportRequested event, Emitter<ExportState> emit) async {
    if (state.phase != ExportPhase.form) return;
    final cancel = _running = ExportCancel();
    emit(state.copyWith(phase: ExportPhase.busy, notSaved: false));
    final result = await _service.export(state.format, cancel: cancel);
    // Dibatalkan pengguna: hasilnya dibuang, lembar sudah kembali ke form.
    if (cancel.isCancelled) return;
    _running = null;
    switch (result) {
      case Right(value: final file):
        AppAnalytics.log(
          DataPortabilityEvents.exportCreated(format: file.format.name, rows: state.preview?.count ?? 0),
        );
        emit(state.copyWith(phase: ExportPhase.ready, file: () => file));
      case Left(value: final failure) when failure.code == BackupFailureCodes.emptyExport:
        emit(state.copyWith(phase: ExportPhase.empty));
      case Left(value: final failure):
        developer.log('Ekspor gagal', error: failure.message, name: 'ExportBloc');
        emit(state.copyWith(phase: ExportPhase.form, effect: _errorEffect));
    }
  }

  void _onCancel(ExportCancelRequested event, Emitter<ExportState> emit) {
    _running?.cancel();
    _running = null;
    emit(state.copyWith(phase: ExportPhase.form));
  }

  Future<void> _deliver(
    Emitter<ExportState> emit,
    Future<TransferOutcome> Function({required String fileName, required Uint8List bytes, required String mimeType})
    action,
  ) async {
    final file = state.file;
    if (file == null) return;
    try {
      final outcome = await action(fileName: file.name, bytes: file.bytes, mimeType: file.format.mimeType);
      emit(
        outcome == TransferOutcome.cancelled ? state.copyWith(notSaved: true) : state.copyWith(finished: true),
      );
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
