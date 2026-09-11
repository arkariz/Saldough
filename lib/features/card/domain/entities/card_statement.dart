import 'package:dependencies/dependencies.dart';
import 'package:saldough/features/card/domain/entities/card_transaction.dart';

/// Satu siklus tagihan kartu kredit — kumpulan transaksi dalam satu periode
/// (T-4.7). Lihat DOMAIN_MODEL.md bagian "Kartu kredit".
final class CardStatement extends Equatable {
  /// Membuat [CardStatement].
  const CardStatement({
    required this.id,
    required this.cardId,
    required this.periodStart,
    required this.periodEnd,
    required this.transactions,
    this.closedAt,
  });

  /// Identitas siklus tagihan.
  final String id;

  /// Rujukan ke `CreditCard`.
  final String cardId;

  /// Tanggal mulai periode (inklusif).
  final DateTime periodStart;

  /// Tanggal cetak, akhir periode (inklusif).
  final DateTime periodEnd;

  /// Transaksi dalam periode ini.
  final List<CardTransaction> transactions;

  /// Terisi saat siklus tagihan ditutup. Null berarti masih terbuka.
  final DateTime? closedAt;

  /// True kalau siklus tagihan sudah ditutup.
  bool get isClosed => closedAt != null;

  /// Jumlah transaksi yang sudah dikonfirmasi — inilah yang disuntikkan ke
  /// baris anggaran (`cardRollUp`, FR-CARD-005). Transaksi langganan yang
  /// belum dikonfirmasi (FR-CARD-004) tidak ikut terhitung.
  int get confirmedTotal =>
      transactions.where((t) => t.isConfirmed).fold(0, (sum, t) => sum + t.amount);

  /// Salinan [CardStatement] dengan [transaction] ditambahkan di akhir.
  CardStatement withTransaction(CardTransaction transaction) =>
      copyWith(transactions: [...transactions, transaction]);

  /// Salinan [CardStatement] yang ditutup pada [at] (bawaan waktu sekarang).
  CardStatement close({DateTime? at}) {
    return CardStatement(
      id: id,
      cardId: cardId,
      periodStart: periodStart,
      periodEnd: periodEnd,
      transactions: transactions,
      closedAt: at ?? DateTime.now(),
    );
  }

  /// Salinan [CardStatement] dengan field yang disebutkan diganti.
  CardStatement copyWith({List<CardTransaction>? transactions}) {
    return CardStatement(
      id: id,
      cardId: cardId,
      periodStart: periodStart,
      periodEnd: periodEnd,
      transactions: transactions ?? this.transactions,
      closedAt: closedAt,
    );
  }

  @override
  List<Object?> get props => [id, cardId, periodStart, periodEnd, transactions, closedAt];
}
