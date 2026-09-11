import 'package:saldough/features/card/domain/entities/card_transaction.dart';

/// Model serialisasi [CardTransaction].
final class CardTransactionModel {
  /// Membuat [CardTransactionModel].
  const CardTransactionModel({
    required this.id,
    required this.date,
    required this.merchant,
    required this.amount,
    required this.note,
    required this.isConfirmed,
  });

  /// Membaca [CardTransactionModel] dari JSON.
  factory CardTransactionModel.fromJson(Map<String, dynamic> json) => CardTransactionModel(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        merchant: json['merchant'] as String,
        amount: json['amount'] as int,
        note: json['note'] as String,
        isConfirmed: json['isConfirmed'] as bool,
      );

  /// Membuat model dari entitas domain.
  factory CardTransactionModel.fromEntity(CardTransaction transaction) => CardTransactionModel(
        id: transaction.id,
        date: transaction.date,
        merchant: transaction.merchant,
        amount: transaction.amount,
        note: transaction.note,
        isConfirmed: transaction.isConfirmed,
      );

  /// Identitas transaksi.
  final String id;

  /// Tanggal transaksi.
  final DateTime date;

  /// Nama merchant.
  final String merchant;

  /// Nominal dalam sen.
  final int amount;

  /// Catatan bebas.
  final String note;

  /// True kalau sudah dikonfirmasi (FR-CARD-004).
  final bool isConfirmed;

  /// Menulis [CardTransactionModel] ke JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'merchant': merchant,
        'amount': amount,
        'note': note,
        'isConfirmed': isConfirmed,
      };

  /// Mengubah model jadi entitas domain.
  CardTransaction toEntity() => CardTransaction(
        id: id,
        date: date,
        merchant: merchant,
        amount: amount,
        note: note,
        isConfirmed: isConfirmed,
      );
}
