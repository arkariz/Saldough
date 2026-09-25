/// Status sebuah `FreelancePayment`.
enum PaymentStatus {
  /// Sudah ditagihkan, uangnya belum diterima.
  pending,

  /// Sudah dicatat diterima; transaksi pemasukannya sudah ada.
  paid,
}
