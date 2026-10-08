import 'package:saldough/shared/wallet/wallet.dart';

/// Persen bagian saldo tiap dompet terhadap total saldo positif (bar sebaran
/// Dompet, ADR-034 §4), dibulatkan dengan sisa terbesar supaya jumlahnya
/// tepat 100. Dompet bersaldo nol atau negatif tidak ikut dan tidak muncul
/// di hasil. Kosong bila tidak ada saldo positif sama sekali.
///
/// Aritmetika bilangan bulat murni: persen kali 10.000 dihitung lewat
/// `~/` pada sen, sisa pembagiannya yang menentukan siapa dapat satu poin
/// tambahan.
Map<String, int> walletShares(List<Wallet> wallets) {
  final positive = [
    for (final w in wallets)
      if (w.currentBalance > 0) w,
  ];
  final total = positive.fold<int>(0, (sum, w) => sum + w.currentBalance);
  if (total == 0) return const {};
  final floors = <String, int>{};
  final remainders = <(String, int)>[];
  for (final wallet in positive) {
    final scaled = wallet.currentBalance * 100;
    floors[wallet.id] = scaled ~/ total;
    remainders.add((wallet.id, scaled % total));
  }
  var missing = 100 - floors.values.fold<int>(0, (a, b) => a + b);
  remainders.sort((a, b) => b.$2.compareTo(a.$2));
  for (final (id, _) in remainders) {
    if (missing == 0) break;
    floors[id] = floors[id]! + 1;
    missing--;
  }
  return floors;
}
