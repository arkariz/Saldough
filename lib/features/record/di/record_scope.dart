import 'package:di/di.dart';
import 'package:saldough/features/record/presentation/bloc/record_bloc.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Lingkup dependensi fitur `record` (lembar CATAT). `WalletRepository` dan
/// `TransactionRepository` sudah didaftarkan di `RootModule` sebagai
/// repository bersama (ADR-0009 — keduanya dipakai fitur lain juga di fase
/// selanjutnya), jadi cukup dibawa lewat [bridge]. `RecomputeWalletBalances`
/// dan `RecordTransaction` adalah use case murni (bukan repository), jadi
/// diinstansiasi langsung di [register], bukan diambil dari kontainer induk.
final class RecordScope extends IsolatedScope {
  /// Membuat [RecordScope] dengan kontainer induk [parentContainer].
  RecordScope({required super.parentContainer});

  @override
  void bridge(GetIt c) {
    c
      ..registerSingleton<WalletRepository>(parent<WalletRepository>())
      ..registerSingleton<TransactionRepository>(parent<TransactionRepository>());
  }

  @override
  void register(GetIt c) {
    c.registerLazySingleton<RecordBloc>(
      () => RecordBloc(
        walletRepository: c<WalletRepository>(),
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
