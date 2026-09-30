import 'package:saldough/shared/category/domain/category.dart';

/// Definisi satu kategori bawaan (ADR-026 §3.2). Nama tampilannya diambil
/// dari i18n saat kategori dibuat; [aliases] tidak disimpan.
final class BuiltInCategory {
  /// Membuat [BuiltInCategory].
  const BuiltInCategory({required this.key, required this.kind, required this.iconKey, this.aliases = const []});

  /// Kunci stabil, dipakai sebagai akhiran [id] dan kunci i18n.
  final String key;

  /// Jenis transaksinya.
  final CategoryKind kind;

  /// Nama `IconKey` ikonnya.
  final String iconKey;

  /// Kata kunci Indonesia dan Inggris, sudah dalam bentuk
  /// [normalizeCategoryText]. Hanya kata yang hampir tidak mungkin berarti
  /// lain ("air" dan "data" sengaja tidak masuk: "air mineral", "transfer
  /// data" -- temuan F5 verifikasi M1). Dipakai migrasi label lama dan pencocokan
  /// pencatatan cerdas (ADR-027), bukan untuk ditampilkan.
  final List<String> aliases;

  /// Id kategori yang dibuat dari definisi ini.
  String get id => 'builtin.$key';
}

/// Set kategori bawaan yang disetujui pemilik 30 Sep 2026 (ADR-026 §3.2).
abstract final class BuiltInCategories {
  BuiltInCategories._();

  /// Seluruh kategori bawaan, dalam urutan tampil.
  static const List<BuiltInCategory> all = [
    BuiltInCategory(
      key: 'food',
      kind: CategoryKind.expense,
      iconKey: 'categoryFood',
      aliases: [
        'makan',
        'makan siang',
        'makan malam',
        'sarapan',
        'minum',
        'jajan',
        'snack',
        'kopi',
        'ngopi',
        'cafe',
        'kafe',
        'resto',
        'restoran',
        'warung',
        'food',
        'lunch',
        'dinner',
        'breakfast',
        'coffee',
        'drink',
      ],
    ),
    BuiltInCategory(
      key: 'groceries',
      kind: CategoryKind.expense,
      iconKey: 'categoryGroceries',
      aliases: [
        'belanja harian',
        'belanja dapur',
        'sembako',
        'sayur',
        'pasar',
        'supermarket',
        'minimarket',
        'indomaret',
        'alfamart',
        'groceries',
        'grocery',
      ],
    ),
    BuiltInCategory(
      key: 'transport',
      kind: CategoryKind.expense,
      iconKey: 'categoryTransport',
      aliases: [
        'transport',
        'transportasi',
        'bensin',
        'bbm',
        'pertalite',
        'pertamax',
        'solar',
        'ojek',
        'ojol',
        'gojek',
        'grab',
        'taksi',
        'parkir',
        'tol',
        'kereta',
        'krl',
        'mrt',
        'busway',
        'bus',
        'fuel',
        'taxi',
        'parking',
      ],
    ),
    BuiltInCategory(
      key: 'bills',
      kind: CategoryKind.expense,
      iconKey: 'categoryBills',
      aliases: [
        'tagihan',
        'listrik',
        'pln',
        'token listrik',
        'tagihan air',
        'air pdam',
        'pdam',
        'sewa',
        'kontrakan',
        'kos',
        'kost',
        'cicilan',
        'bpjs',
        'asuransi',
        'bill',
        'bills',
        'rent',
      ],
    ),
    BuiltInCategory(
      key: 'internet',
      kind: CategoryKind.expense,
      iconKey: 'categoryInternet',
      aliases: ['pulsa', 'kuota', 'paket data', 'internet', 'wifi', 'indihome'],
    ),
    BuiltInCategory(
      key: 'health',
      kind: CategoryKind.expense,
      iconKey: 'categoryHealth',
      aliases: [
        'kesehatan',
        'obat',
        'dokter',
        'apotek',
        'klinik',
        'rumah sakit',
        'medis',
        'vitamin',
        'health',
        'medicine',
        'pharmacy',
      ],
    ),
    BuiltInCategory(
      key: 'entertainment',
      kind: CategoryKind.expense,
      iconKey: 'categoryEntertainment',
      aliases: [
        'hiburan',
        'nonton',
        'bioskop',
        'film',
        'game',
        'netflix',
        'spotify',
        'konser',
        'liburan',
        'entertainment',
        'movie',
      ],
    ),
    BuiltInCategory(
      key: 'shopping',
      kind: CategoryKind.expense,
      iconKey: 'categoryShopping',
      aliases: ['belanja', 'baju', 'pakaian', 'sepatu', 'shopee', 'tokopedia', 'belanja online', 'shopping'],
    ),
    BuiltInCategory(
      key: 'education',
      kind: CategoryKind.expense,
      iconKey: 'categoryEducation',
      aliases: ['pendidikan', 'sekolah', 'kuliah', 'kursus', 'les privat', 'buku', 'spp', 'education', 'course'],
    ),
    BuiltInCategory(
      key: 'family',
      kind: CategoryKind.expense,
      iconKey: 'categoryHousehold',
      aliases: ['keluarga', 'orang tua', 'kiriman', 'family'],
    ),
    BuiltInCategory(
      key: 'donation',
      kind: CategoryKind.expense,
      iconKey: 'categoryOther',
      aliases: ['donasi', 'zakat', 'sedekah', 'infak', 'infaq', 'amal', 'donation', 'charity'],
    ),
    BuiltInCategory(key: 'expenseOther', kind: CategoryKind.expense, iconKey: 'categoryOther', aliases: ['lainnya']),
    BuiltInCategory(
      key: 'salary',
      kind: CategoryKind.income,
      iconKey: 'income',
      aliases: ['gaji', 'gajian', 'salary', 'payroll'],
    ),
    BuiltInCategory(
      key: 'freelance',
      kind: CategoryKind.income,
      iconKey: 'income',
      aliases: ['freelance', 'proyek', 'honor'],
    ),
    BuiltInCategory(
      key: 'bonus',
      kind: CategoryKind.income,
      iconKey: 'income',
      aliases: ['bonus', 'thr', 'insentif', 'incentive'],
    ),
    BuiltInCategory(
      key: 'gift',
      kind: CategoryKind.income,
      iconKey: 'income',
      aliases: ['hadiah', 'angpao', 'angpau', 'kado', 'gift'],
    ),
    BuiltInCategory(key: 'incomeOther', kind: CategoryKind.income, iconKey: 'categoryOther', aliases: ['lainnya']),
  ];

  /// Definisi berkunci [key], atau `null`.
  static BuiltInCategory? byKey(String? key) {
    for (final category in all) {
      if (category.key == key) return category;
    }
    return null;
  }
}
