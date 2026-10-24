import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/app/data_portability/app_backup_registry.dart';
import 'package:saldough/features/data_portability/data/backup_codec.dart';
import 'package:saldough/features/data_portability/data/backup_validator.dart';
import 'package:saldough/features/data_portability/domain/backup_failure_codes.dart';

import '../../helpers/backup_docs.dart';
import '../../helpers/backup_matchers.dart';

/// Pemeriksaan isi cadangan sebelum pemulihan (R-1–R-3).
void main() {
  BackupContents contents(Map<String, String> docs) => BackupContents(
    formatVersion: 1,
    createdAt: DateTime(2026, 10, 22),
    appVersion: '0.8.0',
    appBuild: 14,
    docs: docs,
  );

  void validate(Map<String, String> docs) => BackupValidator.validate(contents(docs), appBackupRegistry);

  test('cadangan yang utuh lolos', () {
    expect(() => validate(sampleDocs(months: ['2026-09', '2026-10'])), returnsNormally);
  });

  test('cadangan kosong lolos (pengguna tanpa data)', () {
    expect(() => validate({}), returnsNormally);
  });

  test('kunci yang tidak dikenal ditolak sebagai cadangan versi lebih baru (R-2)', () {
    expect(() => validate({...sampleDocs(), 'fitur_baru_all': '{}'}), throwsBackup(BackupFailureCodes.newer));
  });

  test('schemaVersion dokumen lebih baru dari yang didukung ditolak (R-2)', () {
    final docs = sampleDocs();
    docs['wallet_all'] = jsonEncode({'schemaVersion': 99, 'items': <Object?>[]});
    expect(() => validate(docs), throwsBackup(BackupFailureCodes.newer));
  });

  test('schemaVersion sama atau lebih lama diterima', () {
    final docs = sampleDocs();
    docs['transaction_2026-10'] = jsonEncode({
      'schemaVersion': 1,
      'items': [
        {'id': 't', 'type': 'expense', 'date': '2026-10-03T00:00:00.000', 'amount': 1, 'walletId': 'w1'},
      ],
    });
    expect(() => validate(docs), returnsNormally);
  });

  test('dokumen yang bukan JSON atau bukan objek ditolak invalid', () {
    expect(() => validate({'wallet_all': 'bukan json'}), throwsBackup(BackupFailureCodes.invalid));
    expect(() => validate({'wallet_all': '[1]'}), throwsBackup(BackupFailureCodes.invalid));
  });

  test('transaksi merujuk dompet yang tidak ada: inconsistent (R-3)', () {
    final docs = sampleDocs();
    docs['wallet_all'] = jsonEncode({
      'schemaVersion': 1,
      'items': [
        {'id': 'w2', 'name': 'Tunai'},
      ],
    });
    expect(() => validate(docs), throwsBackup(BackupFailureCodes.inconsistent));
  });

  test('transfer merujuk dompet tujuan yang tidak ada: inconsistent', () {
    final docs = sampleDocs();
    docs['transaction_2026-10'] = jsonEncode({
      'schemaVersion': 2,
      'items': [
        {
          'id': 't',
          'type': 'transfer',
          'date': '2026-10-03T00:00:00.000',
          'fromWalletId': 'w1',
          'toWalletId': 'hilang',
        },
      ],
    });
    expect(() => validate(docs), throwsBackup(BackupFailureCodes.inconsistent));
  });

  test('transaksi merujuk kategori yang tidak ada: inconsistent', () {
    final docs = sampleDocs();
    docs['category_all'] = jsonEncode({'schemaVersion': 1, 'items': <Object?>[]});
    expect(() => validate(docs), throwsBackup(BackupFailureCodes.inconsistent));
  });

  test('rutin dan pembayaran freelance dengan rujukan hilang: inconsistent', () {
    final base = sampleDocs();
    expect(
      () => validate({
        ...base,
        'recurring_all': jsonEncode({
          'schemaVersion': 1,
          'items': [
            {'id': 'r', 'walletId': 'hilang'},
          ],
        }),
      }),
      throwsBackup(BackupFailureCodes.inconsistent),
    );
    expect(
      () => validate({
        ...base,
        'freelance_projects': jsonEncode({'schemaVersion': 1, 'items': <Object?>[]}),
        'freelance_payments': jsonEncode({
          'schemaVersion': 1,
          'items': [
            {'id': 'p', 'projectId': 'hilang', 'walletId': 'w1'},
          ],
        }),
      }),
      throwsBackup(BackupFailureCodes.inconsistent),
    );
  });

  test('indeks menyebut bulan tanpa dokumen, atau dokumen bulan tanpa indeks: inconsistent', () {
    final noDoc = sampleDocs(months: ['2026-09', '2026-10'])..remove('transaction_2026-09');
    expect(() => validate(noDoc), throwsBackup(BackupFailureCodes.inconsistent));
    final noIndex = sampleDocs(months: ['2026-10']);
    noIndex['transaction_2026-11'] = jsonEncode({'schemaVersion': 2, 'items': <Object?>[]});
    expect(() => validate(noIndex), throwsBackup(BackupFailureCodes.inconsistent));
  });

  test('ikon sumber yang hilang tidak menggagalkan pemulihan', () {
    final docs = sampleDocs()..remove('source_icon_ic1');
    expect(() => validate(docs), returnsNormally);
  });

  test('ringkasan dihitung dari dokumen: jumlah transaksi, dompet, tanggal awal, mata uang', () {
    final summary = BackupValidator.summarize(sampleDocs(months: ['2026-09', '2026-10']), appBackupRegistry);
    expect(summary.transactions, 2);
    expect(summary.wallets, 2);
    expect(summary.firstDate, '2026-09-03');
    expect(summary.currency, 'IDR');
  });

  test('ringkasan data kosong: nol dan tanpa tanggal', () {
    final summary = BackupValidator.summarize({}, appBackupRegistry);
    expect((summary.transactions, summary.wallets, summary.firstDate, summary.currency), (0, 0, null, null));
  });
}
