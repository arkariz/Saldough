import 'package:dependencies/dependencies.dart';
import 'package:saldough/shared/investment/investment.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Nilai kekayaan pada satu tanggal, per lapis (ADR-050 §3.6). Semua sen.
final class WealthPoint extends Equatable {
  /// Membuat [WealthPoint].
  const WealthPoint({
    required this.date,
    required this.operational,
    required this.savings,
    required this.investment,
    this.hasStale = false,
  });

  /// Tanggal (hari) titik ini.
  final DateTime date;

  /// Lapis Dompet.
  final int operational;

  /// Lapis Tabungan.
  final int savings;

  /// Lapis Investasi: nilai pasar instrumen.
  final int investment;

  /// Ada instrumen yang dipegang dengan valuasi terakhir lebih tua dari
  /// [staleAfterDays] (atau belum pernah divaluasi) pada tanggal ini.
  final bool hasStale;

  /// Total aset.
  int get total => operational + savings + investment;

  @override
  List<Object?> get props => [date, operational, savings, investment, hasStale];
}

/// Perubahan Total aset antara dua tanggal, dipecah empat golongan yang
/// jumlahnya tepat selisihnya (ADR-050 §3.6).
final class WealthChange extends Equatable {
  /// Membuat [WealthChange].
  const WealthChange({
    required this.flow,
    required this.investmentValue,
    required this.adjustment,
    required this.opening,
  });

  /// Arus: pemasukan − pengeluaran (+ transfer ke/dari dompet di luar Total).
  final int flow;

  /// Nilai investasi: perubahan nilai instrumen setelah uang yang
  /// dimasukkan/ditarik lewat beli/jual. Bukan pemasukan.
  final int investmentValue;

  /// Penyesuaian saldo bersih (ADR-047).
  final int adjustment;

  /// Pencatatan awal: saldo awal dompet baru dan kepemilikan yang sudah ada
  /// (nilai perolehannya) yang masuk pada periode itu.
  final int opening;

  /// Jumlah keempatnya = selisih Total aset.
  int get total => flow + investmentValue + adjustment + opening;

  @override
  List<Object?> get props => [flow, investmentValue, adjustment, opening];
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// Riwayat kekayaan: nilai Total aset pada tanggal mana pun dan perubahannya
/// antar tanggal (ADR-050 §3.6). Dart murni, tanpa I/O; rumus saldo dompet
/// dan posisi instrumen sama dengan yang dipakai layar lain.
///
/// Hanya dompet yang aktif sekarang dihitung (seperti Total aset hari ini),
/// mulai dari `createdAt` atau, bila `null`, dari transaksi tertuanya.
final class WealthHistory {
  /// Membuat [WealthHistory] dari data saat ini.
  WealthHistory({
    required Iterable<Wallet> wallets,
    required Iterable<Transaction> transactions,
    Iterable<Instrument> instruments = const [],
    Iterable<InstrumentValuation> valuations = const [],
    this.goalWalletIds = const {},
  }) : _wallets = wallets.where((w) => w.isActive).toList(),
       _txs = ([...transactions]..sort((a, b) => _day(a.date).compareTo(_day(b.date)))),
       _instruments = instruments.toList(),
       _valuations = valuations.toList() {
    _days = [for (final t in _txs) _day(t.date)];
    for (final t in _txs) {
      for (final id in _walletIdsOf(t)) {
        _firstDay.putIfAbsent(id, () => _day(t.date));
      }
    }
    for (final t in _txs) {
      if (t is InvestmentTransaction) (_tradesBy[t.instrumentId] ??= []).add(t);
    }
  }

  final List<Wallet> _wallets;
  final List<Transaction> _txs;
  final List<Instrument> _instruments;
  final List<InstrumentValuation> _valuations;
  /// Dompet milik tujuan: masuk lapis Tabungan.
  final Set<String> goalWalletIds;
  late final List<DateTime> _days;
  final Map<String, DateTime> _firstDay = {};
  final Map<String, List<InvestmentTransaction>> _tradesBy = {};

  static const _balance = CalculateWalletBalance();

  static Iterable<String> _walletIdsOf(Transaction t) => switch (t) {
    IncomeTransaction(:final walletId) => [walletId],
    ExpenseTransaction(:final walletId) => [walletId],
    TransferTransaction(:final fromWalletId, :final toWalletId) => [fromWalletId, toWalletId],
    BalanceAdjustmentTransaction(:final walletId) => [walletId],
    InvestmentTransaction(:final walletId) => [walletId],
  };

