import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:saldough/shared/category/domain/category.dart';
import 'package:saldough/shared/category/domain/category_matcher.dart';

/// Daftar kategori seluruh aplikasi, untuk menampilkan nama dan ikon kategori
/// sebuah transaksi (ADR-026 §3.5).
///
/// Pola yang sama dengan `ActiveCurrency` (ADR-025 §3.5): judul transaksi
/// dipakai di banyak layar tanpa bloc bersama. Diisi `main.dart` sebelum
/// `runApp` dan diperbarui `CategoryRepositoryImpl` setiap kali kategori
/// dibaca atau disimpan.
abstract final class ActiveCategories {
  ActiveCategories._();

  /// Pemegang nilai; didengar akar aplikasi untuk membangun ulang layar.
  static final ValueNotifier<List<Category>> notifier = ValueNotifier(const []);

  /// Kategori ber-`id` [id] (aktif maupun terarsip), atau `null`.
  static Category? byId(String? id) {
    if (id == null) return null;
    for (final category in notifier.value) {
      if (category.id == id) return category;
    }
    return null;
  }

  /// Kategori aktif berjenis [kind] untuk pemilih; [frequentIds] di atas.
  static List<Category> selectable(CategoryKind kind, {List<String> frequentIds = const []}) =>
      selectableCategories(notifier.value, kind, frequentIds: frequentIds);
}
