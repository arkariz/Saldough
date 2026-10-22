import 'dart:convert';

import 'package:api_storage/api_storage.dart';
import 'package:saldough/features/data_portability/domain/backup_registry.dart';

/// Mengumpulkan seluruh dokumen yang masuk cakupan cadangan (ADR-040 §3.3).
///
/// Satu fungsi dipakai tiga kali: untuk cadangan, untuk salinan pengaman, dan
/// untuk menentukan kunci lama yang dihapus saat penggantian, supaya ketiganya
/// selalu sepaham.
abstract final class BackupScope {
  /// Peta `kunci → string tersimpan` untuk semua kunci [registry] yang ada di
  /// [storage], termasuk partisi transaksi dan ikon sumber.
  ///
  /// `KeyValueStorage` tidak punya daftar kunci, jadi partisi diambil dari
  /// indeks bulan. Setiap bulan di antara bulan pertama dan terakhir indeks
  /// juga diperiksa dengan `contains`, supaya lubang pada indeks tidak
  /// membuat transaksi terlewat diam-diam.
  static Future<Map<String, String>> collect(KeyValueStorage storage, BackupRegistry registry) async {
    final docs = <String, String>{};
    for (final spec in registry.included) {
      final value = await storage.read(spec.key);
      if (value != null) docs[spec.key] = value;
    }

    final months = <String>{..._monthsOf(docs[registry.transactionIndexKey])};
    for (final month in _gapMonths(months)) {
      if (await storage.contains(registry.transactionPartitionKey(month))) months.add(month);
    }

    final iconIds = <String>{};
    for (final month in months.toList()..sort()) {
      final key = registry.transactionPartitionKey(month);
      final value = await storage.read(key);
      if (value == null) continue;
      docs[key] = value;
      iconIds.addAll(_iconIdsOf(value));
    }

    for (final id in iconIds) {
      final key = registry.sourceIconKey(id);
      final value = await storage.read(key);
      if (value != null) docs[key] = value;
    }
    return docs;
  }

  static List<String> _monthsOf(String? indexDoc) {
    if (indexDoc == null) return const [];
    final json = jsonDecode(indexDoc);
    if (json is! Map<String, dynamic>) return const [];
    return [
      for (final m in json['months'] as List<dynamic>? ?? const [])
        if (m is String && BackupRegistry.isMonth(m)) m,
    ];
  }

  static Iterable<String> _gapMonths(Set<String> known) sync* {
    if (known.length < 2) return;
    final sorted = known.toList()..sort();
    var (year, month) = _parse(sorted.first);
    final (lastYear, lastMonth) = _parse(sorted.last);
    while (year < lastYear || (year == lastYear && month < lastMonth)) {
      month++;
      if (month > 12) {
        month = 1;
        year++;
      }
      final key = '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
      if (!known.contains(key)) yield key;
    }
  }

  static (int, int) _parse(String month) => (int.parse(month.substring(0, 4)), int.parse(month.substring(5, 7)));

  static Set<String> _iconIdsOf(String partitionDoc) {
    final json = jsonDecode(partitionDoc);
    if (json is! Map<String, dynamic>) return const {};
    return {
      for (final item in json['items'] as List<dynamic>? ?? const [])
        if (item is Map<String, dynamic> && item['sourceIconId'] is String) item['sourceIconId'] as String,
    };
  }
}
