import 'package:di/di.dart';
import 'package:saldough/features/transaction/presentation/bloc/transaction_bloc.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Lingkup dependensi fitur `transaction` (layar riwayat). Sama seperti
/// `RecordScope`: `WalletRepository` dan `TransactionRepository` sudah
/// didaftarkan di `RootModule` sebagai repository bersama, jadi cukup dibawa
/// lewat [bridge], bukan didaftarkan ulang. `RecordTransaction` (sunting dan
/// hapus, T-2.6) adalah use case murni, jadi diinstansiasi langsung di
/// [register] seperti di `RecordScope`.
final class TransactionScope extends IsolatedScope {
  /// Membuat [TransactionScope] dengan kontainer induk [parentContainer].
  TransactionScope({required super.parentContainer});

  @override
  void bridge(GetIt c) {
    c
      ..registerSingleton<WalletRepository>(parent<WalletRepository>())
      ..registerSingleton<TransactionRepository>(parent<TransactionRepository>());
  }

  @override
  void register(GetIt c) {
    c.registerLazySingleton<TransactionBloc>(
      () => TransactionBloc(
        walletRepository: c<WalletRepository>(),
        transactionRepository: c<TransactionRepository>(),
        recordTransaction: RecordTransaction(
          transactionRepository: c<TransactionRepository>(),
          recomputeWalletBalances: RecomputeWalletBalances(
            walletRepository: c<WalletRepository>(),
            transactionRepository: c<TransactionRepository>(),
          ),
        ),
      ),
      dispose: (bloc) => bloc.close(),
    );
  }
}
