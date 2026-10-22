import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:saldough/features/data_portability/domain/file_transfer.dart';
import 'package:share_plus/share_plus.dart';

/// [FileTransfer] di atas `file_picker` (simpan dan pilih) dan `share_plus`
/// (bagikan) (ADR-040 §3.8). Berkas yang dibagikan ditulis sementara di cache
/// aplikasi, dihapus sesudahnya, dan disapu tiap bootstrap karena isinya data
/// keuangan.
final class PlatformFileTransfer implements FileTransfer {
  /// Membuat [PlatformFileTransfer].
  const PlatformFileTransfer();

  static const _tempFolder = 'tanukonomy_berbagi';

  @override
  Future<TransferOutcome> saveAs({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final saved = await FilePicker.saveFile(fileName: fileName, bytes: bytes, mimeType: mimeType);
    return saved == null ? TransferOutcome.cancelled : TransferOutcome.done;
  }

  @override
  Future<TransferOutcome> share({required String fileName, required Uint8List bytes, required String mimeType}) async {
    final directory = Directory('${(await getTemporaryDirectory()).path}/$_tempFolder');
    await directory.create(recursive: true);
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    try {
      final result = await SharePlus.instance.share(ShareParams(files: [XFile(file.path, mimeType: mimeType)]));
      return switch (result.status) {
        ShareResultStatus.success => TransferOutcome.done,
        ShareResultStatus.dismissed => TransferOutcome.cancelled,
        ShareResultStatus.unavailable => TransferOutcome.unconfirmed,
      };
    } finally {
      try {
        await file.delete();
      } on FileSystemException {
        // Disapu bootstrap berikutnya.
      }
    }
  }

  @override
  Future<Uint8List?> pickBackup() async {
    final picked = await FilePicker.pickFile();
    return picked?.readAsBytes();
  }

  /// Menghapus sisa berkas bagi di cache; dipanggil bootstrap. Gagal tidak
  /// dilaporkan ke pengguna.
  static Future<void> sweepTemp() async {
    try {
      final directory = Directory('${(await getTemporaryDirectory()).path}/$_tempFolder');
      if (directory.existsSync()) await directory.delete(recursive: true);
    } on Object catch (e) {
      developer.log('Sapu berkas bagi gagal', error: e, name: 'PlatformFileTransfer');
    }
  }
}
