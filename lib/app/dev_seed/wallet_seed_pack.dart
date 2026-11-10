import 'package:di/di.dart';
import 'package:saldough/app/dev_seed/seed_pack.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Tujuh dompet dengan total saldo ±Rp300 juta (Rp299.626.920). Satuan sen, jadi tiap angka
/// dikali 100 lewat [_rp].
///
/// Pembagian: jatah mingguan ±Rp200 ribu, bulanan ±Rp2 juta, Ke Jepang
/// ±Rp20 juta, sisanya disebar ke Utama dan tabungan (rumah, anak, saham).
/// Angkanya sengaja tidak bulat supaya tampak seperti hasil transaksi nyata.
final class WalletSeedPack implements SeedPack {
  /// Membuat [WalletSeedPack].
  const WalletSeedPack();

  static int _rp(int rupiah) => rupiah * 100;

  /// Dompet seed, urutan = urutan tampil.
  static final List<Wallet> wallets = [
    _wallet(SeedIds.walletUtama, 'Utama', 'walletBank', 17842615),
    _wallet(SeedIds.walletMingguan, 'Mingguan', 'walletCash', 213470),
    _wallet(SeedIds.walletBulanan, 'Bulanan', 'walletCash', 2136480),
    _wallet(SeedIds.walletTabunganRumah, 'Tabungan Rumah', 'walletSavings', 148763215),
    _wallet(SeedIds.walletKeJepang, 'Ke Jepang', 'walletSavings', 20847330),
    _wallet(SeedIds.walletAnak, 'Anak', 'walletSavings', 36294870),
    _wallet(SeedIds.walletSaham, 'Saham', 'walletEwallet', 73528940),
  ];

  static Wallet _wallet(String id, String name, String iconKey, int rupiah) => Wallet(
        id: id,
        name: name,
        iconKey: iconKey,
        initialBalance: _rp(rupiah),
        currentBalance: _rp(rupiah),
      );

  @override
  String get id => 'wallets';

  @override
  String get label => 'Dompet (7, total ±Rp300 jt)';

  @override
  String get description => 'Utama, Mingguan, Bulanan, Tabungan Rumah, Ke Jepang, Anak, Saham. '
      'Dompet yang sudah ada tidak ditimpa.';

  @override
  Future<SeedResult> apply(GetIt container) async {
    final repository = container<WalletRepository>();
    final existing = (await repository.listWallets()).fold((f) => throw StateError('$f'), (all) => {for (final w in all) w.id});
    var added = 0;
    for (final wallet in wallets) {
      if (existing.contains(wallet.id)) continue;
      (await repository.saveWallet(wallet)).fold((f) => throw StateError('$f'), (_) {});
      added++;
    }
    if (added > 0) container<LedgerChanges>().notifyChanged(source: this);
    return SeedResult(added: added, skipped: wallets.length - added);
  }
}
