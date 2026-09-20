import 'package:di/di.dart';
import 'package:saldough/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Lingkup dependensi fitur `wallet` (layar Dompet). Sama seperti
/// `TransactionScope`: `WalletRepository` dan `TransactionRepository` sudah
/// didaftarkan di `RootModule` sebagai repository bersama, jadi cukup dibawa
/// lewat [bridge]. `RecomputeWalletBalances` adalah use case murni, jadi
/// diinstansiasi langsung di [register].
final class WalletScope extends IsolatedScope {
  /// Membuat [WalletScope] dengan kontainer induk [parentContainer].
  WalletScope({required super.parentContainer});

  @override
  void bridge(GetIt c) {
    c
      ..registerSingleton<WalletRepository>(parent<WalletRepository>())
      ..registerSingleton<TransactionRepository>(parent<TransactionRepository>());
  }

  @override
  void register(GetIt c) {
    c.registerLazySingleton<WalletBloc>(
      () => WalletBloc(
        walletRepository: c<WalletRepository>(),
        transactionRepository: c<TransactionRepository>(),
        recomputeWalletBalances: RecomputeWalletBalances(
          walletRepository: c<WalletRepository>(),
          transactionRepository: c<TransactionRepository>(),
        ),
      ),
      dispose: (bloc) => bloc.close(),
    );
  }
}
