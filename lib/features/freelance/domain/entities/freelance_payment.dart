import 'package:dependencies/dependencies.dart';
import 'package:saldough/features/freelance/domain/entities/deduction_rule.dart';
import 'package:saldough/features/freelance/domain/entities/payment_status.dart';

/// Sekelompok entri worklog satu proyek yang ditagihkan bersama. Lihat
/// DOMAIN_MODEL.md bagian "Pembayaran".
///
/// Gaji kotor, potongan, dan gaji bersih tidak disimpan; semuanya dihitung
/// dari entri tercakup dan [deductionRules] lewat `CalculateNetPay`.
/// [deductionRules] disalin dari proyek saat pembayaran dibuat (ADR-019),
/// jadi angka pembayaran tidak berubah walau potongan proyek diubah.
///
/// ⚠ [incomeTransactionId] yang terisi adalah penjaga pencatatan ganda.
/// [status], [walletId], dan [incomeTransactionId] selalu berubah bersama,
/// lewat [markPaid] dan [markPending], tidak pernah terpisah.
final class FreelancePayment extends Equatable {
  /// Membuat [FreelancePayment].
  const FreelancePayment({
    required this.id,
    required this.projectId,
    required this.entryIds,
    required this.expectedDate,
    this.deductionRules = const [],
    this.status = PaymentStatus.pending,
    this.walletId,
    this.incomeTransactionId,
    this.receivedDate,
  }) : assert(
         (status == PaymentStatus.paid) == (incomeTransactionId != null && walletId != null && receivedDate != null),
         'Pembayaran paid wajib punya dompet, transaksi, dan tanggal diterima; pending tidak boleh punya.',
       );

  /// Identitas pembayaran.
  final String id;

  /// Proyek yang ditagihkan.
  final String projectId;

  /// Entri worklog yang tercakup, semuanya dari [projectId].
  final List<String> entryIds;

  /// Perkiraan tanggal diterima. Tidak harus mengikuti batas bulan.
  final DateTime expectedDate;

  /// Potongan yang berlaku untuk pembayaran ini.
  final List<DeductionRule> deductionRules;

  /// Status pembayaran.
  final PaymentStatus status;

  /// Dompet tujuan; terisi saat dicatat diterima.
  final String? walletId;

  /// Transaksi pemasukan yang lahir saat dicatat diterima.
  final String? incomeTransactionId;

  /// Tanggal uangnya diterima, sama dengan tanggal transaksi pemasukannya.
  /// Disimpan supaya transaksi itu bisa ditemukan di dokumen bulannya saat
  /// penerimaan dibatalkan (ADR-012).
  final DateTime? receivedDate;

  /// Apakah sudah dicatat diterima.
  bool get isPaid => status == PaymentStatus.paid;

  /// Id transaksi pemasukan untuk pembayaran ini, diturunkan dari [id]
  /// supaya pencatatan ulang sesudah kegagalan menimpa transaksi yang sama,
  /// bukan membuat yang kedua (ADR-019).
  String get transactionId => 'freelance-$id';

  /// Salinan yang sudah diterima di [walletId] pada [date].
  FreelancePayment markPaid({required String walletId, required DateTime date}) => _copy(
    status: PaymentStatus.paid,
    walletId: walletId,
    incomeTransactionId: transactionId,
    receivedDate: date,
  );

  /// Salinan yang kembali tertunda (batalkan penerimaan).
  FreelancePayment markPending() => _copy();

  /// Salinan dengan tanggal perkiraan baru.
  FreelancePayment withExpectedDate(DateTime date) => _copy(
    expectedDate: date,
    status: status,
    walletId: walletId,
    incomeTransactionId: incomeTransactionId,
    receivedDate: receivedDate,
  );

  FreelancePayment _copy({
    DateTime? expectedDate,
    PaymentStatus status = PaymentStatus.pending,
    String? walletId,
    String? incomeTransactionId,
    DateTime? receivedDate,
  }) => FreelancePayment(
    id: id,
    projectId: projectId,
    entryIds: entryIds,
    expectedDate: expectedDate ?? this.expectedDate,
    deductionRules: deductionRules,
    status: status,
    walletId: walletId,
    incomeTransactionId: incomeTransactionId,
    receivedDate: receivedDate,
  );

  @override
  List<Object?> get props => [
    id,
    projectId,
    entryIds,
    expectedDate,
    deductionRules,
    status,
    walletId,
    incomeTransactionId,
    receivedDate,
  ];
}
