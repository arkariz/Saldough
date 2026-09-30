/// Barrel modul `shared/category` — satu-satunya jalur impor ke modul ini
/// dari fitur lain. Lihat ADR-0009 dan ADR-026.
library;

export 'active_categories.dart';
export 'data/category_repository_impl.dart';
export 'domain/built_in_categories.dart';
export 'domain/category.dart';
export 'domain/category_matcher.dart';
export 'domain/category_repository.dart';
export 'domain/legacy_category_labels.dart';
export 'domain/usecases/create_category.dart';
export 'domain/usecases/migrate_legacy_categories.dart';
export 'presentation/category_display.dart';
export 'presentation/category_name_dialog.dart';
