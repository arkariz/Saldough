import 'dart:convert';
import 'dart:isolate';

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/data_portability/data/export_service.dart';
import 'package:saldough/features/data_portability/domain/backup_failure_codes.dart';
import 'package:saldough/features/data_portability/domain/export_data.dart';
import 'package:saldough/features/data_portability/domain/export_models.dart';

import '../../helpers/export_fixtures.dart';

/// Sumber yang memegang objek yang tidak bisa dikirim antar isolate, seperti
/// kotak Hive di repositori sungguhan.
class _UnsendableSource extends _Source {
  _UnsendableSource(super.result);

  final ReceivePort port = ReceivePort();
}

class _Source implements ExportDataSource {
  _Source(this.result);

  Either<Failure, ExportData> result;
  int loads = 0;

  @override
  Future<Either<Failure, ExportData>> load() async {
    loads++;
    return result;
  }
}

/// Ekspor seluruh data saat ini (E-1–E-6, ADR-040 §3.6).
void main() {
  final now = DateTime(2026, 10, 22, 9);
  var source = _Source(right(sampleExportData()));
  ExportService service() => ExportService(source: source, labels: () => idLabels, now: () => now);

  setUp(() => source = _Source(right(sampleExportData())));

  test('preview: jumlah transaksi dan rentang tanggal paling awal sampai paling akhir', () async {
    final preview = (await service().preview()).getOrElse((_) => throw StateError('Left'));
    expect(preview.count, 3);
    expect(preview.firstDate, DateTime(2026, 9, 23));
    expect(preview.lastDate, DateTime(2026, 9, 26));
  });

  test('preview tanpa transaksi: nol dan tanpa tanggal', () async {
    source = _Source(right(sampleExportData(transactions: const [])));
    final preview = (await service().preview()).getOrElse((_) => throw StateError('Left'));
    expect((preview.count, preview.firstDate, preview.lastDate), (0, null, null));
  });

  test('xlsx: nama berkas memuat tanggal hari ekspor, tipe MIME benar, isi ZIP', () async {
    final file = (await service().export(ExportFormat.xlsx)).getOrElse((_) => throw StateError('Left'));
    expect(file.name, 'tanukonomy-ekspor-2026-10-22.xlsx');
    expect(file.format.mimeType, contains('spreadsheetml.sheet'));
    expect(file.rowCount, 3);
    expect(file.bytes.sublist(0, 2), [0x50, 0x4B], reason: 'tanda ZIP "PK"');
  });

  test('csv: ekstensi .csv, BOM, dan baris judul', () async {
    final file = (await service().export(ExportFormat.csv)).getOrElse((_) => throw StateError('Left'));
    expect(file.name, 'tanukonomy-ekspor-2026-10-22.csv');
    expect(file.bytes.sublist(0, 3), [0xEF, 0xBB, 0xBF]);
    expect(utf8.decode(file.bytes.sublist(3)).split('\r\n').first, startsWith('Tanggal,Awal periode'));
  });

  test('layanan yang memegang objek tak-terkirim (kotak Hive) tetap bisa membangun berkas di isolate', () async {
    // Regresi: closure Isolate.run ikut membawa `this` (sumber data berisi
    // repositori sungguhan) sehingga ekspor gagal di perangkat.
    final unsendable = _UnsendableSource(right(sampleExportData()));
    addTearDown(unsendable.port.close);
    final result = await ExportService(
      source: unsendable,
      labels: () => idLabels,
      now: () => now,
    ).export(ExportFormat.xlsx);
    expect(result.isRight(), isTrue, reason: result.fold((f) => f.message, (_) => ''));
  });

  test('belum ada transaksi: emptyExport, tanpa membangun berkas', () async {
    source = _Source(right(sampleExportData(transactions: const [])));
    final result = await service().export(ExportFormat.xlsx);
    expect(result.swap().getOrElse((_) => throw StateError('Right')).code, BackupFailureCodes.emptyExport);
  });

  test('dibatalkan sebelum mulai: cancelled, bukan galat berkas', () async {
    final cancel = ExportCancel()..cancel();
    final result = await service().export(ExportFormat.xlsx, cancel: cancel);
    expect(result.swap().getOrElse((_) => throw StateError('Right')).code, BackupFailureCodes.cancelled);
  });

  test('galat membaca data diteruskan apa adanya', () async {
    const failure = SystemFailure(code: FailureCode('X'), message: 'baca gagal');
    source = _Source(left(failure));
    final result = await service().export(ExportFormat.xlsx);
    expect(result.swap().getOrElse((_) => throw StateError('Right')), failure);
  });
}
