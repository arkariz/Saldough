import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/data_portability/data/backup_codec.dart';
import 'package:saldough/features/data_portability/domain/backup_failure_codes.dart';
import 'package:saldough/features/data_portability/domain/backup_summary.dart';

import '../../helpers/backup_docs.dart';
import '../../helpers/backup_matchers.dart';

/// Kodek berkas cadangan (ADR-040 §3.2).
void main() {
  const summary = BackupSummary(transactions: 1, wallets: 2, firstDate: '2026-10-03', currency: 'IDR');
  final createdAt = DateTime(2026, 10, 22, 9, 12);

  Uint8List encode([Map<String, String>? docs]) => BackupCodec.encode(
    docs: docs ?? sampleDocs(),
    createdAt: createdAt,
    appVersion: '0.8.0',
    appBuild: 14,
    summary: summary,
  );

  test('bolak-balik: dokumen kembali persis, termasuk nilai yang sama persis', () {
    final docs = sampleDocs();
    final contents = BackupCodec.decode(encode(docs));
    expect(contents.docs, docs);
    expect(contents.formatVersion, BackupCodec.formatVersion);
    expect(contents.createdAt, createdAt);
    expect(contents.appVersion, '0.8.0');
    expect(contents.appBuild, 14);
  });

  test('berkas berupa gzip dengan amplop berversi', () {
    final envelope = jsonDecode(utf8.decode(gzip.decode(encode()))) as Map<String, dynamic>;
    expect(envelope['format'], 'tanukonomy-backup');
    expect(envelope['formatVersion'], 1);
    expect(envelope['summary'], summary.toJson());
    expect(envelope['sha256'], BackupCodec.checksum(sampleDocs()));
  });

  test('checksum tidak bergantung urutan kunci, dan berubah bila satu nilai berubah', () {
    final docs = sampleDocs();
    final reversed = {for (final k in docs.keys.toList().reversed) k: docs[k]!};
    expect(BackupCodec.checksum(reversed), BackupCodec.checksum(docs));
    expect(BackupCodec.checksum(sampleDocs(amount: 101)), isNot(BackupCodec.checksum(docs)));
  });

  test('checksum memisahkan kunci dari nilai: ("a","bc") berbeda dari ("ab","c")', () {
    expect(BackupCodec.checksum({'a': 'bc'}), isNot(BackupCodec.checksum({'ab': 'c'})));
  });

  test('bukan gzip, kosong, dan JSON bukan objek ditolak sebagai invalid', () {
    expect(() => BackupCodec.decode(Uint8List.fromList(utf8.encode('halo'))), throwsBackup(BackupFailureCodes.invalid));
    expect(() => BackupCodec.decode(Uint8List(0)), throwsBackup(BackupFailureCodes.invalid));
    expect(
      () => BackupCodec.decode(Uint8List.fromList(gzip.encode(utf8.encode('[1,2]')))),
      throwsBackup(BackupFailureCodes.invalid),
    );
  });

  test('berkas dipotong atau satu byte berubah ditolak sebagai invalid', () {
    final bytes = encode();
    expect(() => BackupCodec.decode(bytes.sublist(0, bytes.length ~/ 2)), throwsBackup(BackupFailureCodes.invalid));
    final flipped = Uint8List.fromList(bytes)..[bytes.length ~/ 2] ^= 0xFF;
    expect(() => BackupCodec.decode(flipped), throwsBackup(BackupFailureCodes.invalid));
  });

  test('checksum yang tidak cocok ditolak walau gzip utuh', () {
    final envelope = jsonDecode(utf8.decode(gzip.decode(encode()))) as Map<String, dynamic>;
    (envelope['docs'] as Map<String, dynamic>)['wallet_all'] = '{"schemaVersion":1,"items":[]}';
    final tampered = Uint8List.fromList(gzip.encode(utf8.encode(jsonEncode(envelope))));
    expect(() => BackupCodec.decode(tampered), throwsBackup(BackupFailureCodes.invalid));
  });

  test('amplop dari jenis lain ditolak invalid; formatVersion lebih baru ditolak newer', () {
    Uint8List wrap(Map<String, dynamic> patch) {
      final envelope = jsonDecode(utf8.decode(gzip.decode(encode()))) as Map<String, dynamic>..addAll(patch);
      return Uint8List.fromList(gzip.encode(utf8.encode(jsonEncode(envelope))));
    }

    expect(() => BackupCodec.decode(wrap({'format': 'lain'})), throwsBackup(BackupFailureCodes.invalid));
    expect(() => BackupCodec.decode(wrap({'formatVersion': 2})), throwsBackup(BackupFailureCodes.newer));
    expect(() => BackupCodec.decode(wrap({'formatVersion': 'satu'})), throwsBackup(BackupFailureCodes.invalid));
  });
}
