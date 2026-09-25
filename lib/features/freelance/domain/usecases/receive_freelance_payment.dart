import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/freelance/domain/entities/freelance_payment.dart';
import 'package:saldough/features/freelance/domain/repositories/freelance_repository.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Mencatat bahwa sebuah pembayaran freelance benar-benar diterima, atau
/// membatalkan pencatatan itu (FR-FRL-004, ADR-019).
///
/// Ini SATU-SATUNYA jalan fitur freelance ke saldo dompet. Mencatat worklog
/// atau membuat pembayaran tidak pernah menyentuhnya (aturan 6 CLAUDE.md).
///
/// **Urutan penulisan mengikat.** Mencatat diterima: transaksi lebih dulu
/// (id-nya `payment.transactionId`, jadi pengulangan sesudah kegagalan
/// menimpa transaksi yang sama), baru pembayaran. Membatalkan: pembayaran
/// dikembalikan ke `pending` lebih dulu, baru transaksinya dihapus. Kedua
/// arah tidak pernah menyisakan pembayaran `paid` tanpa transaksi.
final class ReceiveFreelancePayment {
  /// Membuat [ReceiveFreelancePayment].
  const ReceiveFreelancePayment({required this.freelanceRepository, required this.recordTransaction});

  /// Penyimpan pembayaran.
  final FreelanceRepository freelanceRepository;

  /// Pencatat transaksi yang juga menghitung ulang saldo dompet.
  final RecordTransaction recordTransaction;

  /// Kode kegagalan saat [payment] sudah diterima sebelumnya.
  static const alreadyPaidCode = FailureCode('FREELANCE_PAYMENT_ALREADY_PAID');

  /// Kode kegagalan saat gaji bersih tidak positif (potongan ≥ gaji kotor).
  static const nonPositiveNetPayCode = FailureCode('FREELANCE_NET_PAY_NOT_POSITIVE');

  /// Kode kegagalan saat membatalkan pembayaran yang belum diterima.
  static const notPaidCode = FailureCode('FREELANCE_PAYMENT_NOT_PAID');

  /// Mencatat [payment] diterima sebesar [netPay] sen di [walletId] pada
  /// [date]: membuat tepat satu `IncomeTransaction`, lalu menandai
  /// pembayarannya `paid`.
  Future<Either<Failure, Unit>> call({
    required FreelancePayment payment,
    required int netPay,
    required String walletId,
    required DateTime date,
    required String note,
  }) async {
    if (payment.isPaid) {
      return left(const ValidationFailure(code: alreadyPaidCode, message: 'Pembayaran sudah dicatat diterima.'));
    }
    if (netPay <= 0) {
      return left(const ValidationFailure(code: nonPositiveNetPayCode, message: 'Gaji bersih harus positif.'));
    }
    final transaction = IncomeTransaction(
      id: payment.transactionId,
      date: date,
      amount: netPay,
      note: note,
      walletId: walletId,
      freelancePaymentId: payment.id,
    );
    final recorded = await recordTransaction(transaction);
    return switch (recorded) {
      Left(value: final failure) => left(failure),
      Right() => freelanceRepository.savePayment(payment.markPaid(walletId: walletId, date: date)),
    };
  }

  /// Membatalkan penerimaan [payment] yang transaksinya bernominal
  /// [netPay] sen: pembayaran kembali `pending`, lalu transaksinya dihapus
  /// dan saldo dompetnya dihitung ulang.
  Future<Either<Failure, Unit>> undo({required FreelancePayment payment, required int netPay}) async {
    final walletId = payment.walletId;
    final receivedDate = payment.receivedDate;
    if (!payment.isPaid || walletId == null || receivedDate == null) {
      return left(const ValidationFailure(code: notPaidCode, message: 'Pembayaran belum dicatat diterima.'));
    }
    final reverted = await freelanceRepository.savePayment(payment.markPending());
    if (reverted case Left(value: final failure)) return left(failure);
    return recordTransaction.delete(
      IncomeTransaction(
        id: payment.transactionId,
        date: receivedDate,
        // Nominal tidak dipakai untuk menghapus; `delete` hanya butuh id,
        // tanggal, dan dompet. Tetap diisi nilai sebenarnya supaya lolos
        // aturan nominal positif.
        amount: netPay > 0 ? netPay : 1,
        note: '',
        walletId: walletId,
        freelancePaymentId: payment.id,
      ),
    );
  }
}