  /// Jumlah transaksi bertanggal ≤ [day].
  int _countUpTo(DateTime day) {
    var lo = 0;
    var hi = _days.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (_days[mid].isAfter(day)) {
        hi = mid;
      } else {
        lo = mid + 1;
      }
    }
    return lo;
  }

  /// Dompet dihitung pada [day]?
  bool _included(Wallet w, DateTime day) {
    final created = w.createdAt;
    if (created != null) return !_day(created).isAfter(day);
    final first = _firstDay[w.id];
    return first == null || !first.isAfter(day);
  }

  /// Nilai kekayaan pada [date].
  WealthPoint at(DateTime date) {
    final day = _day(date);
    final upTo = _txs.sublist(0, _countUpTo(day));
    var operational = 0;
    var savings = 0;
    for (final w in _wallets) {
      if (!_included(w, day)) continue;
      final balance = _balance(w, upTo);
      if (goalWalletIds.contains(w.id)) {
        savings += balance;
      } else {
        operational += balance;
      }
    }
    var investment = 0;
    var stale = false;
    for (final i in _instruments) {
      final s = InstrumentSummary.of(i, _tradesBy[i.id] ?? const [], _valuations, asOf: day);
      if (s.position.quantity <= 0) continue;
      investment += s.marketValue;
      final v = s.valuation;
      if (v == null || day.difference(_day(v.date)).inDays > staleAfterDays) stale = true;
    }
    return WealthPoint(date: day, operational: operational, savings: savings, investment: investment, hasStale: stale);
  }

  /// Nilai kekayaan pada tiap tanggal di [dates], berurutan seperti diberikan.
  List<WealthPoint> series(Iterable<DateTime> dates) => [for (final d in dates) at(d)];

  /// Perubahan Total aset dari akhir [from] sampai akhir [to] (`from` < `to`),
  /// dipecah empat golongan.
  WealthChange change(DateTime from, DateTime to) {
    final s = _day(from);
    final e = _day(to);
    var flow = 0;
    var adjustment = 0;
    var opening = 0;
    var cashIntoInvestments = 0; // uang dompet (yang dihitung) yang masuk instrumen

    bool inPeriod(Transaction t) {
      final d = _day(t.date);
      return d.isAfter(s) && !d.isAfter(e);
    }

    for (final w in _wallets) {
      final atEnd = _included(w, e);
      if (!atEnd) continue;
      final atStart = _included(w, s);
      if (!atStart) {
        // Dompet baru: saldo awal dan transaksi bertanggal sebelum/sama s
        // (mundur ke belakang) masuk pencatatan awal.
        opening += w.initialBalance;
        opening += _balance(w, _txs.sublist(0, _countUpTo(s))) - w.initialBalance;
      }
      for (final t in _txs) {
        if (!inPeriod(t)) continue;
        switch (t) {
          case IncomeTransaction(:final walletId, :final amount):
            if (walletId == w.id) flow += amount;
          case ExpenseTransaction(:final walletId, :final amount):
            if (walletId == w.id) flow -= amount;
          case TransferTransaction(:final fromWalletId, :final toWalletId, :final amount):
            if (toWalletId == w.id) flow += amount;
            if (fromWalletId == w.id) flow -= amount;
          case BalanceAdjustmentTransaction(:final walletId, :final signedAmount):
            if (walletId == w.id) adjustment += signedAmount;
          case InvestmentTransaction(:final walletId, :final signedAmount):
            if (walletId == w.id) cashIntoInvestments -= signedAmount;
        }
      }
    }

    var investmentDelta = 0;
    var openingCosts = 0;
    for (final i in _instruments) {
      investmentDelta += _instrumentValue(i, e) - _instrumentValue(i, s);
      final o = i.opening;
      if (o == null) continue;
      final d = _day(o.date);
      if (d.isAfter(s) && !d.isAfter(e)) openingCosts += o.cost;
    }
    opening += openingCosts;
    return WealthChange(
      flow: flow,
      investmentValue: investmentDelta - cashIntoInvestments - openingCosts,
      adjustment: adjustment,
      opening: opening,
    );
  }

  int _instrumentValue(Instrument i, DateTime day) {
    final s = InstrumentSummary.of(i, _tradesBy[i.id] ?? const [], _valuations, asOf: day);
    return s.position.quantity <= 0 ? 0 : s.marketValue;
  }
}
