import 'package:dependencies/dependencies.dart';
import 'package:saldough/shared/investment/domain/instrument.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// `a × b ÷ c` dibulatkan setengah ke atas, tanpa luapan (`a`, `b` ≥ 0,
/// `c` > 0).
int mulDivRound(int a, int b, int c) {
  final n = BigInt.from(a) * BigInt.from(b);
  final d = BigInt.from(c);
  return ((n + d ~/ BigInt.two) ~/ d).toInt();
}

/// Nilai pasar [quantity] instrumen berjenis [type] pada harga [unitPrice],
/// dalam sen (ADR-049 §3.4).
int marketValueOf(InstrumentType type, int quantity, int unitPrice) => switch (type) {
  InstrumentType.stock => mulDivRound(quantity * sharesPerLot, unitPrice, quantityScale),
  InstrumentType.bond => mulDivRound(quantity, unitPrice, bondPriceScale),
  InstrumentType.mutualFund || InstrumentType.gold || InstrumentType.other => mulDivRound(
    quantity,
    unitPrice,
    quantityScale,
  ),
};

/// Harga per satuan harga yang membuat [quantity] bernilai [totalValue]
/// (formulir "isi nilai total", ADR-049 §3.4), dibulatkan ke sen.
int unitPriceFor(InstrumentType type, int quantity, int totalValue) => switch (type) {
  InstrumentType.stock => mulDivRound(totalValue, quantityScale, quantity * sharesPerLot),
  InstrumentType.bond => mulDivRound(totalValue, bondPriceScale, quantity),
  InstrumentType.mutualFund || InstrumentType.gold || InstrumentType.other => mulDivRound(
    totalValue,
    quantityScale,
    quantity,
  ),
};

/// Posisi satu instrumen hasil memutar ulang aktivitasnya (ADR-049 §3.5):
/// jumlah, nilai perolehan bagian yang masih dipegang, dan untung/rugi
/// terwujud. Biaya yang dijual memakai rata-rata tertimbang (KT-A1).
final class InstrumentPosition extends Equatable {
  /// Membuat [InstrumentPosition].
  const InstrumentPosition({
    required this.quantity,
    required this.cost,
    required this.realized,
    required this.hasActivity,
    this.shortfallDate,
  });

  /// Memutar ulang kepemilikan awal [instrument] dan [transactions] (hanya
  /// yang menunjuk instrumen ini dihitung), urut tanggal lalu `id`. Bila
  /// [asOf] diisi, hanya aktivitas sampai tanggal itu.
  ///
  /// Penjualan yang melebihi jumlah saat itu menghentikan pemutaran dan
  /// mengisi [shortfallDate] (§3.6): posisinya tidak sah.
  factory InstrumentPosition.replay(
    Instrument instrument,
    Iterable<Transaction> transactions, {
    DateTime? asOf,
  }) {
    final trades = [
      for (final t in transactions)
        if (t is InvestmentTransaction && t.instrumentId == instrument.id) t,
    ]..sort((a, b) {
        final byDate = _day(a.date).compareTo(_day(b.date));
        return byDate != 0 ? byDate : a.id.compareTo(b.id);
      });
    final limit = asOf == null ? null : _day(asOf);
    var quantity = 0;
    var cost = 0;
    var realized = 0;
    var hasActivity = false;
    final opening = instrument.opening;
    // Kepemilikan awal mendahului transaksi bertanggal sama.
    if (opening != null && (limit == null || !opening.date.isAfter(limit))) {
      quantity = opening.quantity;
      cost = opening.cost;
      hasActivity = true;
    }
    for (final trade in trades) {
      final day = _day(trade.date);
      if (limit != null && day.isAfter(limit)) break;
      hasActivity = true;
      switch (trade.side) {
        case InvestmentSide.buy:
          quantity += trade.quantity;
          cost += trade.amount;
        case InvestmentSide.sell:
          if (trade.quantity > quantity) {
            return InstrumentPosition(
              quantity: quantity,
              cost: cost,
              realized: realized,
              hasActivity: true,
              shortfallDate: day,
            );
          }
          final portion = trade.quantity == quantity ? cost : mulDivRound(cost, trade.quantity, quantity);
          realized += trade.amount - portion;
          cost -= portion;
          quantity -= trade.quantity;
      }
    }
    return InstrumentPosition(quantity: quantity, cost: cost, realized: realized, hasActivity: hasActivity);
  }

  /// Jumlah yang dipegang (§3.2).
  final int quantity;

  /// Nilai perolehan bagian yang masih dipegang, sen.
  final int cost;

  /// Untung (positif) atau rugi (negatif) terwujud dari penjualan, sen.
  final int realized;

  /// Pernah ada kepemilikan awal atau transaksi.
  final bool hasActivity;

  /// Tanggal penjualan pertama yang melebihi jumlah, atau `null` bila sah.
  final DateTime? shortfallDate;

  /// Semua penjualan tertutup jumlah yang dipegang saat itu.
  bool get isValid => shortfallDate == null;

  /// Aktif: masih dipegang, atau baru dibuat tanpa aktivitas. Selesai tidak
  /// dihitung batas Gratis dan tidak masuk lapis Investasi.
  bool get isActive => quantity > 0 || !hasActivity;

  @override
  List<Object?> get props => [quantity, cost, realized, hasActivity, shortfallDate];
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
