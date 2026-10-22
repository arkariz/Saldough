import 'package:saldough/shared/wallet/wallet.dart';

/// Bagian saldo satu dompet terhadap total saldo positif (BalanceSpread).
final class WalletShare {
  /// Membuat [WalletShare].
  const WalletShare({required this.percent, required this.belowOne});

  /// Persen bulat, dibulatkan setengah ke atas.
  final int percent;

  /// Saldo di atas 0 tetapi di bawah 0,5% dari total: tampil "<1%".
  final bool belowOne;

  /// "54%" atau "<1%".
  String get text => belowOne ? '<1%' : '$percent%';
}

/// Bagian saldo tiap dompet terhadap total saldo positif (kartu Sebaran
/// saldo, BalanceSpread): persen bulat setengah ke atas, di bawah 0,5% ditulis
/// "<1%" -- sama dengan Analisis, jadi jumlahnya boleh tidak tepat 100.
/// Dompet bersaldo nol atau negatif tidak ikut dan tidak muncul di hasil.
/// Kosong bila tidak ada saldo positif sama sekali.
///
/// Aritmetika bilangan bulat murni pada sen.
Map<String, WalletShare> walletShares(List<Wallet> wallets) {
  final positive = [
    for (final w in wallets)
      if (w.currentBalance > 0) w,
  ];
  final total = positive.fold<int>(0, (sum, w) => sum + w.currentBalance);
  if (total == 0) return const {};
  return {
    for (final wallet in positive)
      wallet.id: WalletShare(
        // (saldo × 200 + total) ~/ (2 × total) = bulat setengah ke atas.
        percent: (wallet.currentBalance * 200 + total) ~/ (2 * total),
        belowOne: wallet.currentBalance * 200 < total,
      ),
  };
}
