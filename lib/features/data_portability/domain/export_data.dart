import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Seluruh bahan ekspor yang dibaca dari penyimpanan (EXPORT_BACKUP §5.2).
///
/// Nama diselesaikan saat ekspor (E-2): peta berisi nama **sekarang**. Id yang
/// tidak ditemukan (data yatim) tidak menggagalkan ekspor; barisnya memakai
/// teks kosong.
final class ExportData {
  /// Membuat [ExportData].
  const ExportData({
    required this.transactions,
    required this.wallets,
    required this.categoryNames,
    required this.budgetLabels,
    required this.ruleNames,
    required this.freelanceProjectByPaymentId,
    required this.schedule,
    required this.currency,
  });

  /// Seluruh transaksi.
  final List<Transaction> transactions;

  /// Seluruh dompet (aktif dan nonaktif) dengan saldo sekarang.
  final List<Wallet> wallets;

  /// `categoryId → nama`, termasuk kategori terarsip.
  final Map<String, String> categoryNames;

  /// `budgetItemId → "Anggaran › Pos"`.
  final Map<String, String> budgetLabels;

  /// `ruleId → nama rutin`.
  final Map<String, String> ruleNames;

  /// `freelancePaymentId → nama proyek`.
  final Map<String, String> freelanceProjectByPaymentId;

  /// Jadwal bulan keuangan untuk kolom Awal periode.
  final FinancialMonthSchedule schedule;

  /// Mata uang aplikasi.
  final AppCurrency currency;
}

/// Membaca [ExportData]. Diimplementasikan akar komposisi di atas repositori
/// transaksi, dompet, kategori, anggaran, rutin, dan freelance (ADR-030: fitur
/// ini tidak mengimpor fitur lain).
// ignore: one_member_abstracts, port kecil untuk satu kebutuhan baca lintas fitur.
abstract interface class ExportDataSource {
  /// Seluruh data saat ini.
  Future<Either<Failure, ExportData>> load();
}
