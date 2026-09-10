import 'package:saldough/features/card/domain/entities/credit_card.dart';

/// Model serialisasi [CreditCard].
final class CreditCardModel {
  /// Membuat [CreditCardModel].
  const CreditCardModel({required this.id, required this.name, required this.statementDayOfMonth});

  /// Membaca [CreditCardModel] dari JSON.
  factory CreditCardModel.fromJson(Map<String, dynamic> json) => CreditCardModel(
        id: json['id'] as String,
        name: json['name'] as String,
        statementDayOfMonth: json['statementDayOfMonth'] as int,
      );

  /// Membuat model dari entitas domain.
  factory CreditCardModel.fromEntity(CreditCard card) => CreditCardModel(
        id: card.id,
        name: card.name,
        statementDayOfMonth: card.statementDayOfMonth,
      );

  /// Versi skema dokumen ini. Naikkan kalau bentuk field berubah.
  static const schemaVersion = 1;

  /// Identitas kartu.
  final String id;

  /// Nama kartu.
  final String name;

  /// Tanggal cetak tagihan.
  final int statementDayOfMonth;

  /// Menulis [CreditCardModel] ke JSON.
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'statementDayOfMonth': statementDayOfMonth};

  /// Mengubah model jadi entitas domain.
  CreditCard toEntity() => CreditCard(id: id, name: name, statementDayOfMonth: statementDayOfMonth);
}
