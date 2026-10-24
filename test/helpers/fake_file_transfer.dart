import 'dart:typed_data';

import 'package:saldough/features/data_portability/domain/file_transfer.dart';

/// [FileTransfer] palsu: mencatat apa yang disimpan atau dibagikan.
final class FakeFileTransfer implements FileTransfer {
  /// Hasil yang dikembalikan `saveAs`.
  TransferOutcome saveOutcome = TransferOutcome.done;

  /// Hasil yang dikembalikan `share`.
  TransferOutcome shareOutcome = TransferOutcome.done;

  /// Isi yang dikembalikan `pickBackup`.
  Uint8List? picked;

  /// Bila di-set, `saveAs` dan `share` melempar ini.
  Object? error;

  /// Nama berkas yang disimpan.
  final saved = <String>[];

  /// Nama berkas yang dibagikan.
  final shared = <String>[];

  /// Isi terakhir yang disimpan atau dibagikan.
  Uint8List? lastBytes;

  @override
  Future<TransferOutcome> saveAs({required String fileName, required Uint8List bytes, required String mimeType}) async {
    // Palsu: melempar apa pun yang diminta uji.
    // ignore: only_throw_errors
    if (error != null) throw error!;
    saved.add(fileName);
    lastBytes = bytes;
    return saveOutcome;
  }

  @override
  Future<TransferOutcome> share({required String fileName, required Uint8List bytes, required String mimeType}) async {
    // Palsu: melempar apa pun yang diminta uji.
    // ignore: only_throw_errors
    if (error != null) throw error!;
    shared.add(fileName);
    lastBytes = bytes;
    return shareOutcome;
  }

  @override
  Future<Uint8List?> pickBackup() async => picked;
}
