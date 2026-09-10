/// Barrel modul `shared/income` — satu-satunya jalur impor ke modul ini dari
/// fitur lain. Lihat ADR-0009 dan aturan yang mengikat di
/// ARCHITECTURE_OVERVIEW.md.
library;

export 'data/income_source_repository_impl.dart';
export 'domain/calculate_net_pay.dart';
export 'domain/deduction_amount.dart';
export 'domain/deduction_kind.dart';
export 'domain/deduction_rule.dart';
export 'domain/income_source.dart';
export 'domain/income_source_kind.dart';
export 'domain/income_source_repository.dart';
export 'domain/net_pay_breakdown.dart';
