import 'package:bloc_test/bloc_test.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saldough/features/record/presentation/bloc/record_bloc.dart';
import 'package:saldough/features/record/presentation/bloc/record_state.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

import '../../../../helpers/mocks.dart';

const _forcedFailure = SystemFailure(
  code: FailureCode('TEST_FORCED_FAILURE'),
  message: 'dipaksa gagal untuk uji',
);

void main() {
  late MockWalletRepository walletRepository;
  late MockTransactionRepository transactionRepository;

  setUpAll(() {
    registerFallbackValue(fallbackWallet);
    registerFallbackValue(fallbackTransaction);
  });

  setUp(() {
    walletRepository = MockWalletRepository();
    transactionRepository = MockTransactionRepository();
    when(() => walletRepository.listWallets()).thenAnswer(
      (_) async => const Right([
        Wallet(
          id: 'bca',
          name: 'BCA',
          iconKey: 'walletBank',
          initialBalance: 500000000,
          currentBalance: 500000000,
        ),
        Wallet(
          id: 'gopay',
          name: 'GoPay',
          iconKey: 'walletEwallet',
          initialBalance: 0,
          currentBalance: 0,
        ),
        Wallet(
          id: 'lama',
          name: 'Dompet Lama',
          iconKey: 'walletCash',
          initialBalance: 0,
          currentBalance: 0,
          isActive: false,
        ),
      ]),
    );
    when(
      () => transactionRepository.saveTransaction(
        any(),
        previousDate: any(named: 'previousDate'),
      ),
    ).thenAnswer(
      (_) async => const Right(unit),
    );
    when(
      () => walletRepository.saveWallet(any()),
    ).thenAnswer((_) async => const Right(unit));
  });

  RecordBloc buildBloc() => RecordBloc(
    walletRepository: walletRepository,
    recordTransaction: RecordTransaction(
      transactionRepository: transactionRepository,
      recomputeWalletBalances: RecomputeWalletBalances(
        walletRepository: walletRepository,
        transactionRepository: transactionRepository,
      ),
    ),
  );

  group('RecordBloc', () {
    blocTest<RecordBloc, RecordState>(
      'RecordWalletsLoaded memuat dompet AKTIF saja',
      build: buildBloc,
      act: (bloc) => bloc.add(const RecordWalletsLoaded()),
      skip: 1,
      verify: (bloc) {
        expect(
          bloc.state.wallets.map((w) => w.id),
          containsAll(['bca', 'gopay']),
        );
        expect(bloc.state.wallets.map((w) => w.id), isNot(contains('lama')));
      },
    );

    blocTest<RecordBloc, RecordState>(
      'kegagalan pemuatan dompet menyetel loadFailed true',
      setUp: () => when(
        () => walletRepository.listWallets(),
      ).thenAnswer((_) async => const Left(_forcedFailure)),
      build: buildBloc,
      act: (bloc) => bloc.add(const RecordWalletsLoaded()),
      skip: 1,
      expect: () => [
        isA<RecordState>()
            .having((s) => s.loadFailed, 'loadFailed', true)
            .having((s) => s.wallets, 'wallets', isEmpty),
      ],
    );

    blocTest<RecordBloc, RecordState>(
      'IncomeRecorded mencatat transaksi dan menambah saldo dompet tujuan',
      setUp: () {
        when(() => transactionRepository.listAllTransactions()).thenAnswer(
          (_) async => Right([
            IncomeTransaction(
              id: 'i1',
              date: DateTime(2026, 9),
              amount: 261543800,
              note: 'gaji',
              walletId: 'bca',
            ),
          ]),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        IncomeRecorded(
          walletId: 'bca',
          amount: 261543800,
          date: DateTime(2026, 9),
          note: 'gaji',
        ),
      ),
      verify: (bloc) {
        final saved =
            verify(
                  () => walletRepository.saveWallet(captureAny()),
                ).captured.single
                as Wallet;
        expect(
          saved.currentBalance,
          761543800,
          reason: '500.000.000 awal + 261.543.800',
        );
        expect(bloc.state.effect, isA<ShowSnackBarEffect>());
      },
    );

    blocTest<RecordBloc, RecordState>(
      'ExpenseRecorded mencatat transaksi dan mengurangi saldo dompet asal',
      setUp: () {
        when(() => transactionRepository.listAllTransactions()).thenAnswer(
          (_) async => Right([
            ExpenseTransaction(
              id: 'e1',
              date: DateTime(2026, 9),
              amount: 75000,
              note: 'kopi',
              walletId: 'bca',
              categoryKey: 'makan',
            ),
          ]),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        ExpenseRecorded(
          walletId: 'bca',
          amount: 75000,
          date: DateTime(2026, 9),
          note: 'kopi',
          categoryKey: 'makan',
        ),
      ),
      verify: (bloc) {
        final saved =
            verify(
                  () => walletRepository.saveWallet(captureAny()),
                ).captured.single
                as Wallet;
        expect(saved.currentBalance, 499925000);
      },
    );

    blocTest<RecordBloc, RecordState>(
      'TransferRecorded mengurangi dompet asal dan menambah dompet tujuan sekaligus',
      setUp: () {
        when(() => transactionRepository.listAllTransactions()).thenAnswer(
          (_) async => Right([
            TransferTransaction(
              id: 't1',
              date: DateTime(2026, 9),
              amount: 100000000,
              note: '',
              fromWalletId: 'bca',
              toWalletId: 'gopay',
            ),
          ]),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        TransferRecorded(
          fromWalletId: 'bca',
          toWalletId: 'gopay',
          amount: 100000000,
          date: DateTime(2026, 9),
          note: '',
        ),
      ),
      verify: (bloc) {
        final saved = verify(
          () => walletRepository.saveWallet(captureAny()),
        ).captured.cast<Wallet>();
        expect(
          saved.firstWhere((w) => w.id == 'bca').currentBalance,
          400000000,
        );
        expect(
          saved.firstWhere((w) => w.id == 'gopay').currentBalance,
          100000000,
        );
      },
    );

    blocTest<RecordBloc, RecordState>(
      'gagal menulis memancarkan efek galat, bukan galat berhasil',
      setUp: () {
        when(
          () => transactionRepository.saveTransaction(
            any(),
            previousDate: any(named: 'previousDate'),
          ),
        ).thenAnswer((_) async => const Left(_forcedFailure));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        IncomeRecorded(
          walletId: 'bca',
          amount: 1000,
          date: DateTime(2026, 9),
          note: '',
        ),
      ),
      verify: (bloc) {
        expect(
          (bloc.state.effect! as ShowSnackBarEffect).severity,
          FeedbackSeverity.error,
        );
        verifyNever(() => walletRepository.saveWallet(any()));
      },
    );
  });
}
