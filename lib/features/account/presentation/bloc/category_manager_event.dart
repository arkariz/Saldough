part of 'category_manager_bloc.dart';

/// Event [CategoryManagerBloc].
sealed class CategoryManagerEvent {
  /// Membuat [CategoryManagerEvent].
  const CategoryManagerEvent();
}

/// Memuat daftar kategori saat layar dibuka.
final class CategoryManagerStarted extends CategoryManagerEvent {
  /// Membuat [CategoryManagerStarted].
  const CategoryManagerStarted();
}

/// Menambah kategori [name] berjenis [kind].
final class CategoryManagerAdded extends CategoryManagerEvent {
  /// Membuat [CategoryManagerAdded].
  const CategoryManagerAdded({required this.kind, required this.name, this.iconKey});

  /// Jenis kategori baru.
  final CategoryKind kind;

  /// Nama kategori baru.
  final String name;

  /// Ikon pilihan pengguna, atau `null` (ditebak dari nama).
  final String? iconKey;
}

/// Mengganti nama [category] menjadi [name], dan ikonnya menjadi [iconKey]
/// bila diberikan.
final class CategoryManagerRenamed extends CategoryManagerEvent {
  /// Membuat [CategoryManagerRenamed].
  const CategoryManagerRenamed({required this.category, required this.name, this.iconKey});

  /// Kategori yang diubah.
  final Category category;

  /// Nama baru.
  final String name;

  /// Ikon baru, atau `null` (tidak berubah).
  final String? iconKey;
}

/// Mengarsipkan [category], atau memulihkannya kalau sudah terarsip.
final class CategoryManagerArchiveToggled extends CategoryManagerEvent {
  /// Membuat [CategoryManagerArchiveToggled].
  const CategoryManagerArchiveToggled(this.category);

  /// Kategori yang diarsipkan atau dipulihkan.
  final Category category;
}
