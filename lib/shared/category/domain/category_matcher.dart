import 'package:saldough/shared/category/domain/built_in_categories.dart';
import 'package:saldough/shared/category/domain/category.dart';

/// Kategori berjenis [kind] di [categories] yang cocok **persis** dengan
/// [text] (setelah [normalizeCategoryText]): nama lebih dulu, lalu alias
/// kategori bawaan. `null` kalau tidak ada yang cocok.
///
/// Sengaja tidak mencocokkan sebagian ("makan siang di kantor" tidak cocok
/// dengan "makan") — dipakai migrasi label lama dan validasi keluaran
/// pencatatan cerdas (ADR-026, ADR-027), yang tidak boleh menebak.
/// Kategori aktif menang atas kategori terarsip.
Category? matchCategory(Iterable<Category> categories, CategoryKind kind, String text) {
  final needle = normalizeCategoryText(text);
  if (needle.isEmpty) return null;
  final candidates = categories.where((c) => c.kind == kind).toList()
    ..sort((a, b) => (a.isArchived ? 1 : 0).compareTo(b.isArchived ? 1 : 0));
  for (final category in candidates) {
    if (normalizeCategoryText(category.name) == needle) return category;
  }
  for (final category in candidates) {
    final builtIn = BuiltInCategories.byKey(category.builtInKey);
    if (builtIn != null && builtIn.aliases.contains(needle)) return category;
  }
  return null;
}

/// Kategori aktif berjenis [kind] untuk pemilih: yang paling sering dipakai
/// ([frequentIds], terurut) lebih dulu, lalu sisanya menurut `sortOrder`.
List<Category> selectableCategories(
  Iterable<Category> categories,
  CategoryKind kind, {
  List<String> frequentIds = const [],
}) {
  final active = categories.where((c) => c.kind == kind && !c.isArchived).toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  final byId = {for (final c in active) c.id: c};
  final ordered = <Category>[
    for (final id in frequentIds)
      if (byId[id] != null) byId[id]!,
  ];
  return [...ordered, ...active.where((c) => !ordered.contains(c))];
}
