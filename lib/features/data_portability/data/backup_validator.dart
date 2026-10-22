// Dokumen yang tidak bisa diurai berarti cadangan rusak (R-1/R-3).
// ignore_for_file: avoid_catches_without_on_clauses

import 'dart:convert';

import 'package:saldough/features/data_portability/data/backup_codec.dart';
import 'package:saldough/features/data_portability/domain/backup_failure_codes.dart';
import 'package:saldough/features/data_portability/domain/backup_registry.dart';
import 'package:saldough/features/data_portability/domain/backup_summary.dart';

/// Memeriksa isi cadangan sebelum ada yang ditulis (R-1–R-3, ADR-040 §3.4
/// langkah 1) dan menghitung ringkasannya dari dokumen.
abstract final class BackupValidator {
  /// Melempar [BackupException] bila [contents] tidak boleh dipulihkan:
  /// kunci tidak dikenal atau `schemaVersion` lebih baru → `newer`; dokumen
  /// tidak bisa diurai atau rujukan tidak utuh → `invalid`/`inconsistent`.
  static void validate(BackupContents contents, BackupRegistry registry) {
    final docs = contents.docs;
    final parsed = <String, Map<String, dynamic>>{};

    for (final entry in docs.entries) {
      final spec = registry.specOf(entry.key);
      if (!spec.isIncluded) {
        throw BackupException(BackupFailureCodes.newer, 'kunci tidak dikenal: ${entry.key}');
      }
      final Object? json;
      try {
        json = jsonDecode(entry.value);
      } catch (e) {
        throw BackupException(BackupFailureCodes.invalid, '${entry.key} bukan JSON: $e');
      }
      if (json is! Map<String, dynamic>) {
        throw BackupException(BackupFailureCodes.invalid, '${entry.key} bukan objek');
      }
      final supported = spec.schema;
      if (supported != null) {
        final version = json['schemaVersion'];
        if (version is int && version > supported) {
          throw BackupException(BackupFailureCodes.newer, '${entry.key} schemaVersion $version > $supported');
        }
      }
      parsed[entry.key] = json;
    }

    _checkPartitions(parsed, registry);
    for (final reference in registry.references) {
      _checkReference(parsed, reference);
    }
  }

  static void _checkPartitions(Map<String, Map<String, dynamic>> parsed, BackupRegistry registry) {
    final indexed = <String>{
      for (final m in parsed[registry.transactionIndexKey]?['months'] as List<dynamic>? ?? const [])
        if (m is String) m,
    };
    final present = <String>{
      for (final key in parsed.keys)
        if (key.startsWith(registry.transactionPartitionPrefix) &&
            BackupRegistry.isMonth(key.substring(registry.transactionPartitionPrefix.length)))
          key.substring(registry.transactionPartitionPrefix.length),
    };
    final missing = indexed.difference(present);
    if (missing.isNotEmpty) {
      throw BackupException(BackupFailureCodes.inconsistent, 'bulan di indeks tanpa dokumen: $missing');
    }
    final unlisted = present.difference(indexed);
    if (unlisted.isNotEmpty) {
      throw BackupException(BackupFailureCodes.inconsistent, 'dokumen bulan tanpa indeks: $unlisted');
    }
  }

  static void _checkReference(Map<String, Map<String, dynamic>> parsed, BackupReference reference) {
    final targetIds = {for (final item in _items(parsed[reference.target])) item['id']};
    final isPrefix = reference.from.endsWith('*');
    final prefix = isPrefix ? reference.from.substring(0, reference.from.length - 1) : reference.from;
    for (final entry in parsed.entries) {
      if (isPrefix ? !entry.key.startsWith(prefix) : entry.key != prefix) continue;
      for (final item in _items(entry.value)) {
        for (final field in reference.fields) {
          final value = item[field];
          if (value is String && !targetIds.contains(value)) {
            throw BackupException(
              BackupFailureCodes.inconsistent,
              '${entry.key}.$field merujuk $value yang tidak ada di ${reference.target}',
            );
          }
        }
      }
    }
  }

  static Iterable<Map<String, dynamic>> _items(Map<String, dynamic>? doc) sync* {
    for (final item in doc?['items'] as List<dynamic>? ?? const []) {
      if (item is Map<String, dynamic>) yield item;
    }
  }

  /// Ringkasan isi [docs], dihitung dari dokumen (bukan dari amplop).
  static BackupSummary summarize(Map<String, String> docs, BackupRegistry registry) {
    var transactions = 0;
    String? first;
    for (final entry in docs.entries) {
      if (!entry.key.startsWith(registry.transactionPartitionPrefix)) continue;
      if (!BackupRegistry.isMonth(entry.key.substring(registry.transactionPartitionPrefix.length))) continue;
      for (final item in _items(_tryParse(entry.value))) {
        transactions++;
        final date = item['date'];
        if (date is String && date.length >= 10) {
          final day = date.substring(0, 10);
          if (first == null || day.compareTo(first) < 0) first = day;
        }
      }
    }
    final wallets = _items(_tryParse(docs[registry.walletsKey])).length;
    final currency = _tryParse(docs[registry.currencyKey])?['code'];
    return BackupSummary(
      transactions: transactions,
      wallets: wallets,
      firstDate: first,
      currency: currency is String ? currency : null,
    );
  }

  static Map<String, dynamic>? _tryParse(String? doc) {
    if (doc == null) return null;
    try {
      final json = jsonDecode(doc);
      return json is Map<String, dynamic> ? json : null;
    } catch (_) {
      return null;
    }
  }
}
