import 'package:navigation/navigation.dart';

// Satu-satunya berkas fitur `budget` yang boleh diimpor fitur lain
// (ADR-0004, ADR-030 §3.3).

/// Input rincian satu anggaran (FR-BUD-007).
final class BudgetDetailInput extends RouteInput {
  /// Membuat [BudgetDetailInput].
  const BudgetDetailInput({required this.budgetId});

  /// Anggaran yang dibuka.
  final String budgetId;
}

/// Kunci rute fitur `budget`.
abstract final class BudgetRouteKeys {
  /// Rincian satu anggaran: dari tab Anggaran dan dari baris "Anggaran" di
  /// rincian transaksi (T-4.11).
  static const detail = RouteKey<BudgetDetailInput>('budget.detail');
}
