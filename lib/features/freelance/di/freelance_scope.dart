import 'package:di/di.dart';
import 'package:saldough/features/freelance/domain/repositories/freelance_repository.dart';
import 'package:saldough/features/freelance/domain/usecases/receive_freelance_payment.dart';
import 'package:saldough/features/freelance/presentation/bloc/freelance_bloc.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Lingkup dependensi fitur `freelance` (Ikhtisar Freelance, T-5.8).
///
/// Dibuat saat Ikhtisar Freelance dibuka dan dibuang saat ditutup, karena
/// Freelance bukan tujuan navigasi bawah (FR-FRL-005). Ketiga repository
/// didaftarkan di `RootModule` dan dibawa lewat [bridge].
/// `RecordTransaction` dirakit di sini seperti di `RecordScope`: mencatat
/// pembayaran diterima menulis transaksi pemasukan dan menghitung ulang
/// saldo dompet tujuannya.
final class FreelanceScope extends IsolatedScope {
  /// Membuat [FreelanceScope] dengan kontainer induk [parentContainer].
  FreelanceScope({required super.parentContainer});

  @override
  void bridge(GetIt c) {
    c
      ..registerSingleton<FreelanceRepository>(parent<FreelanceRepository>())
      ..registerSingleton<WalletRepository>(parent<WalletRepository>())
      ..registerSingleton<TransactionRepository>(parent<TransactionRepository>());
  }

  @override
  void register(GetIt c) {
    c.registerLazySingleton<FreelanceBloc>(
      () => FreelanceBloc(
        freelanceRepository: c<FreelanceRepository>(),
        walletRepository: c<WalletRepository>(),
        receivePayment: ReceiveFreelancePayment(
          freelanceRepository: c<FreelanceRepository>(),
          recordTransaction: RecordTransaction(
            transactionRepository: c<TransactionRepository>(),
            recomputeWalletBalances: RecomputeWalletBalances(
              walletRepository: c<WalletRepository>(),
              transactionRepository: c<TransactionRepository>(),
            ),
          ),
        ),
      ),
      dispose: (bloc) => bloc.close(),
    );
  }
}
