import 'package:dependencies/dependencies.dart';

/// Template langganan berulang pada sebuah kartu (FR-CARD-004). Disiapkan
/// otomatis jadi `CardTransaction` belum terkonfirmasi saat siklus tagihan
/// baru dibuka — lihat `CloseCardStatement`.
final class RecurringSubscription extends Equatable {
  /// Membuat [RecurringSubscription].
  const RecurringSubscription({
    required this.id,
    required this.cardId,
    required this.merchant,
    required this.amount,
    required this.dayOfMonth,
    this.isActive = true,
  });

  /// Identitas langganan.
  final String id;

  /// Rujukan ke `CreditCard`.
  final String cardId;

  /// Nama merchant, misalnya `"Claude AI"`.
  final String merchant;

  /// Nominal per bulan dalam sen — nilai TERAKHIR diketahui, bukan
  /// dipercaya penuh. Nominal langganan bisa berubah antar siklus (contoh
  /// nyata: Rp337.760 lalu Rp358.600), makanya transaksi hasil penyiapannya
  /// selalu wajib dikonfirmasi dulu.
  final int amount;

  /// Tanggal transaksi disiapkan tiap bulan.
  final int dayOfMonth;

  /// False untuk menonaktifkan langganan tanpa menghapus riwayat
  /// transaksinya yang sudah ada (FR-CARD-004).
  final bool isActive;

  /// Salinan [RecurringSubscription] dengan field yang disebutkan diganti.
  RecurringSubscription copyWith({String? merchant, int? amount, int? dayOfMonth, bool? isActive}) {
    return RecurringSubscription(
      id: id,
      cardId: cardId,
      merchant: merchant ?? this.merchant,
      amount: amount ?? this.amount,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [id, cardId, merchant, amount, dayOfMonth, isActive];
}
