import 'package:saldough/shared/wallet/wallet.dart';

/// Dompet aktif yang boleh mengisi draf. Gagal dibaca = tanpa dompet (draf
/// tetap tersusun, dompetnya kosong). [exclude] = dompet milik tujuan
/// tabungan: hanya untuk transfer, jadi tidak pernah ditebak untuk pemasukan
/// atau pengeluaran dari notifikasi (ADR-048 §8.2a).
Future<List<Wallet>> loadActiveWallets(WalletRepository repository, {Set<String> exclude = const {}}) async =>
    (await repository.listWallets())
        .getOrElse((_) => const [])
        .where((w) => w.isActive && !exclude.contains(w.id))
        .toList();
