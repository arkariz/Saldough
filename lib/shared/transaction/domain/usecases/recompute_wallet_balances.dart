import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/shared/transaction/domain/transaction.dart';
import 'package:saldough/shared/transaction/domain/transaction_repository.dart';
import 'package:saldough/shared/wallet/domain/usecases/calculate_wallet_balance.dart';
import 'package:saldough/shared/wallet/domain/wallet.dart';
import 'package:saldough/shared/wallet/domain/wallet_repository.dart';

/// Menghitung ulang dan menulis `Wallet.currentBalance` dari nol, berdasarkan
/// `initialBalance` ditambah seluruh transaksi yang tercatat.
///
/// Ini penyeimbang keputusan menyimpan `currentBalance` sebagai cache
/// (ADR-012): tanpa use case ini beserta ujinya, keputusan itu tidak boleh
/// diambil sama sekali. Dipakai dua cara —
/// [call] mengulang seluruh dompet dari nol (perkakas audit/pemulihan, dan
/// bukti T-1.7), sementara [forWallets] hanya menyentuh dompet yang
/// disebutkan (dipakai `RecordTransaction` setelah satu transaksi
/// dicatat/disunting/dihapus, supaya tidak perlu menulis ulang dompet yang
/// tidak terdampak).
final class RecomputeWalletBalances {
  /// Membuat [RecomputeWalletBalances].
  const RecomputeWalletBalances({
    required this.walletRepository,
    required this.transactionRepository,
    this.calculateWalletBalance = const CalculateWalletBalance(),
  });

  /// Repository dompet yang saldonya ditulis ulang.
  final WalletRepository walletRepository;

  /// Repository transaksi, sumber kebenaran perhitungan.
  final TransactionRepository transactionRepository;

  /// Rumus yang dipakai untuk tiap dompet.
  final CalculateWalletBalance calculateWalletBalance;

  /// Menghitung ulang dan menulis `currentBalance` **seluruh** dompet.
  Future<Either<Failure, Unit>> call() async {
    final walletsResult = await walletRepository.listWallets();
    return switch (walletsResult) {
      Left(value: final failure) => left(failure),
      Right(value: final wallets) => _recomputeAndWrite(wallets),
    };
  }

  /// Menghitung ulang dan menulis `currentBalance` hanya dompet ber-`id`
  /// yang ada di [walletIds]. Tidak berefek pada dompet lain.
  Future<Either<Failure, Unit>> forWallets(Iterable<String> walletIds) async {
    final walletsResult = await walletRepository.listWallets();
    return switch (walletsResult) {
      Left(value: final failure) => left(failure),
      Right(value: final wallets) => _recomputeAndWrite(
          wallets.where((wallet) => walletIds.contains(wallet.id)).toList(),
        ),
    };
  }

  Future<Either<Failure, Unit>> _recomputeAndWrite(List<Wallet> wallets) async {
    if (wallets.isEmpty) return right(unit);
    final transactionsResult = await transactionRepository.listAllTransactions();
    return switch (transactionsResult) {
      Left(value: final failure) => left(failure),
      Right(value: final transactions) => _writeAll(wallets, transactions),
    };
  }

  Future<Either<Failure, Unit>> _writeAll(List<Wallet> wallets, List<Transaction> transactions) async {
    for (final wallet in wallets) {
      final balance = calculateWalletBalance(wallet, transactions);
      final saveResult = await walletRepository.saveWallet(wallet.copyWith(currentBalance: balance));
      if (saveResult case Left(value: final failure)) return left(failure);
    }
    return right(unit);
  }
}
