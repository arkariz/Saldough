import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/data_portability/data/export_service.dart';
import 'package:saldough/features/data_portability/domain/export_data.dart';
import 'package:saldough/features/data_portability/domain/export_models.dart';
import 'package:saldough/features/data_portability/domain/file_transfer.dart';
import 'package:saldough/features/data_portability/presentation/bloc/export_bloc.dart';
import 'package:saldough/features/data_portability/presentation/bloc/export_state.dart';

import '../../helpers/export_fixtures.dart';
import '../../helpers/fake_file_transfer.dart';

class _Source implements ExportDataSource {
  _Source(this.data);

  ExportData? data;

  @override
  Future<Either<Failure, ExportData>> load() async =>
      data == null ? left(const SystemFailure(code: FailureCode('X'), message: 'gagal')) : right(data!);
}

/// Alur lembar ekspor (EXPORT_BACKUP §5.1): ringkasan → format → proses →
/// berkas siap → simpan atau bagikan.
void main() {
  late _Source source;
  late FakeFileTransfer transfer;
  late ExportBloc bloc;

  setUp(() {
    source = _Source(sampleExportData());
    transfer = FakeFileTransfer();
    bloc = ExportBloc(
      service: ExportService(source: source, labels: () => idLabels, now: () => DateTime(2026, 10, 22)),
      transfer: transfer,
    );
  });

  tearDown(() => bloc.close());

  Future<void> reach(ExportPhase phase) => bloc.stream.firstWhere((s) => s.phase == phase);

  test('dibuka: ringkasan dihitung, xlsx terpilih bawaan', () async {
    bloc.add(const ExportStarted());
    final state = await bloc.stream.firstWhere((s) => s.phase == ExportPhase.form);
    expect(state.format, ExportFormat.xlsx);
    expect(state.preview!.count, 3);
  });

  test('belum ada transaksi: tahap empty dan Ekspor tidak melakukan apa-apa', () async {
    source.data = sampleExportData(transactions: const []);
    bloc.add(const ExportStarted());
    await reach(ExportPhase.empty);
    bloc.add(const ExportRequested());
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(bloc.state.phase, ExportPhase.empty);
  });

  test('ganti format lalu Ekspor: busy, lalu ready dengan berkas sesuai format', () async {
    bloc.add(const ExportStarted());
    await reach(ExportPhase.form);
    bloc
      ..add(const ExportFormatChanged(ExportFormat.csv))
      ..add(const ExportRequested());
    await reach(ExportPhase.ready);
    expect(bloc.state.file!.name, 'tanukonomy-ekspor-2026-10-22.csv');
    expect(bloc.state.file!.rowCount, 3);
  });

  test('Batal saat busy: kembali ke form dan hasil yang menyusul dibuang', () async {
    bloc.add(const ExportStarted());
    await reach(ExportPhase.form);
    bloc.add(const ExportRequested());
    await reach(ExportPhase.busy);
    bloc.add(const ExportCancelRequested());
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(bloc.state.phase, ExportPhase.form);
    expect(bloc.state.file, isNull);
  });

  test('Simpan ke…: berkas disimpan dengan nama dan isinya, lalu lembar selesai', () async {
    bloc.add(const ExportStarted());
    await reach(ExportPhase.form);
    bloc.add(const ExportRequested());
    await reach(ExportPhase.ready);
    bloc.add(const ExportSaveRequested());
    await bloc.stream.firstWhere((s) => s.finished);
    expect(transfer.saved, ['tanukonomy-ekspor-2026-10-22.xlsx']);
    expect(transfer.lastBytes, bloc.state.file!.bytes);
  });

  test('Bagikan: berkas dibagikan, lalu lembar selesai', () async {
    bloc.add(const ExportStarted());
    await reach(ExportPhase.form);
    bloc.add(const ExportRequested());
    await reach(ExportPhase.ready);
    bloc.add(const ExportShareRequested());
    await bloc.stream.firstWhere((s) => s.finished);
    expect(transfer.shared, hasLength(1));
  });

  test('lembar simpan ditutup tanpa menyimpan: tetap di ready dengan catatan, belum selesai', () async {
    transfer.saveOutcome = TransferOutcome.cancelled;
    bloc.add(const ExportStarted());
    await reach(ExportPhase.form);
    bloc.add(const ExportRequested());
    await reach(ExportPhase.ready);
    bloc.add(const ExportSaveRequested());
    final state = await bloc.stream.firstWhere((s) => s.notSaved);
    expect(state.phase, ExportPhase.ready);
    expect(state.finished, isFalse);
  });

  test('galat saat menyimpan tidak menutup lembar dan memunculkan efek galat', () async {
    transfer.error = StateError('disk penuh');
    bloc.add(const ExportStarted());
    await reach(ExportPhase.form);
    bloc.add(const ExportRequested());
    await reach(ExportPhase.ready);
    bloc.add(const ExportSaveRequested());
    final state = await bloc.stream.firstWhere((s) => s.effect != null);
    expect(state.finished, isFalse);
    expect(state.phase, ExportPhase.ready);
  });

  test('galat membaca data: kembali ke form dengan efek galat, tanpa berkas', () async {
    bloc.add(const ExportStarted());
    await reach(ExportPhase.form);
    source.data = null;
    bloc.add(const ExportRequested());
    final state = await bloc.stream.firstWhere((s) => s.effect != null);
    expect(state.phase, ExportPhase.form);
    expect(state.file, isNull);
  });
}
