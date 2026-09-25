import 'package:dependencies/dependencies.dart';

/// Peristiwa yang benar-benar terjadi pada uang pemilik — tipe tertutup
/// dengan tiga anggota. Tertutup karena menambah jenis baru mengubah aturan
/// perhitungan saldo, jadi harus dipikirkan dan diuji, bukan diketik
/// pemilik. Lihat DOMAIN_MODEL.md bagian "Transaksi".
sealed class Transaction extends Equatable {
  /// Membuat [Transaction].
  const Transaction({
    required this.id,
    required this.date,
    required this.amount,
    required this.note,
    this.categoryKey,
  }) : assert(amount > 0, 'Nominal transaksi harus positif; arah uang ditentukan jenisnya, bukan tandanya.');

  /// Identitas transaksi.
  final String id;

  /// Kapan peristiwanya terjadi, bukan kapan dicatat.
  final DateTime date;

  /// Nominal dalam sen. Selalu positif.
  final int amount;

  /// Catatan bebas, boleh kosong.
  final String note;

  /// Label pengelompokan, boleh kosong.
  final String? categoryKey;
}

/// Menambah saldo satu dompet.
final class IncomeTransaction extends Transaction {
  /// Membuat [IncomeTransaction].
  const IncomeTransaction({
    required super.id,
    required super.date,
    required super.amount,
    required super.note,
    required this.walletId,
    super.categoryKey,
    this.freelancePaymentId,
  });

  /// Dompet yang bertambah.
  final String walletId;

  /// Pembayaran freelance yang melahirkan transaksi ini. Kalau terisi,
  /// transaksi ini milik pembayarannya: tidak bisa disunting atau dihapus
  /// dari tab Transaksi, hanya lewat Ikhtisar Freelance (ADR-019).
  final String? freelancePaymentId;

  /// Apakah transaksi ini milik sebuah pembayaran freelance.
  bool get isFreelancePayment => freelancePaymentId != null;

  /// Salinan [IncomeTransaction] dengan field yang disebutkan diganti.
  IncomeTransaction copyWith({
    DateTime? date,
    int? amount,
    String? note,
    String? categoryKey,
    String? walletId,
  }) {
    return IncomeTransaction(
      id: id,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      categoryKey: categoryKey ?? this.categoryKey,
      walletId: walletId ?? this.walletId,
      freelancePaymentId: freelancePaymentId,
    );
  }

  @override
  List<Object?> get props => [id, date, amount, note, categoryKey, walletId, freelancePaymentId];
}

/// Mengurangi saldo satu dompet, dan boleh ditautkan ke satu pos anggaran.
final class ExpenseTransaction extends Transaction {
  /// Membuat [ExpenseTransaction].
  const ExpenseTransaction({
    required super.id,
    required super.date,
    required super.amount,
    required super.note,
    required this.walletId,
    super.categoryKey,
    this.budgetItemId,
  });

  /// Dompet yang berkurang.
  final String walletId;

  /// Pos anggaran yang ditambahi angka terpakainya. `null` berarti
  /// pengeluaran di luar anggaran mana pun.
  ///
  /// Tautan hanya sah kalau dompet anggarannya sama dengan [walletId] —
  /// aturan itu ditegakkan di lapisan yang mengetahui `Budget` (Fase 4),
  /// bukan di sini.
  final String? budgetItemId;

  /// Salinan [ExpenseTransaction] dengan field yang disebutkan diganti.
  ///
  /// ⚠ [budgetItemId] hanya diganti kalau diisi. Untuk melepas tautan pos
  /// anggaran, buat [ExpenseTransaction] baru secara langsung.
  ExpenseTransaction copyWith({
    DateTime? date,
    int? amount,
    String? note,
    String? categoryKey,
    String? walletId,
    String? budgetItemId,
  }) {
    return ExpenseTransaction(
      id: id,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      categoryKey: categoryKey ?? this.categoryKey,
      walletId: walletId ?? this.walletId,
      budgetItemId: budgetItemId ?? this.budgetItemId,
    );
  }

  @override
  List<Object?> get props => [id, date, amount, note, categoryKey, walletId, budgetItemId];
}

/// Memindahkan catatan uang antar dompet. Tidak mengubah total uang
/// pemilik, hanya tempatnya — dan tidak pernah dihitung sebagai pemasukan
/// maupun pengeluaran di ringkasan mana pun.
final class TransferTransaction extends Transaction {
  /// Membuat [TransferTransaction].
  const TransferTransaction({
    required super.id,
    required super.date,
    required super.amount,
    required super.note,
    required this.fromWalletId,
    required this.toWalletId,
    super.categoryKey,
    this.budgetItemId,
  }) : assert(fromWalletId != toWalletId, 'Transfer butuh dua dompet berbeda.');

  /// Dompet yang berkurang.
  final String fromWalletId;

  /// Dompet yang bertambah. Selalu berbeda dari [fromWalletId].
  final String toWalletId;

  /// Pos anggaran yang ditambahi angka terpakainya, untuk pos yang memang
  /// berupa rencana pemindahan dana (misalnya setoran tabungan). `null`
  /// berarti transfer di luar anggaran mana pun.
  ///
  /// Yang menentukan apakah transfer ini terhitung ke sebuah pos adalah
  /// [fromWalletId] — uang keluar dari dompet anggaran — bukan [walletId]
  /// seperti pada [ExpenseTransaction].
  final String? budgetItemId;

  /// Salinan [TransferTransaction] dengan field yang disebutkan diganti.
  ///
  /// ⚠ [budgetItemId] hanya diganti kalau diisi. Untuk melepas tautan pos
  /// anggaran, buat [TransferTransaction] baru secara langsung.
  TransferTransaction copyWith({
    DateTime? date,
    int? amount,
    String? note,
    String? categoryKey,
    String? fromWalletId,
    String? toWalletId,
    String? budgetItemId,
  }) {
    return TransferTransaction(
      id: id,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      categoryKey: categoryKey ?? this.categoryKey,
      fromWalletId: fromWalletId ?? this.fromWalletId,
      toWalletId: toWalletId ?? this.toWalletId,
      budgetItemId: budgetItemId ?? this.budgetItemId,
    );
  }

  @override
  List<Object?> get props => [id, date, amount, note, categoryKey, fromWalletId, toWalletId, budgetItemId];
}
