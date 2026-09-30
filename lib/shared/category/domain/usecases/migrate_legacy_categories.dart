import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/shared/category/domain/built_in_categories.dart';
import 'package:saldough/shared/category/domain/category.dart';
import 'package:saldough/shared/category/domain/category_matcher.dart';
import 'package:saldough/shared/category/domain/category_repository.dart';
import 'package:saldough/shared/category/domain/legacy_category_labels.dart';

/// Menyiapkan kategori bawaan dan memindahkan label teks bebas lama menjadi
/// kategori (ADR-026 §3.4). Dipanggil `main.dart` di setiap pembukaan; begitu
/// penanda selesai tertulis, pekerjaannya hanya satu baca.
///
/// Aman diulang kalau terhenti di tengah: id kategori hasil migrasi
/// deterministik (`legacy.<jenis>.<label>`), dokumen kategori ditulis sebelum
/// transaksi, dan penanda ditulis paling akhir.
final class MigrateLegacyCategories {
  /// Membuat [MigrateLegacyCategories].
  const MigrateLegacyCategories({required this._categoryRepository, required this._legacyLabels});

  final CategoryRepository _categoryRepository;
  final LegacyCategoryLabels _legacyLabels;

  /// Menjalankan migrasi. [builtInName] memberi nama tampilan kategori bawaan
  /// dari kuncinya (i18n bahasa aktif).
  Future<Either<Failure, Unit>> call({required String Function(String builtInKey) builtInName}) async {
    switch (await _categoryRepository.isLegacyMigrationDone()) {
      case Left(value: final failure):
        return left(failure);
      case Right(value: true):
        return right(unit);
      case Right():
        break;
    }

    final List<Category> categories;
    switch (await _categoryRepository.listCategories()) {
      case Left(value: final failure):
        return left(failure);
      case Right(value: final stored):
        categories = [...stored];
    }

    final storedIds = {for (final c in categories) c.id};
    final missingBuiltIns = [
      for (final (index, builtIn) in BuiltInCategories.all.indexed)
        if (!storedIds.contains(builtIn.id))
          Category(
            id: builtIn.id,
            kind: builtIn.kind,
            name: builtInName(builtIn.key),
            builtInKey: builtIn.key,
            iconKey: builtIn.iconKey,
            sortOrder: index,
          ),
    ];
    // Kategori bawaan disimpan lebih dulu, terpisah dari pemindahan label:
    // kalau membaca label lama gagal, pemilih kategori tetap berisi.
    if (missingBuiltIns.isNotEmpty) {
      if (await _categoryRepository.saveCategories(missingBuiltIns) case Left(value: final failure)) {
        return left(failure);
      }
      categories.addAll(missingBuiltIns);
    }

    final List<LegacyCategoryLabel> labels;
    switch (await _legacyLabels.listLabels()) {
      case Left(value: final failure):
        return left(failure);
      case Right(value: final listed):
        labels = listed;
    }
    var nextOrder = categories.fold<int>(0, (max, c) => c.sortOrder > max ? c.sortOrder : max) + 1;
    final idByLabel = <LegacyCategoryLabel, String>{};
    for (final label in labels) {
      final match = matchCategory(categories, label.kind, label.label);
      if (match != null) {
        idByLabel[label] = match.id;
        continue;
      }
      final created = Category(
        id: legacyCategoryId(label),
        kind: label.kind,
        name: label.label.trim(),
        sortOrder: nextOrder++,
      );
      categories.add(created);
      idByLabel[label] = created.id;
    }

    if (await _categoryRepository.saveCategories(categories) case Left(value: final failure)) return left(failure);
    final replaced = await _legacyLabels.replaceLabels(
      (label) => idByLabel[label] ?? matchCategory(categories, label.kind, label.label)?.id,
    );
    if (replaced case Left(value: final failure)) return left(failure);
    return _categoryRepository.markLegacyMigrationDone();
  }
}

/// Id deterministik kategori hasil migrasi [label].
String legacyCategoryId(LegacyCategoryLabel label) => 'legacy.${label.kind.name}.${normalizeCategoryText(label.label)}';
