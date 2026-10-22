/// Satu kunci penyimpanan yang ikut cadangan.
final class BackupKeySpec {
  /// Membuat [BackupKeySpec].
  const BackupKeySpec(this.key, {this.supportedSchema});

  /// Nilai `StorageKey.value`, mis. `wallet_all`.
  final String key;

  /// `schemaVersion` tertinggi yang dibaca aplikasi ini. Dokumen yang lebih
  /// baru ditolak (R-2). `null` untuk dokumen tanpa `schemaVersion`
  /// (penanda migrasi, ikon).
  final int? supportedSchema;
}

/// Rujukan antardokumen yang diperiksa saat pemulihan (R-3): setiap nilai
/// field [fields] pada item-item dokumen [from] harus berupa `id` item di
/// dokumen [target].
final class BackupReference {
  /// Membuat [BackupReference].
  const BackupReference({required this.from, required this.fields, required this.target});

  /// Kunci dokumen sumber; akhiran `*` berarti semua kunci berawalan itu
  /// (mis. `transaction_*`).
  final String from;

  /// Nama field berisi `id` yang dirujuk (nilai `null` dilewati).
  final List<String> fields;

  /// Kunci dokumen yang memuat `items[].id` tujuan.
  final String target;
}

/// Daftar seluruh kunci penyimpanan dan statusnya terhadap cadangan
/// (ADR-040 §3.3). Instansnya dirakit akar komposisi
/// (`lib/app/data_portability/`); uji kelengkapan memastikan setiap
/// `StorageKey` di `lib/` terdaftar di salah satu sisi.
final class BackupRegistry {
  /// Membuat [BackupRegistry].
  const BackupRegistry({
    required this.included,
    required this.excluded,
    required this.transactionIndexKey,
    required this.transactionPartitionKey,
    required this.transactionPartitionPrefix,
    required this.transactionSchema,
    required this.sourceIconKey,
    required this.sourceIconPrefix,
    required this.references,
    required this.walletsKey,
    required this.currencyKey,
  });

  /// Kunci tetap yang ikut cadangan.
  final List<BackupKeySpec> included;

  /// Kunci yang sengaja tidak ikut, beserta alasannya.
  final Map<String, String> excluded;

  /// Dokumen indeks partisi transaksi (`{months: [YYYY-MM]}`).
  final String transactionIndexKey;

  /// Kunci partisi transaksi untuk bulan `YYYY-MM`.
  final String Function(String month) transactionPartitionKey;

  /// Awalan kunci partisi transaksi.
  final String transactionPartitionPrefix;

  /// `schemaVersion` tertinggi dokumen partisi transaksi.
  final int transactionSchema;

  /// Kunci ikon sumber untuk `sourceIconId`.
  final String Function(String id) sourceIconKey;

  /// Awalan kunci ikon sumber.
  final String sourceIconPrefix;

  /// Rujukan yang diperiksa saat pemulihan.
  final List<BackupReference> references;

  /// Dokumen dompet (untuk ringkasan).
  final String walletsKey;

  /// Dokumen mata uang (untuk ringkasan).
  final String currencyKey;

  /// `schemaVersion` tertinggi yang didukung untuk [key], `null` bila
  /// dokumennya tanpa versi.
  ///
  /// Mengembalikan `isIncluded: false` untuk kunci yang tidak dikenal.
  ({bool isIncluded, int? schema}) specOf(String key) {
    for (final spec in included) {
      if (spec.key == key) return (isIncluded: true, schema: spec.supportedSchema);
    }
    if (key.startsWith(transactionPartitionPrefix) && _isMonth(key.substring(transactionPartitionPrefix.length))) {
      return (isIncluded: true, schema: transactionSchema);
    }
    if (key.startsWith(sourceIconPrefix) && key.length > sourceIconPrefix.length) {
      return (isIncluded: true, schema: null);
    }
    return (isIncluded: false, schema: null);
  }

  static final _month = RegExp(r'^\d{4}-(0[1-9]|1[0-2])$');

  /// Apakah [value] berbentuk `YYYY-MM`.
  static bool isMonth(String value) => _month.hasMatch(value);

  static bool _isMonth(String value) => isMonth(value);
}
