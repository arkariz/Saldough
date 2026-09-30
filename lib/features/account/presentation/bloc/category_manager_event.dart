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
  const CategoryManagerAdded({required this.kind, required this.name});

  /// Jenis kategori baru.
  final CategoryKind kind;

  /// Nama kategori baru.
  final String name;
}

/// Mengganti nama [category] menjadi [name].
final class CategoryManagerRenamed extends CategoryManagerEvent {
  /// Membuat [CategoryManagerRenamed].
  const CategoryManagerRenamed({required this.category, required this.name});

  /// Kategori yang diganti namanya.
  final Category category;

  /// Nama baru.
  final String name;
}

/// Mengarsipkan [category], atau memulihkannya kalau sudah terarsip.
final class CategoryManagerArchiveToggled extends CategoryManagerEvent {
  /// Membuat [CategoryManagerArchiveToggled].
  const CategoryManagerArchiveToggled(this.category);

  /// Kategori yang diarsipkan atau dipulihkan.
  final Category category;
}
