/// Barrel modul `shared/transaction` — satu-satunya jalur impor ke modul ini
/// dari fitur lain. Lihat ADR-0009 dan aturan yang mengikat di
/// ARCHITECTURE_OVERVIEW.md.
library;

export 'data/transaction_repository_impl.dart';
export 'domain/transaction.dart';
export 'domain/transaction_repository.dart';
