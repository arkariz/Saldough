import 'package:saldough/features/card/domain/entities/recurring_subscription.dart';

/// Model serialisasi [RecurringSubscription].
final class RecurringSubscriptionModel {
  /// Membuat [RecurringSubscriptionModel].
  const RecurringSubscriptionModel({
    required this.id,
    required this.cardId,
    required this.merchant,
    required this.amount,
    required this.dayOfMonth,
    required this.isActive,
  });

  /// Membaca [RecurringSubscriptionModel] dari JSON.
  factory RecurringSubscriptionModel.fromJson(Map<String, dynamic> json) => RecurringSubscriptionModel(
        id: json['id'] as String,
        cardId: json['cardId'] as String,
        merchant: json['merchant'] as String,
        amount: json['amount'] as int,
        dayOfMonth: json['dayOfMonth'] as int,
        isActive: json['isActive'] as bool,
      );

  /// Membuat model dari entitas domain.
  factory RecurringSubscriptionModel.fromEntity(RecurringSubscription sub) => RecurringSubscriptionModel(
        id: sub.id,
        cardId: sub.cardId,
        merchant: sub.merchant,
        amount: sub.amount,
        dayOfMonth: sub.dayOfMonth,
        isActive: sub.isActive,
      );

  /// Versi skema dokumen ini. Naikkan kalau bentuk field berubah.
  static const schemaVersion = 1;

  /// Identitas langganan.
  final String id;

  /// Rujukan ke `CreditCard`.
  final String cardId;

  /// Nama merchant.
  final String merchant;

  /// Nominal per bulan dalam sen.
  final int amount;

  /// Tanggal transaksi disiapkan tiap bulan.
  final int dayOfMonth;

  /// Aktif/nonaktif.
  final bool isActive;

  /// Menulis [RecurringSubscriptionModel] ke JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'cardId': cardId,
        'merchant': merchant,
        'amount': amount,
        'dayOfMonth': dayOfMonth,
        'isActive': isActive,
      };

  /// Mengubah model jadi entitas domain.
  RecurringSubscription toEntity() => RecurringSubscription(
        id: id,
        cardId: cardId,
        merchant: merchant,
        amount: amount,
        dayOfMonth: dayOfMonth,
        isActive: isActive,
      );
}
