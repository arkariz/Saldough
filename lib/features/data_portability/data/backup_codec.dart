import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:saldough/features/data_portability/domain/backup_failure_codes.dart';
import 'package:saldough/features/data_portability/domain/backup_summary.dart';

/// Isi cadangan yang sudah dibuka dan lolos pemeriksaan amplop.
final class BackupContents {
  /// Membuat [BackupContents].
  const BackupContents({
    required this.formatVersion,
    required this.createdAt,
    required this.appVersion,
    required this.appBuild,
    required this.docs,
  });

  /// Versi amplop.
  final int formatVersion;

  /// Saat cadangan dibuat.
  final DateTime createdAt;

  /// Versi aplikasi pembuat (`0.8.0`).
  final String appVersion;

  /// Nomor build aplikasi pembuat.
  final int appBuild;

  /// Dokumen penyimpanan apa adanya: `kunci → string tersimpan`.
  final Map<String, String> docs;
}

/// Kodek berkas cadangan (ADR-040 §3.2): `gzip(utf8(JSON))` dengan amplop
/// berversi dan checksum SHA-256.
abstract final class BackupCodec {
  /// Penanda jenis di amplop.
  static const format = 'tanukonomy-backup';

  /// Versi amplop yang ditulis dan dikenal aplikasi ini.
  static const formatVersion = 1;

  /// Ekstensi berkas cadangan.
  static const extension = 'tkbak';

  /// Batas ukuran sesudah dekompresi, melindungi dari berkas yang sengaja
  /// dibuat membengkak.
  static const int maxDecodedBytes = 256 * 1024 * 1024;

  /// SHA-256 (heksadesimal) atas [docs]: untuk tiap kunci terurut naik,
  /// `utf8(kunci) 0x00 utf8(nilai) 0x00`. Tidak bergantung pada format JSON.
  static String checksum(Map<String, String> docs) {
    final out = BytesBuilder(copy: false);
    for (final key in docs.keys.toList()..sort()) {
      out
        ..add(utf8.encode(key))
        ..addByte(0)
        ..add(utf8.encode(docs[key]!))
        ..addByte(0);
    }
    return sha256.convert(out.toBytes()).toString();
  }

  /// Menyusun berkas cadangan dari [docs].
  static Uint8List encode({
    required Map<String, String> docs,
    required DateTime createdAt,
    required String appVersion,
    required int appBuild,
    required BackupSummary summary,
  }) {
    final envelope = <String, Object?>{
      'format': format,
      'formatVersion': formatVersion,
      // UTC supaya tidak ambigu antar perangkat dan zona waktu (B-51).
      'createdAt': createdAt.toUtc().toIso8601String(),
      'app': {'version': appVersion, 'build': appBuild},
      'summary': summary.toJson(),
      'docs': docs,
      'sha256': checksum(docs),
    };
    return Uint8List.fromList(gzip.encode(utf8.encode(jsonEncode(envelope))));
  }

  /// Membuka [bytes]. Melempar [BackupException]: `invalid` untuk bukan
  /// cadangan, rusak, atau checksum tidak cocok; `newer` untuk amplop versi
  /// lebih baru.
  static BackupContents decode(Uint8List bytes) {
    final Map<String, dynamic> json;
    try {
      final raw = gzip.decode(bytes);
      if (raw.length > maxDecodedBytes) {
        throw const BackupException(BackupFailureCodes.invalid, 'melebihi batas ukuran');
      }
      final decoded = jsonDecode(utf8.decode(raw));
      if (decoded is! Map<String, dynamic>) {
        throw const BackupException(BackupFailureCodes.invalid, 'amplop bukan objek');
      }
      json = decoded;
    } on BackupException {
      rethrow;
    } catch (e) {
      throw BackupException(BackupFailureCodes.invalid, 'tidak bisa dibuka: $e');
    }

    if (json['format'] != format) {
      throw const BackupException(BackupFailureCodes.invalid, 'bukan cadangan Tanukonomy');
    }
    final version = json['formatVersion'];
    if (version is! int) throw const BackupException(BackupFailureCodes.invalid, 'formatVersion hilang');
    if (version > formatVersion) {
      throw BackupException(BackupFailureCodes.newer, 'formatVersion $version > $formatVersion');
    }

    try {
      final rawDocs = json['docs'] as Map<String, dynamic>;
      final docs = {for (final e in rawDocs.entries) e.key: e.value as String};
      if (json['sha256'] != checksum(docs)) {
        throw const BackupException(BackupFailureCodes.invalid, 'checksum tidak cocok');
      }
      final app = json['app'] as Map<String, dynamic>;
      return BackupContents(
        formatVersion: version,
        createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
        appVersion: app['version'] as String,
        appBuild: app['build'] as int,
        docs: docs,
      );
    } on BackupException {
      rethrow;
    } catch (e) {
      throw BackupException(BackupFailureCodes.invalid, 'amplop tidak lengkap: $e');
    }
  }
}
