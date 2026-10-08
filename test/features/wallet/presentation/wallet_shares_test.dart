import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/wallet/presentation/wallet_shares.dart';
import 'package:saldough/shared/wallet/wallet.dart';

Wallet _w(String id, int sen) =>
    Wallet(id: id, name: id, iconKey: 'walletBank', initialBalance: 0, currentBalance: sen);

/// Bar sebaran saldo Dompet (T-14.9): persen bulat, jumlah tepat 100.
void main() {
  test('contoh prototipe: 14.810.000 / 12.000.000 / 376.000 / 336.000 → 54/44/1/1', () {
    final shares = walletShares([
      _w('bca', 1481000000),
      _w('tabungan', 1200000000),
      _w('tunai', 37600000),
      _w('gopay', 33600000),
    ]);
    expect(shares, {'bca': 54, 'tabungan': 44, 'tunai': 1, 'gopay': 1});
    expect(shares.values.reduce((a, b) => a + b), 100);
  });

  test('tiga sama besar: sisa terbesar membagi poin, jumlah tetap 100', () {
    final shares = walletShares([_w('a', 100), _w('b', 100), _w('c', 100)]);
    expect(shares.values.reduce((a, b) => a + b), 100);
    expect(shares.values.toSet(), {33, 34});
  });

  test('saldo nol atau negatif tidak ikut; tanpa saldo positif kosong', () {
    final shares = walletShares([_w('a', 500), _w('kartu', -300), _w('nol', 0)]);
    expect(shares, {'a': 100});
    expect(walletShares([_w('kartu', -300)]), isEmpty);
  });
}
