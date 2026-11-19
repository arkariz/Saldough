import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/shared/investment/investment.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:saldough/shared/wealth/wealth.dart';

DateTime d(int day) => DateTime(2026, 10, day);

Wallet wallet(String id, int initial, {DateTime? createdAt, bool active = true}) => Wallet(
  id: id,
  name: id,
  iconKey: 'walletBank',
  initialBalance: initial,
  currentBalance: initial,
  isActive: active,
  createdAt: createdAt,
);

IncomeTransaction income(String id, int day, int amount, String w) =>
    IncomeTransaction(id: id, date: d(day), amount: amount, note: '', walletId: w);

ExpenseTransaction expense(String id, int day, int amount, String w) =>
    ExpenseTransaction(id: id, date: d(day), amount: amount, note: '', walletId: w);

InvestmentTransaction trade(String id, int day, InvestmentSide side, int qty, int amount, String w) =>
    InvestmentTransaction(
      id: id,
      date: d(day),
      amount: amount,
      note: '',
      walletId: w,
      instrumentId: 'bbca',
      side: side,
      quantity: qty,
    );

void main() {
  perfMain();
  final bbca = Instrument(id: 'bbca', name: 'BBCA', type: InstrumentType.stock, createdAt: d(1));
  // Harga per lembar dalam sen; 1 lot = 100 lembar.
  InstrumentValuation price(int day, int unit) => InstrumentValuation(instrumentId: 'bbca', date: d(day), unitPrice: unit);

  group('WealthHistory.at', () {
    test('saldo dompet dan lapis mengikuti tanggal; dompet tujuan masuk Tabungan', () {
      final history = WealthHistory(
        wallets: [wallet('a', 100000, createdAt: d(1)), wallet('s', 0, createdAt: d(1))],
        transactions: [
          income('i1', 2, 50000, 'a'),
          expense('e1', 4, 20000, 'a'),
          TransferTransaction(id: 't1', date: d(5), amount: 30000, note: '', fromWalletId: 'a', toWalletId: 's'),
        ],
        goalWalletIds: {'s'},
      );
      expect(history.at(d(1)).total, 100000);
      expect(history.at(d(3)).operational, 150000);
      final p = history.at(d(5));
      expect((p.operational, p.savings, p.total), (100000, 30000, 130000));
    });

    test('dompet nonaktif tidak dihitung; dompet baru baru ikut sejak createdAt', () {
      final history = WealthHistory(
        wallets: [wallet('a', 1000, createdAt: d(1)), wallet('off', 9999, active: false), wallet('b', 500, createdAt: d(5))],
        transactions: const [],
      );
      expect(history.at(d(4)).total, 1000);
      expect(history.at(d(5)).total, 1500);
    });

    test('dompet lama tanpa createdAt dihitung sejak transaksi tertuanya', () {
      final history = WealthHistory(
        wallets: [wallet('a', 1000), wallet('old', 700)],
        transactions: [income('i1', 6, 100, 'old')],
      );
      expect(history.at(d(5)).total, 1000);
      expect(history.at(d(6)).total, 1000 + 800);
    });

    test('investasi: jumlah pada tanggal × valuasi terakhir; belum divaluasi = nilai perolehan', () {
      final history = WealthHistory(
        wallets: [wallet('a', 5000000, createdAt: d(1))],
        transactions: [trade('b1', 3, InvestmentSide.buy, 20000, 1000000, 'a')],
        instruments: [bbca],
        valuations: [price(5, 6000)],
      );
      expect(history.at(d(2)).investment, 0);
      final bought = history.at(d(3));
      expect((bought.investment, bought.operational, bought.total), (1000000, 4000000, 5000000));
      expect(bought.hasStale, isTrue, reason: 'belum pernah divaluasi');
      final valued = history.at(d(5));
      expect(valued.investment, 1200000);
      expect(valued.hasStale, isFalse);
      expect(history.at(DateTime(2026, 12, 20)).hasStale, isTrue, reason: 'valuasi > 30 hari');
    });

    test('menjual semua habis dari lapis Investasi', () {
      final history = WealthHistory(
        wallets: [wallet('a', 5000000, createdAt: d(1))],
        transactions: [
          trade('b1', 3, InvestmentSide.buy, 20000, 1000000, 'a'),
          trade('s1', 8, InvestmentSide.sell, 20000, 1300000, 'a'),
        ],
        instruments: [bbca],
        valuations: [price(5, 6000)],
      );
      final p = history.at(d(8));
      expect((p.investment, p.operational), (0, 5300000));
    });
  });

  group('WealthHistory.change', () {
    final history = WealthHistory(
      wallets: [
        wallet('a', 1000000, createdAt: d(1)),
        wallet('b', 200000, createdAt: d(6)),
        wallet('c', 40000, createdAt: d(1)),
      ],
      transactions: [
        income('i1', 2, 500000, 'a'),
        expense('e1', 3, 120000, 'a'),
        TransferTransaction(id: 't1', date: d(4), amount: 100000, note: '', fromWalletId: 'a', toWalletId: 'b'),
        TransferTransaction(id: 't2', date: d(7), amount: 50000, note: '', fromWalletId: 'a', toWalletId: 'c'),
        BalanceAdjustmentTransaction(
          id: 'adj1',
          date: d(9),
          amount: 25000,
          note: '',
          walletId: 'a',
          direction: AdjustmentDirection.decrease,
        ),
        trade('b1', 5, InvestmentSide.buy, 20000, 1000000, 'a'),
        trade('s1', 12, InvestmentSide.sell, 10000, 700000, 'a'),
        expense('back', 3, 10000, 'b'), // mundur sebelum createdAt dompet b
        income('c1', 10, 5000, 'c'),
      ],
      instruments: [
        bbca,
        Instrument(
          id: 'gold',
          name: 'Emas',
          type: InstrumentType.gold,
          createdAt: d(2),
          opening: OpeningHolding(date: d(8), quantity: 20000, cost: 900000),
        ),
      ],
      valuations: [
        price(5, 5000),
        price(11, 8000),
        InstrumentValuation(instrumentId: 'gold', date: d(8), unitPrice: 500000),
        InstrumentValuation(instrumentId: 'gold', date: d(13), unitPrice: 520000),
      ],
      goalWalletIds: {'c'},
    );

    test('empat golongan berjumlah tepat selisih Total aset untuk setiap pasangan tanggal', () {
      for (var s = 1; s <= 14; s++) {
        for (var e = s + 1; e <= 15; e++) {
          final change = history.change(d(s), d(e));
          expect(change.total, history.at(d(e)).total - history.at(d(s)).total, reason: 'hari $s → $e');
        }
      }
    });

    test('golongan: arus, penyesuaian, pencatatan awal, dan nilai investasi', () {
      final c = history.change(d(1), d(14));
      expect(c.adjustment, -25000);
      // Dompet b baru (saldo awal 200.000) dan emas pembukaan (perolehan
      // 900.000) masuk pencatatan awal; pengeluaran mundur 10.000 di b
      // bertanggal di dalam periode, jadi ikut Arus.
      expect(c.opening, 200000 + 900000);
      expect(c.flow, 500000 - 120000 - 10000 + 5000);
      // Nilai investasi: dikurangi uang yang dimasukkan lewat beli/jual.
      expect(c.investmentValue, c.total - c.flow - c.adjustment - c.opening);
      expect(c.investmentValue, greaterThan(0));
    });

    test('transfer antar dompet yang sama-sama dihitung tidak mengubah Total', () {
      final onlyTransfer = WealthHistory(
        wallets: [wallet('a', 1000, createdAt: d(1)), wallet('b', 0, createdAt: d(1))],
        transactions: [TransferTransaction(id: 't', date: d(3), amount: 400, note: '', fromWalletId: 'a', toWalletId: 'b')],
      );
      final c = onlyTransfer.change(d(1), d(5));
      expect((c.flow, c.total), (0, 0));
    });
  });
}

