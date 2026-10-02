/// Barrel modul `shared/recurring` — satu-satunya jalur impor ke modul ini
/// dari fitur lain (ADR-0009). Transaksi rutin dipakai Beranda, Rencana,
/// CATAT, dan penangkap notifikasi (ADR-034 §3.1).
library;

export 'data/recurring_rule_repository_impl.dart';
export 'domain/occurrence_status.dart';
export 'domain/occurrences.dart';
export 'domain/recurring_rule.dart';
export 'domain/recurring_rule_repository.dart';
