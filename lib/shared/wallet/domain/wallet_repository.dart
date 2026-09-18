import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/shared/wallet/domain/wallet.dart';

/// Kontrak akses data [Wallet]. Lihat ADR-0005 — selalu `Either<Failure, T>`,
/// tidak pernah `throw Failure`.
abstract interface class WalletRepository {
  /// Daftar seluruh dompet terdaftar, aktif maupun tidak.
  Future<Either<Failure, List<Wallet>>> listWallets();

  /// Menyimpan [wallet] — menambah kalau `id` baru, menimpa kalau sudah ada.
  Future<Either<Failure, Unit>> saveWallet(Wallet wallet);

  /// Menghapus dompet ber-`id` [id]. Tidak berefek kalau `id` tidak
  /// ditemukan.
  ///
  /// ⚠ Repository ini tidak memeriksa apakah dompet masih punya transaksi.
  /// Aturan "hanya boleh dihapus kalau belum punya transaksi" (FR-WAL-001)
  /// adalah tanggung jawab lapisan yang mengetahui `TransactionRepository`,
  /// bukan lapisan ini.
  Future<Either<Failure, Unit>> deleteWallet(String id);
}
