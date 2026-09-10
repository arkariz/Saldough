/// Barrel modul `shared/goal` — satu-satunya jalur impor ke modul ini dari
/// fitur lain. Lihat ADR-0009 dan aturan yang mengikat di
/// ARCHITECTURE_OVERVIEW.md.
library;

export 'data/goal_repository_impl.dart';
export 'domain/goal.dart';
export 'domain/goal_repository.dart';
