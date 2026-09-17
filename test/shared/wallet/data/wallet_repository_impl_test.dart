import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/shared/wallet/data/wallet_repository_impl.dart';
import 'package:saldough/shared/wallet/domain/wallet.dart';

void main() {
  late InMemoryKeyValueStorage storage;
  late WalletRepositoryImpl repository;

  setUp(() {
    storage = InMemoryKeyValueStorage();
    repository = WalletRepositoryImpl(storage: storage);
  });

  group('WalletRepositoryImpl', () {
    test('daftar dompet kosong sebelum ada yang disimpan', () async {
      final result = await repository.listWallets();

      expect(result.getOrElse((_) => throw StateError('expected Right')), isEmpty);
    });

    test('menyimpan lalu membaca dompet mengembalikan nilai yang sama', () async {
      const wallet = Wallet(
        id: 'w1',
        name: 'BCA',
        iconKey: 'walletBank',
        initialBalance: 500000000,
        currentBalance: 500000000,
      );

      await repository.saveWallet(wallet);
      final result = await repository.listWallets();

      final wallets = result.getOrElse((_) => throw StateError('expected Right'));
      expect(wallets.single, wallet);
    });

    test('menyimpan ulang dompet ber-id sama menimpa, bukan menambah', () async {
      const wallet = Wallet(
        id: 'w1',
        name: 'BCA',
        iconKey: 'walletBank',
        initialBalance: 500000000,
        currentBalance: 500000000,
      );
      await repository.saveWallet(wallet);
      await repository.saveWallet(wallet.copyWith(currentBalance: 450000000));

      final result = await repository.listWallets();
      final wallets = result.getOrElse((_) => throw StateError('expected Right'));
      expect(wallets, hasLength(1));
      expect(wallets.single.currentBalance, 450000000);
    });

    test('menyunting nama dan ikon tidak mengubah saldo tercatat', () async {
      const wallet = Wallet(
        id: 'w1',
        name: 'BCA',
        iconKey: 'walletBank',
        initialBalance: 500000000,
        currentBalance: 450000000,
      );
      await repository.saveWallet(wallet);
      await repository.saveWallet(wallet.copyWith(name: 'BCA Utama', iconKey: 'walletCard'));

      final result = await repository.listWallets();
      final saved = result.getOrElse((_) => throw StateError('expected Right')).single;
      expect(saved.name, 'BCA Utama');
      expect(saved.iconKey, 'walletCard');
      expect(saved.currentBalance, 450000000);
    });

    test('menandai dompet tidak aktif tanpa menghapusnya', () async {
      const wallet = Wallet(
        id: 'w1',
        name: 'Dompet Lama',
        iconKey: 'walletCash',
        initialBalance: 0,
        currentBalance: 0,
      );
      await repository.saveWallet(wallet);
      await repository.saveWallet(wallet.copyWith(isActive: false));

      final result = await repository.listWallets();
      final wallets = result.getOrElse((_) => throw StateError('expected Right'));
      expect(wallets, hasLength(1));
      expect(wallets.single.isActive, isFalse);
    });

    test('saldo negatif tersimpan apa adanya, bukan kesalahan', () async {
      const wallet = Wallet(
        id: 'w1',
        name: 'Kartu Kredit',
        iconKey: 'walletCard',
        initialBalance: 0,
        currentBalance: -150000,
      );
      await repository.saveWallet(wallet);

      final result = await repository.listWallets();
      final saved = result.getOrElse((_) => throw StateError('expected Right')).single;
      expect(saved.currentBalance, -150000);
    });

    test('menghapus dompet ber-id tertentu', () async {
      const wallet = Wallet(
        id: 'w1',
        name: 'GoPay',
        iconKey: 'walletEwallet',
        initialBalance: 100000,
        currentBalance: 100000,
      );
      await repository.saveWallet(wallet);
      await repository.deleteWallet('w1');

      final result = await repository.listWallets();
      expect(result.getOrElse((_) => throw StateError('expected Right')), isEmpty);
    });

    test('menghapus id yang tidak ada tidak berefek', () async {
      const wallet = Wallet(
        id: 'w1',
        name: 'GoPay',
        iconKey: 'walletEwallet',
        initialBalance: 100000,
        currentBalance: 100000,
      );
      await repository.saveWallet(wallet);
      await repository.deleteWallet('tidak-ada');

      final result = await repository.listWallets();
      expect(result.getOrElse((_) => throw StateError('expected Right')), hasLength(1));
    });

    test('menyimpan beberapa dompet mempertahankan urutan penyimpanan', () async {
      const bca = Wallet(id: 'w1', name: 'BCA', iconKey: 'walletBank', initialBalance: 0, currentBalance: 0);
      const tunai = Wallet(id: 'w2', name: 'Tunai', iconKey: 'walletCash', initialBalance: 0, currentBalance: 0);
      await repository.saveWallet(bca);
      await repository.saveWallet(tunai);

      final result = await repository.listWallets();
      final wallets = result.getOrElse((_) => throw StateError('expected Right'));
      expect(wallets.map((w) => w.id), ['w1', 'w2']);
    });
  });
}
