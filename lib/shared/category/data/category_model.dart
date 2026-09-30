import 'package:saldough/shared/category/domain/category.dart';

/// Model serialisasi [Category], terpisah dari entitas domain (tanpa
/// `freezed`, mengikuti konvensi monorepo — lihat ARCHITECTURE_OVERVIEW.md).
final class CategoryModel {
  /// Membuat [CategoryModel].
  const CategoryModel({
    required this.id,
    required this.kind,
    required this.name,
    required this.isArchived,
    required this.sortOrder,
    this.builtInKey,
    this.iconKey,
  });

  /// Membaca [CategoryModel] dari JSON.
  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
    id: json['id'] as String,
    kind: json['kind'] as String,
    name: json['name'] as String,
    builtInKey: json['builtInKey'] as String?,
    iconKey: json['iconKey'] as String?,
    isArchived: json['isArchived'] as bool,
    sortOrder: json['sortOrder'] as int,
  );

  /// Membuat [CategoryModel] dari entitas domain [Category].
  factory CategoryModel.fromEntity(Category category) => CategoryModel(
    id: category.id,
    kind: category.kind.name,
    name: category.name,
    builtInKey: category.builtInKey,
    iconKey: category.iconKey,
    isArchived: category.isArchived,
    sortOrder: category.sortOrder,
  );

  /// Versi skema dokumen ini. Naikkan kalau bentuk field berubah.
  static const schemaVersion = 1;

  /// Identitas kategori.
  final String id;

  /// `'expense'` atau `'income'`.
  final String kind;

  /// Nama tampilan.
  final String name;

  /// Kunci kategori bawaan.
  final String? builtInKey;

  /// Nama `IconKey`.
  final String? iconKey;

  /// Terarsip atau tidak.
  final bool isArchived;

  /// Urutan di pemilih.
  final int sortOrder;

  /// Menulis [CategoryModel] ke JSON.
  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind,
    'name': name,
    if (builtInKey != null) 'builtInKey': builtInKey,
    if (iconKey != null) 'iconKey': iconKey,
    'isArchived': isArchived,
    'sortOrder': sortOrder,
  };

  /// Mengubah model jadi entitas domain [Category]. Melempar
  /// [FormatException] kalau [kind] tidak dikenal (dokumen rusak).
  Category toEntity() => Category(
    id: id,
    kind: CategoryKind.values.firstWhere(
      (k) => k.name == kind,
      orElse: () => throw FormatException('Jenis kategori tidak dikenal: $kind ($id)'),
    ),
    name: name,
    builtInKey: builtInKey,
    iconKey: iconKey,
    isArchived: isArchived,
    sortOrder: sortOrder,
  );
}
