import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/shared/category/category.dart';

/// Mengisi `ActiveCategories` dengan kategori yang id dan namanya sama
/// dengan [names] (ADR-026), lalu mengosongkannya lagi sesudah uji.
///
/// Dipakai uji yang menampilkan judul atau penyaring kategori — tanpa ini
/// transaksi berkategori tampil tanpa nama.
void useCategories(List<String> names, {CategoryKind kind = CategoryKind.expense}) {
  ActiveCategories.notifier.value = [for (final name in names) Category(id: name, kind: kind, name: name)];
  addTearDown(() => ActiveCategories.notifier.value = const []);
}
