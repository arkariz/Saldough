import 'package:saldough/shared/wallet/wallet.dart';

/// Dompet aktif yang boleh mengisi draf. Gagal dibaca = tanpa dompet (draf
/// tetap tersusun, dompetnya kosong).
Future<List<Wallet>> loadActiveWallets(WalletRepository repository) async =>
    (await repository.listWallets()).getOrElse((_) => const []).where((w) => w.isActive).toList();
