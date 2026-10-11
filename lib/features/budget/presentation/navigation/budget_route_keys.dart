import 'package:navigation/navigation.dart';
import 'package:saldough/core/financial_month/financial_month.dart';

// Satu-satunya berkas fitur `budget` yang boleh diimpor fitur lain
// (ADR-0004, ADR-030 §3.3).

/// Input rincian satu anggaran (FR-BUD-007).
final class BudgetDetailInput extends RouteInput {
  /// Membuat [BudgetDetailInput].
  const BudgetDetailInput({required this.budgetId});

  /// Anggaran yang dibuka.
  final String budgetId;
}

/// Asal pembukaan lembar Awal bulan keuangan, untuk analitik
/// (FINANCIAL_PERIOD §8A).
enum FinancialMonthSource {
  /// Kepala Rencana › Bulan ini.
  plan,

  /// Layar Akun.
  account,

  /// Tawaran rutin gajian (F2).
  offer,
}

/// Input lembar Awal bulan keuangan.
final class FinancialMonthInput extends RouteInput {
  /// Membuat [FinancialMonthInput].
  const FinancialMonthInput({required this.source, this.initial});

  /// Asal pembukaan.
  final FinancialMonthSource source;

  /// Tanggal yang sudah terpilih saat dibuka (tawaran rutin gajian, F2);
  /// `null` = tanggal aktif.
  final FinancialMonthStart? initial;
}

/// Kunci rute fitur `budget`.
abstract final class BudgetRouteKeys {
  /// Rincian satu anggaran: dari tab Anggaran dan dari baris "Anggaran" di
  /// rincian transaksi (T-4.11).
  static const detail = RouteKey<BudgetDetailInput>('budget.detail');

  /// Lembar Awal bulan keuangan (ADR-038, FINANCIAL_PERIOD F1): dari kepala
  /// Rencana › Bulan ini dan dari Akun. Selesai dengan `true` bila disimpan.
  /// Milik `budget` karena menyimpan juga memindah anggaran rutin.
  static const financialMonth = RouteKey<FinancialMonthInput>('budget.financialMonth');
}
