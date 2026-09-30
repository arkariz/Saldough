import 'package:dependencies/dependencies.dart';

/// Jenis transaksi yang boleh memakai sebuah [Category]. Transfer tidak
/// berkategori (ADR-026 §3.3), jadi tidak ada anggota `transfer`.
enum CategoryKind {
  /// Kategori pengeluaran.
  expense,

  /// Kategori pemasukan.
  income,
}

/// Pengelompokan pemasukan atau pengeluaran. Lihat DOMAIN_MODEL.md bagian
/// "Kategori" dan ADR-026.
///
/// Daftarnya datar dan dipisah per [kind]. Kategori tidak pernah dihapus
/// selama ada transaksi yang menunjuknya — cukup diarsipkan ([isArchived]).
final class Category extends Equatable {
  /// Membuat [Category].
  const Category({
    required this.id,
    required this.kind,
    required this.name,
    this.builtInKey,
    this.iconKey,
    this.isArchived = false,
    this.sortOrder = 0,
  });

  /// Identitas kategori: `builtin.<key>`, `legacy.<jenis>.<label>` (hasil
  /// migrasi label lama), atau id buatan pengguna.
  final String id;

  /// Jenis transaksi yang memakai kategori ini.
  final CategoryKind kind;

  /// Nama tampilan. Data milik pengguna, termasuk untuk kategori bawaan
  /// (nama bawaan ditulis dari i18n saat dibuat).
  final String name;

  /// Kunci kategori bawaan (lihat `BuiltInCategories`), untuk alias dan ikon.
  /// `null` untuk kategori buatan pengguna.
  final String? builtInKey;

  /// Nama `IconKey`. `null` berarti ikon ditebak dari [name].
  final String? iconKey;

  /// Tidak ditawarkan lagi di pemilih, tetapi transaksi lama tetap menunjuknya.
  final bool isArchived;

  /// Urutan di pemilih, kecil di atas.
  final int sortOrder;

  /// Salinan [Category] dengan field yang disebutkan diganti.
  Category copyWith({String? name, String? iconKey, bool? isArchived, int? sortOrder}) {
    return Category(
      id: id,
      kind: kind,
      name: name ?? this.name,
      builtInKey: builtInKey,
      iconKey: iconKey ?? this.iconKey,
      isArchived: isArchived ?? this.isArchived,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  List<Object?> get props => [id, kind, name, builtInKey, iconKey, isArchived, sortOrder];
}

/// Bentuk baku teks kategori untuk dibandingkan: huruf kecil, spasi dirapikan.
/// "  Makan   Siang " dan "makan siang" dianggap sama.
String normalizeCategoryText(String text) => text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
