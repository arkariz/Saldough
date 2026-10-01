/// Barrel modul `shared/transaction` — satu-satunya jalur impor ke modul ini
/// dari fitur lain. Lihat ADR-0009 dan aturan yang mengikat di
/// ARCHITECTURE_OVERVIEW.md.
library;

export 'data/source_icon_repository_impl.dart';
export 'data/transaction_repository_impl.dart';
export 'domain/ledger_changes.dart';
export 'domain/source_icon_repository.dart';
export 'domain/transaction.dart';
export 'domain/transaction_query.dart';
export 'domain/transaction_repository.dart';
export 'domain/usecases/calculate_cash_flow.dart';
export 'domain/usecases/recompute_wallet_balances.dart';
export 'domain/usecases/record_transaction.dart';
