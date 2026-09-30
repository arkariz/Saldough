import 'package:navigation/navigation.dart';
import 'package:saldough/shared/transaction/transaction.dart';

// Satu-satunya berkas fitur `transaction` yang boleh diimpor fitur lain
// (ADR-0004, ADR-030 §3.3).

/// Input rincian satu transaksi (FR-TXN-006).
final class TransactionDetailInput extends RouteInput {
  /// Membuat [TransactionDetailInput].
  const TransactionDetailInput(this.transaction);

  /// Transaksi yang dibuka (cuplikan; rinciannya ditutup sesudah sunting
  /// atau hapus).
  final Transaction transaction;
}

/// Input riwayat yang tersaring satu dompet ("Lihat semua transaksi" di
/// rincian dompet).
final class TransactionHistoryInput extends RouteInput {
  /// Membuat [TransactionHistoryInput].
  const TransactionHistoryInput({required this.walletId});

  /// Dompet penyaring awal.
  final String walletId;
}

/// Kunci rute fitur `transaction`.
abstract final class TransactionRouteKeys {
  /// Rincian satu transaksi.
  static const detail = RouteKey<TransactionDetailInput>('transaction.detail');

  /// Riwayat tersaring satu dompet, terpisah dari tab Riwayat.
  static const history = RouteKey<TransactionHistoryInput>('transaction.history');
}
