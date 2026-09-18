/// Barrel modul `shared/wallet` — satu-satunya jalur impor ke modul ini dari
/// fitur lain. Lihat ADR-0009 dan aturan yang mengikat di
/// ARCHITECTURE_OVERVIEW.md.
library;

export 'data/wallet_repository_impl.dart';
export 'domain/usecases/calculate_wallet_balance.dart';
export 'domain/wallet.dart';
export 'domain/wallet_repository.dart';