/// Pengukuran T-32.4 (ADR-050 §3.6): 10.000 transaksi, 5 tahun, 60 titik
/// bulanan. Batasnya longgar agar tidak rapuh di mesin lambat; angka
/// sebenarnya dicatat di ADR.
void perfMain() {
  test('kinerja: 10.000 transaksi × 60 titik bulanan', () {
    DateTime dayOf(int i) => DateTime(2022).add(Duration(days: i % 1800));
    final txs = <Transaction>[
      for (var i = 0; i < 10000; i++)
        if (i % 10 == 0)
          InvestmentTransaction(
            id: 'b$i',
            date: dayOf(i),
            amount: 100000,
            note: '',
            walletId: 'a',
            instrumentId: 'i${i % 5}',
            side: InvestmentSide.buy,
            quantity: 10000,
          )
        else
          IncomeTransaction(id: 'i$i', date: dayOf(i), amount: 1000, note: '', walletId: 'a'),
    ];
    final history = WealthHistory(
      wallets: [for (final id in ['a', 'b', 'c']) wallet(id, 0, createdAt: DateTime(2022))],
      transactions: txs,
      instruments: [
        for (var k = 0; k < 5; k++) Instrument(id: 'i$k', name: 'I$k', type: InstrumentType.stock, createdAt: DateTime(2022)),
      ],
      valuations: [
        for (var k = 0; k < 5; k++)
          for (var m = 0; m < 60; m++) InstrumentValuation(instrumentId: 'i$k', date: DateTime(2022, 1 + m), unitPrice: 1000 + m),
      ],
    );
    final sw = Stopwatch()..start();
    final points = history.series([for (var m = 0; m < 60; m++) DateTime(2022, 2 + m, 0)]);
    final seriesMs = sw.elapsedMilliseconds;
    sw.reset();
    history.change(DateTime(2026, 9, 30), DateTime(2026, 10, 31));
    final changeMs = sw.elapsedMilliseconds;
    // Sengaja mencetak: angka pengukuran dicatat di ADR-050.
    // ignore: avoid_print
    print('PERF series=${seriesMs}ms change=${changeMs}ms points=${points.length}');
    expect(seriesMs, lessThan(5000));
  });
}
