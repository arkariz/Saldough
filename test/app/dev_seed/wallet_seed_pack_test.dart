import 'package:di/di.dart' show GetIt;
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/app/dev_seed/seed_pack.dart';
import 'package:saldough/app/dev_seed/wallet_seed_pack.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

void main() {
  late GetIt c;
  late WalletRepository repo;

  setUp(() {
    repo = WalletRepositoryImpl(storage: InMemoryKeyValueStorage());
    c = GetIt.asNewInstance()
      ..registerSingleton<WalletRepository>(repo)
      ..registerSingleton<LedgerChanges>(LedgerChanges());
  });

  Future<List<Wallet>> all() async => (await repo.listWallets()).getOrElse((_) => []);

  test('total ±Rp300 juta, tujuh dompet, angka tidak bulat, jatah sesuai permintaan', () {
    final by = {for (final w in WalletSeedPack.wallets) w.id: w.currentBalance ~/ 100};
    expect(by.values.reduce((a, b) => a + b), inInclusiveRange(295000000, 305000000));
    expect(by.values.every((v) => v % 1000 != 0), isTrue);
    expect(by.length, 7);
    expect(by[SeedIds.walletMingguan], inInclusiveRange(200000, 230000));
    expect(by[SeedIds.walletBulanan], inInclusiveRange(2000000, 2300000));
    expect(by[SeedIds.walletKeJepang], inInclusiveRange(20000000, 20999999));
  });

  test('diterapkan dua kali tidak menggandakan', () async {
    const pack = WalletSeedPack();
    expect((await pack.apply(c)).added, 7);
    final second = await pack.apply(c);
    expect((added: second.added, skipped: second.skipped), (added: 0, skipped: 7));
    expect((await all()).length, 7);
  });

  test('dompet yang sudah ada (saldo sudah bergeser) tidak ditimpa, data lain utuh', () async {
    const mine = Wallet(id: 'punyaku', name: 'Punyaku', iconKey: 'walletBank', initialBalance: 5, currentBalance: 5);
    await repo.saveWallet(mine);
    await repo.saveWallet(WalletSeedPack.wallets.first.copyWith(currentBalance: 123));
    await const WalletSeedPack().apply(c);
    final wallets = await all();
    expect(wallets.length, 8);
    expect(wallets.firstWhere((w) => w.id == SeedIds.walletUtama).currentBalance, 123);
    expect(wallets.any((w) => w.id == 'punyaku'), isTrue);
  });
}
