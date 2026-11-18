import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/shared/investment/investment.dart';
import 'package:saldough/shared/transaction/data/transaction_model.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// ADR-049 §3.3, §3.6, §3.7, §3.12: beli/jual lewat RecordTransaction
/// mengubah saldo dompet tetapi tidak Arus; posisi negatif ditolak; hapus
/// instrumen bercatatan ditolak; batas Aktif.
void main() {
  late InMemoryKeyValueStorage storage;
  late WalletRepositoryImpl wallets;
  late TransactionRepositoryImpl transactions;
  late InvestmentRepositoryImpl investments;
  final now = DateTime(2026, 11, 18, 9);

  const bca = Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 10000000, currentBalance: 10000000);
  Instrument instrument(String id, {OpeningHolding? opening}) =>
      Instrument(id: id, name: id.toUpperCase(), type: InstrumentType.stock, createdAt: now, opening: opening);
  InvestmentTransaction trade(String id, InvestmentSide side, int lots, int amount, {String on = 'bbca', DateTime? date}) =>
      InvestmentTransaction(
        id: id,
        date: date ?? now,
        amount: amount,
        note: '',
        walletId: 'bca',
        instrumentId: on,
        side: side,
        quantity: lots * quantityScale,
      );

  RecordTransaction record() => RecordTransaction(
    ledgerChanges: LedgerChanges(),
    transactionRepository: transactions,
    recomputeWalletBalances: RecomputeWalletBalances(walletRepository: wallets, transactionRepository: transactions),
    investmentGuard: InvestmentPositionGuard(investments: investments, transactions: transactions),
  );
  LoadInstrumentSummaries summaries() => LoadInstrumentSummaries(investments: investments, transactions: transactions);
  CreateInstrument create() => CreateInstrument(investments: investments, summaries: summaries());
  RecordInvestment recordInvestment() =>
      RecordInvestment(recordTransaction: record(), create: create(), summaries: summaries());

  Future<int> balance() async =>
      (await wallets.listWallets()).getOrElse((_) => throw StateError('x')).single.currentBalance;
  FailureCode? codeOf<T>(Either<Failure, T> result) => result.fold((f) => f.code, (_) => null);
  T ok<T>(Either<Failure, T> result) => result.getOrElse((f) => throw StateError('$f'));

  setUp(() async {
    storage = InMemoryKeyValueStorage();
    wallets = WalletRepositoryImpl(storage: storage);
    transactions = TransactionRepositoryImpl(storage: storage);
    investments = InvestmentRepositoryImpl(storage: storage);
    await wallets.saveWallet(bca);
  });

  test('beli instrumen baru lewat CATAT: saldo turun, Arus tetap 0', () async {
    ok(await recordInvestment()(trade('b1', InvestmentSide.buy, 2, 1800000), newInstrument: instrument('bbca')));
    expect(await balance(), 10000000 - 1800000);
    final all = ok(await transactions.listAllTransactions());
    final flow = const CalculateCashFlow()(all, month: now);
    expect((flow.income, flow.expense), (0, 0));
    final s = ok(await summaries()()).single;
    expect((s.position.quantity, s.position.cost), (2 * quantityScale, 1800000));
  });

  test('jual mengembalikan hasil bersih ke dompet; untung terwujud bukan pemasukan', () async {
    ok(await recordInvestment()(trade('b1', InvestmentSide.buy, 2, 1800000), newInstrument: instrument('bbca')));
    ok(await recordInvestment()(trade('s1', InvestmentSide.sell, 1, 1000000, date: now.add(const Duration(days: 1)))));
    expect(await balance(), 10000000 - 1800000 + 1000000);
    expect(ok(await summaries()()).single.position.realized, 100000);
    final flow = const CalculateCashFlow()(ok(await transactions.listAllTransactions()), month: now);
    expect(flow.income, 0);
  });

  test('jual lebih dari yang dimiliki ditolak, saldo tidak berubah', () async {
    ok(await recordInvestment()(trade('b1', InvestmentSide.buy, 1, 900000), newInstrument: instrument('bbca')));
    final result = await recordInvestment()(trade('s1', InvestmentSide.sell, 2, 2000000));
    expect(codeOf(result), InvestmentFailures.insufficientQuantity);
    expect(await balance(), 10000000 - 900000);
  });

  test('hapus beli yang membuat jual sesudahnya negatif ditolak', () async {
    ok(await recordInvestment()(trade('b1', InvestmentSide.buy, 1, 900000), newInstrument: instrument('bbca')));
    final sell = trade('s1', InvestmentSide.sell, 1, 1000000, date: now.add(const Duration(days: 1)));
    ok(await recordInvestment()(sell));
    final buy = ok(await transactions.listAllTransactions()).firstWhere((t) => t.id == 'b1');
    expect(codeOf(await record().delete(buy)), InvestmentFailures.insufficientQuantity);
    ok(await record().delete(sell));
    ok(await record().delete(buy));
    expect(await balance(), 10000000);
  });

  test('instrumen bercatatan tidak bisa dihapus; tanpa catatan terhapus bersama valuasinya', () async {
    ok(await recordInvestment()(trade('b1', InvestmentSide.buy, 1, 900000), newInstrument: instrument('bbca')));
    final delete = DeleteInstrument(investments: investments, transactions: transactions);
    expect(codeOf(await delete('bbca')), InvestmentFailures.hasRecords);
    ok(await create()(instrument('emas')));
    ok(await SaveValuations(investments: investments)([
      InstrumentValuation(instrumentId: 'emas', date: now, unitPrice: 100),
    ]));
    ok(await delete('emas'));
    expect(ok(await investments.listValuations()), isEmpty);
  });

  test('batas Aktif: ke-3 ditolak, instrumen Selesai tidak dihitung, beli lagi Selesai diperiksa', () async {
    ok(await create()(instrument('a'), activeLimit: 2));
    ok(await create()(instrument('b'), activeLimit: 2));
    expect(codeOf(await create()(instrument('c'), activeLimit: 2)), InvestmentFailures.limitReached);
    // Instrumen baru lewat CATAT juga tunduk batas, dan tidak meninggalkan apa pun.
    final viaRecord = await recordInvestment()(
      trade('b1', InvestmentSide.buy, 1, 100, on: 'c'),
      newInstrument: instrument('c'),
      activeLimit: 2,
    );
    expect(codeOf(viaRecord), InvestmentFailures.limitReached);
    expect(ok(await investments.listInstruments()).map((i) => i.id), ['a', 'b']);
    // b dibeli lalu dijual habis → Selesai, sehingga c boleh dibuat.
    ok(await recordInvestment()(trade('b2', InvestmentSide.buy, 1, 100, on: 'b'), activeLimit: 2));
    ok(await recordInvestment()(trade('s2', InvestmentSide.sell, 1, 100, on: 'b', date: now.add(const Duration(days: 1))), activeLimit: 2));
    ok(await create()(instrument('c'), activeLimit: 2));
    final again = await recordInvestment()(
      trade('b3', InvestmentSide.buy, 1, 100, on: 'b', date: now.add(const Duration(days: 2))),
      activeLimit: 2,
    );
    expect(codeOf(again), InvestmentFailures.limitReached);
    ok(await recordInvestment()(trade('b4', InvestmentSide.buy, 1, 100, on: 'a')));
  });

  test('jenis terkunci sesudah ada catatan; kepemilikan awal divalidasi ulang', () async {
    ok(await recordInvestment()(trade('b1', InvestmentSide.buy, 1, 900000), newInstrument: instrument('bbca')));
    final update = UpdateInstrument(investments: investments, transactions: transactions);
    final asGold = Instrument(id: 'bbca', name: 'BBCA', type: InstrumentType.gold, createdAt: now);
    expect(codeOf(await update(asGold)), InvestmentFailures.typeLocked);
    ok(await recordInvestment()(trade('s1', InvestmentSide.sell, 1, 1000000, date: now.add(const Duration(days: 1)))));
    final opening = OpeningHolding(date: DateTime(2026), quantity: quantityScale, cost: 500000);
    ok(await update(instrument('bbca', opening: opening)));
    ok(await recordInvestment()(trade('s2', InvestmentSide.sell, 1, 600000, date: now.add(const Duration(days: 2)))));
    expect(codeOf(await update(instrument('bbca'))), InvestmentFailures.insufficientQuantity);
  });

  test('DTO transaksi investasi bolak-balik', () {
    final t = trade('b1', InvestmentSide.sell, 3, 123);
    final model = TransactionModel.fromJson(TransactionModel.fromEntity(t).toJson());
    expect(model.toEntity(), t);
    expect(TransactionModel.schemaVersion, 4);
  });

  test('model instrumen dan valuasi bolak-balik', () {
    final i = Instrument(
      id: 'x',
      name: 'Emas',
      type: InstrumentType.gold,
      createdAt: now,
      code: 'XAU',
      opening: OpeningHolding(date: now, quantity: 5000, cost: 700000),
    );
    expect(InstrumentModel.fromJson(InstrumentModel.toJson(i)), i);
    final v = InstrumentValuation(instrumentId: 'x', date: now, unitPrice: 9, source: ValuationSource.sheet);
    expect(ValuationModel.fromJson(ValuationModel.toJson(v)), v);
  });
}
