import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/shared/investment/investment.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// ADR-049 §3.2–§3.5: jumlah berskala, rata-rata tertimbang, nilai pasar per
/// satuan harga, kesegaran.
void main() {
  final created = DateTime(2026);
  Instrument stock({OpeningHolding? opening}) =>
      Instrument(id: 'bbca', name: 'BBCA', type: InstrumentType.stock, createdAt: created, opening: opening);

  InvestmentTransaction trade(
    String id,
    InvestmentSide side,
    int lots,
    int amount, {
    DateTime? date,
    String instrumentId = 'bbca',
  }) => InvestmentTransaction(
    id: id,
    date: date ?? DateTime(2026, 2),
    amount: amount,
    note: '',
    walletId: 'w',
    instrumentId: instrumentId,
    side: side,
    quantity: lots * quantityScale,
  );

  group('marketValueOf', () {
    test('saham: lot × 100 lembar × harga per lembar', () {
      // 2 lot × 100 × Rp9.500 = Rp1.900.000.
      expect(marketValueOf(InstrumentType.stock, 2 * quantityScale, 950000), 190000000);
    });

    test('emas pecahan gram dibulatkan setengah ke atas ke sen', () {
      // 0,5 g × 1.234.567 sen/g = 617.283,5 → 617.284.
      expect(marketValueOf(InstrumentType.gold, 5000, 1234567), 617284);
    });

    test('obligasi: nominal × persen (basis poin ×100)', () {
      // Nominal Rp1.000.000 × 100,50% = Rp1.005.000.
      expect(marketValueOf(InstrumentType.bond, 100000000, 1005000), 100500000);
    });

    test('unitPriceFor kebalikan nilai total', () {
      expect(unitPriceFor(InstrumentType.stock, 2 * quantityScale, 190000000), 950000);
      expect(unitPriceFor(InstrumentType.bond, 100000000, 100500000), 1005000);
    });

    test('angka besar tidak meluap', () {
      expect(marketValueOf(InstrumentType.stock, 1000000 * quantityScale, 10000000000), 1000000000000000000);
    });
  });

  group('InstrumentPosition.replay', () {
    test('rata-rata tertimbang: jual sebagian mengurangi perolehan proporsional', () {
      final p = InstrumentPosition.replay(stock(), [
        trade('1', InvestmentSide.buy, 2, 1800000),
        trade('2', InvestmentSide.buy, 1, 1200000, date: DateTime(2026, 3)),
        trade('3', InvestmentSide.sell, 1, 1500000, date: DateTime(2026, 4)),
      ]);
      // Perolehan 3.000.000 untuk 3 lot, jual 1 lot: bagian 1.000.000.
      expect(p.quantity, 2 * quantityScale);
      expect(p.cost, 2000000);
      expect(p.realized, 500000);
      expect(p.isActive, isTrue);
    });

    test('jual habis memakai seluruh perolehan tanpa sisa pembulatan', () {
      final p = InstrumentPosition.replay(stock(), [
        trade('1', InvestmentSide.buy, 3, 1000000),
        trade('2', InvestmentSide.sell, 1, 300000, date: DateTime(2026, 3)),
        trade('3', InvestmentSide.sell, 2, 900000, date: DateTime(2026, 4)),
      ]);
      expect(p.quantity, 0);
      expect(p.cost, 0);
      // 300.000 − 333.333 + 900.000 − 666.667 = 200.000.
      expect(p.realized, 200000);
      expect(p.isActive, isFalse);
    });

    test('kepemilikan awal ikut dihitung dan mendahului transaksi bertanggal sama', () {
      final p = InstrumentPosition.replay(
        stock(opening: OpeningHolding(date: DateTime(2026, 2), quantity: quantityScale, cost: 900000)),
        [trade('1', InvestmentSide.sell, 1, 1000000)],
      );
      expect(p.isValid, isTrue);
      expect(p.realized, 100000);
    });

    test('jual melebihi jumlah pada tanggalnya tidak sah', () {
      final p = InstrumentPosition.replay(stock(), [
        trade('1', InvestmentSide.sell, 1, 1000000),
        trade('2', InvestmentSide.buy, 1, 900000, date: DateTime(2026, 3)),
      ]);
      expect(p.isValid, isFalse);
      expect(p.shortfallDate, DateTime(2026, 2));
    });

    test('transaksi instrumen lain diabaikan; asOf memotong', () {
      final p = InstrumentPosition.replay(stock(), [
        trade('1', InvestmentSide.buy, 1, 900000),
        trade('2', InvestmentSide.buy, 5, 100, instrumentId: 'tlkm'),
        trade('3', InvestmentSide.buy, 1, 900000, date: DateTime(2026, 5)),
      ], asOf: DateTime(2026, 3));
      expect(p.quantity, quantityScale);
    });

    test('instrumen baru tanpa aktivitas tetap Aktif', () {
      expect(InstrumentPosition.replay(stock(), const []).isActive, isTrue);
    });
  });

  group('InstrumentSummary', () {
    final trades = [trade('1', InvestmentSide.buy, 2, 1800000)];

    test('belum pernah divaluasi: nilai pasar = perolehan', () {
      final s = InstrumentSummary.of(stock(), trades, const []);
      expect(s.neverValued, isTrue);
      expect(s.marketValue, 1800000);
      expect(s.unrealized, 0);
      expect(s.isStale(DateTime(2027)), isFalse);
    });

    test('valuasi terakhir ≤ asOf dipakai, kesegaran 30 hari', () {
      final vals = [
        InstrumentValuation(instrumentId: 'bbca', date: DateTime(2026, 3), unitPrice: 10000),
        InstrumentValuation(instrumentId: 'bbca', date: DateTime(2026, 4), unitPrice: 12000),
      ];
      final s = InstrumentSummary.of(stock(), trades, vals);
      // 2 lot × 100 lembar × 12.000 sen = 2.400.000.
      expect(s.marketValue, 2400000);
      expect(s.unrealized, 600000);
      expect(s.isStale(DateTime(2026, 4, 30)), isFalse);
      expect(s.isStale(DateTime(2026, 5)), isTrue);
      expect(InstrumentSummary.of(stock(), trades, vals, asOf: DateTime(2026, 3, 15)).valuation?.unitPrice, 10000);
    });

    test('lapis Investasi dan hitungan batas hanya instrumen Aktif', () {
      final done = Instrument(id: 'tlkm', name: 'TLKM', type: InstrumentType.stock, createdAt: created);
      final all = [
        trade('1', InvestmentSide.buy, 1, 500000),
        trade('2', InvestmentSide.buy, 1, 400000, instrumentId: 'tlkm'),
        trade('3', InvestmentSide.sell, 1, 450000, instrumentId: 'tlkm', date: DateTime(2026, 3)),
      ];
      final summaries = [InstrumentSummary.of(stock(), all, const []), InstrumentSummary.of(done, all, const [])];
      expect(investmentLayerValue(summaries), 500000);
      expect(activeInstrumentCount(summaries), 1);
    });
  });
}
