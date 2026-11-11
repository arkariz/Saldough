import 'package:di/di.dart' show GetIt;
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/app/dev_seed/seed_pack.dart';
import 'package:saldough/app/dev_seed/spending_seed_pack.dart';
import 'package:saldough/app/dev_seed/wallet_seed_pack.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

void main() {
  // 11 Nov 2026: Sep dan Okt penuh, Nov sampai tanggal 11.
  final today = DateTime(2026, 11, 11);
  late GetIt c;
  late TransactionRepository txRepo;

  setUp(() {
    final storage = InMemoryKeyValueStorage();
    txRepo = TransactionRepositoryImpl(storage: storage);
    c = GetIt.asNewInstance()
      ..registerSingleton<WalletRepository>(WalletRepositoryImpl(storage: storage))
      ..registerSingleton<TransactionRepository>(txRepo)
      ..registerSingleton<CategoryRepository>(CategoryRepositoryImpl(storage: storage))
      ..registerSingleton<RecurringRuleRepository>(RecurringRuleRepositoryImpl(storage: storage))
      ..registerSingleton<LedgerChanges>(LedgerChanges())
      ..registerSingleton<RecurringChanges>(RecurringChanges());
  });

  Future<List<Transaction>> month(int m) async =>
      (await txRepo.listTransactionsInMonth(DateTime(2026, m))).getOrElse((_) => []);

  int spend(List<Transaction> all) =>
      all.whereType<ExpenseTransaction>().fold(0, (a, t) => a + t.amount) ~/ 100;

  test('pengeluaran Rp5-7 juta per bulan; bulan berjalan sampai hari ini', () async {
    await const SpendingSeedPack().applyAt(c, today);
    expect(spend(await month(9)), inInclusiveRange(5000000, 7000000));
    expect(spend(await month(10)), inInclusiveRange(5000000, 7000000));
    final nov = await month(11);
    expect(spend(nov), inInclusiveRange(5000000, 7000000));
    expect(nov.every((t) => !t.date.isAfter(today)), isTrue);
  });

  test('nabung Rp7 juta per bulan = empat transfer tertaut rutin, bukan pengeluaran', () async {
    await const SpendingSeedPack().applyAt(c, today);
    for (final m in [9, 10, 11]) {
      final transfers = (await month(m)).whereType<TransferTransaction>().toList();
      expect(transfers.length, 4);
      expect(transfers.fold(0, (a, t) => a + t.amount) ~/ 100, 7000000);
      expect(transfers.every((t) => t.fromWalletId == SeedIds.walletUtama && t.recurrence != null), isTrue);
      expect(transfers.map((t) => t.toWalletId).toSet(), {
        SeedIds.walletTabunganRumah,
        SeedIds.walletAnak,
        SeedIds.walletKeJepang,
        SeedIds.walletSaham,
      });
    }
    final rules = (await c<RecurringRuleRepository>().listRules()).getOrElse((_) => []);
    expect(rules.length, 4);
    expect(rules.fold(0, (a, r) => a + r.amount) ~/ 100, 7000000);
    expect(rules.every((r) => r.kind == RecurringKind.transfer && r.schedule.frequency == RecurringFrequency.monthly), isTrue);
  });

  test('kategori yang diminta ada dan dipakai pengeluaran', () async {
    await const SpendingSeedPack().applyAt(c, today);
    final names = (await c<CategoryRepository>().listCategories()).getOrElse((_) => []).map((x) => x.name).toSet();
    expect(names, containsAll(['Tagihan Kos', 'Tagihan Listrik', 'Belanja Bulanan', 'Jajan']));
    final used = (await month(10)).whereType<ExpenseTransaction>().map((t) => t.categoryId).toSet();
    expect(used, containsAll([
      SpendingSeedIds.catKos,
      SpendingSeedIds.catListrik,
      SpendingSeedIds.catBelanja,
      SpendingSeedIds.catJajan,
    ]));
    // Selingan: lebih dari empat kategori dalam sebulan.
    expect(used.length, greaterThan(5));
  });

  test('saldo dompet ikut bergerak sesuai transaksi', () async {
    await const SpendingSeedPack().applyAt(c, today);
    final wallets = {for (final w in (await c<WalletRepository>().listWallets()).getOrElse((_) => [])) w.id: w};
    final rumah = WalletSeedPack.wallets.firstWhere((w) => w.id == SeedIds.walletTabunganRumah);
    expect(wallets[SeedIds.walletTabunganRumah]!.currentBalance, rumah.initialBalance + 3 * 300000000);
    final all = (await txRepo.listAllTransactions()).getOrElse((_) => []);
    final utama = WalletSeedPack.wallets.firstWhere((w) => w.id == SeedIds.walletUtama);
    final income = all.whereType<IncomeTransaction>().fold(0, (a, t) => a + t.amount);
    final out = all.whereType<ExpenseTransaction>().fold(0, (a, t) => a + t.amount) +
        all.whereType<TransferTransaction>().fold(0, (a, t) => a + t.amount);
    expect(wallets[SeedIds.walletUtama]!.currentBalance, utama.initialBalance + income - out);
  });

  test('diterapkan dua kali tidak menggandakan dan tidak menimpa suntingan', () async {
    await const SpendingSeedPack().applyAt(c, today);
    final before = (await txRepo.listAllTransactions()).getOrElse((_) => []).length;
    final edited = (await month(10)).whereType<ExpenseTransaction>().firstWhere((t) => t.note == 'Bayar kos bulanan');
    await txRepo.saveTransaction(edited.copyWith(note: 'Kos (disunting)'));
    final second = await const SpendingSeedPack().applyAt(c, today);
    expect(second.added, 0);
    expect((await txRepo.listAllTransactions()).getOrElse((_) => []).length, before);
    expect((await month(10)).any((t) => t.note == 'Kos (disunting)'), isTrue);
  });
}
