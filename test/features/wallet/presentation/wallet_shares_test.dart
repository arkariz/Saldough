import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/wallet/presentation/wallet_shares.dart';
import 'package:saldough/features/wallet/presentation/widgets/wallet_card.dart';
import 'package:saldough/shared/wallet/wallet.dart';

Wallet _w(String id, int sen, {String icon = 'walletBank'}) =>
    Wallet(id: id, name: id, iconKey: icon, initialBalance: 0, currentBalance: sen);

/// Kartu Sebaran saldo Dompet (B-66, BalanceSpread): persen bulat setengah ke
/// atas, di bawah 0,5% "<1%", sama dengan Analisis.
void main() {
  test('contoh prototipe: 14.810.000 / 12.000.000 / 376.000 / 336.000 → 54/44/1/1', () {
    final shares = walletShares([
      _w('bca', 1481000000),
      _w('tabungan', 1200000000),
      _w('tunai', 37600000),
      _w('gopay', 33600000),
    ]);
    expect({for (final e in shares.entries) e.key: e.value.text}, {
      'bca': '54%',
      'tabungan': '44%',
      'tunai': '1%',
      'gopay': '1%',
    });
  });

  test('pembulatan setengah ke atas; jumlahnya boleh tidak tepat 100', () {
    final shares = walletShares([_w('a', 100), _w('b', 100), _w('c', 100)]);
    expect(shares.values.map((s) => s.percent).toSet(), {33});
    expect(walletShares([_w('a', 1), _w('b', 1)])['a']!.percent, 50);
    expect(walletShares([_w('a', 125), _w('b', 875)])['a']!.percent, 13, reason: '12,5% → 13');
  });

  test('di atas 0 tetapi di bawah 0,5% ditulis "<1%"; tepat 0,5% menjadi 1%', () {
    final shares = walletShares([_w('besar', 99600), _w('kecil', 400)]);
    expect(shares['kecil']!.belowOne, isTrue);
    expect(shares['kecil']!.text, '<1%');
    final half = walletShares([_w('besar', 99500), _w('kecil', 500)]);
    expect(half['kecil']!.text, '1%');
  });

  test('saldo nol atau negatif tidak ikut; tanpa saldo positif kosong', () {
    final shares = walletShares([_w('a', 500), _w('kartu', -300), _w('nol', 0)]);
    expect(shares.keys, ['a']);
    expect(shares['a']!.text, '100%');
    expect(walletShares([_w('kartu', -300)]), isEmpty);
  });

  group('walletColors', () {
    const colors = AppColors.light;

    test('dompet pertama tiap jenis memakai warna jenisnya', () {
      final map = walletColors(colors, [
        _w('bca', 1),
        _w('tabungan', 1, icon: 'walletSavings'),
        _w('tunai', 1, icon: 'walletCash'),
        _w('gopay', 1, icon: 'walletEwallet'),
      ]);
      expect(map, {'bca': colors.catBlue, 'tabungan': colors.catAmber, 'tunai': colors.catGreen, 'gopay': colors.catTeal});
    });

    test('dua bank mendapat warna berbeda', () {
      final map = walletColors(colors, [_w('bca', 1), _w('mandiri', 1)]);
      expect(map['bca'], colors.catBlue);
      expect(map['mandiri'], isNot(colors.catBlue));
    });
  });
}
