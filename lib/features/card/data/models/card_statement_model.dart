import 'package:saldough/features/card/data/models/card_transaction_model.dart';
import 'package:saldough/features/card/domain/entities/card_statement.dart';

/// Model serialisasi [CardStatement].
final class CardStatementModel {
  /// Membuat [CardStatementModel].
  const CardStatementModel({
    required this.id,
    required this.cardId,
    required this.periodStart,
    required this.periodEnd,
    required this.transactions,
    this.closedAt,
  });

  /// Membaca [CardStatementModel] dari JSON.
  factory CardStatementModel.fromJson(Map<String, dynamic> json) => CardStatementModel(
        id: json['id'] as String,
        cardId: json['cardId'] as String,
        periodStart: DateTime.parse(json['periodStart'] as String),
        periodEnd: DateTime.parse(json['periodEnd'] as String),
        transactions: (json['transactions'] as List<dynamic>)
            .map((e) => CardTransactionModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        closedAt: json['closedAt'] == null ? null : DateTime.parse(json['closedAt'] as String),
      );

  /// Membuat model dari entitas domain.
  factory CardStatementModel.fromEntity(CardStatement statement) => CardStatementModel(
        id: statement.id,
        cardId: statement.cardId,
        periodStart: statement.periodStart,
        periodEnd: statement.periodEnd,
        transactions: statement.transactions.map(CardTransactionModel.fromEntity).toList(),
        closedAt: statement.closedAt,
      );

  /// Versi skema dokumen ini. Naikkan kalau bentuk field berubah.
  static const schemaVersion = 1;

  /// Identitas siklus tagihan.
  final String id;

  /// Rujukan ke `CreditCard`.
  final String cardId;

  /// Tanggal mulai periode.
  final DateTime periodStart;

  /// Tanggal cetak, akhir periode.
  final DateTime periodEnd;

  /// Transaksi dalam periode ini.
  final List<CardTransactionModel> transactions;

  /// Terisi saat siklus tagihan ditutup.
  final DateTime? closedAt;

  /// Menulis [CardStatementModel] ke JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'cardId': cardId,
        'periodStart': periodStart.toIso8601String(),
        'periodEnd': periodEnd.toIso8601String(),
        'transactions': transactions.map((t) => t.toJson()).toList(),
        'closedAt': closedAt?.toIso8601String(),
      };

  /// Mengubah model jadi entitas domain.
  CardStatement toEntity() => CardStatement(
        id: id,
        cardId: cardId,
        periodStart: periodStart,
        periodEnd: periodEnd,
        transactions: transactions.map((t) => t.toEntity()).toList(),
        closedAt: closedAt,
      );
}
