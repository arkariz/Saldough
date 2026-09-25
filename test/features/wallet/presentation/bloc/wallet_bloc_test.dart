import 'package:bloc_test/bloc_test.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:saldough/features/wallet/presentation/bloc/wallet_state.dart';
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
  });

  WalletBloc buildBloc() => WalletBloc(
    walletRepository: walletRepository,
    transactionRepository: transactionRepository,
    recomputeWalletBalances: RecomputeWalletBalances(
      walletRepository: walletRepository,
      transactionRepository: transactionRepository,
    ),
  );

  Wallet wallet(
    String id, {
    String name = 'BCA',
    int initial = 0,
    int? current,
    bool isActive = true,
    String iconKey = 'walletBank',
  }) => Wallet(
    id: id,
    name: name,
    iconKey: iconKey,
    initialBalance: initial,
    currentBalance: current ?? initial,
    isActive: isActive,
  );

  String? messageOf(WalletState state) => (state.effect as ShowSnackBarEffect?)?.message;

  group('WalletBloc -- memuat', () {
    blocTest<WalletBloc, WalletState>(
      'WalletStarted memuat dompet aktif maupun tidak',
      setUp: () {
        when(
          () => walletRepository.listWallets(),
        ).thenAnswer(
          (_) async => Right([wallet('a'), wallet('b', name: 'Lama', isActive: false)]),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const WalletStarted()),
      expect: () => [
        isA<WalletState>().having((s) => s.isLoading, 'isLoading', true),
        isA<WalletState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.wallets.map((w) => w.id), 'wallets', ['a', 'b'])
            .having((s) => s.activeWallets.map((w) => w.id), 'activeWallets', [
              'a',
            ])
            .having(
              (s) => s.inactiveWallets.map((w) => w.id),
              'inactiveWallets',
              ['b'],
            )
            .having((s) => s.loadFailed, 'loadFailed', false),
      ],
    );

    blocTest<WalletBloc, WalletState>(
      'kegagalan pembacaan menyalakan loadFailed dan memancarkan galat, bukan daftar kosong',
      setUp: () {
        when(
          () => walletRepository.listWallets(),
        ).thenAnswer((_) async => const Left(_forcedFailure));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const WalletStarted()),
      expect: () => [
        isA<WalletState>().having((s) => s.isLoading, 'isLoading', true),
        isA<WalletState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.loadFailed, 'loadFailed', true)
            .having((s) => s.effect, 'effect', isA<ShowSnackBarEffect>()),
      ],
    );

    blocTest<WalletBloc, WalletState>(
      'total saldo hanya menjumlahkan dompet AKTIF dan boleh negatif (FR-WAL-003)',
      setUp: () {
        when(() => walletRepository.listWallets()).thenAnswer(
          (_) async => Right([
            wallet('a', current: 100000000),
            wallet('b', name: 'GoPay', current: -30000000),
            wallet('c', name: 'Nonaktif', current: 999999999, isActive: false),
          ]),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const WalletStarted()),
      skip: 1,
      expect: () => [
        isA<WalletState>().having(
          (s) => s.totalBalance,
          'totalBalance',
          70000000,
        ),
      ],
    );

    blocTest<WalletBloc, WalletState>(
      'WalletRefreshed memuat ulang TANPA pernah menyalakan isLoading',
      setUp: () {
        when(
          () => walletRepository.listWallets(),
        ).thenAnswer((_) async => Right([wallet('baru')]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const WalletRefreshed()),
      verify: (bloc) {
        expect(bloc.state.isLoading, isFalse);
        expect(bloc.state.wallets.map((w) => w.id), ['baru']);
      },
      expect: () => [
        isA<WalletState>().having((s) => s.isLoading, 'isLoading', false),
      ],
    );
  });

  group('WalletBloc -- tambah (FR-WAL-001/002)', () {
    blocTest<WalletBloc, WalletState>(
      'menyimpan dompet dengan saldo tercatat = saldo awal dan nama dirapikan',
      setUp: () {
        when(
          () => walletRepository.saveWallet(any()),
        ).thenAnswer((_) async => const Right(unit));
        when(
          () => walletRepository.listWallets(),
        ).thenAnswer(
          (_) async => Right([
            wallet(
              'new',
              name: 'GoPay',
              initial: 25000000,
              iconKey: 'walletEwallet',
            ),
          ]),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const WalletAdded(
          name: '  GoPay  ',
          iconKey: 'walletEwallet',
          initialBalance: 25000000,
        ),
      ),
      verify: (bloc) {
        final saved =
            verify(
                  () => walletRepository.saveWallet(captureAny()),
                ).captured.single
                as Wallet;
        expect(saved.name, 'GoPay');
        expect(saved.iconKey, 'walletEwallet');
        expect(saved.initialBalance, 25000000);
        expect(saved.currentBalance, 25000000);
        expect(saved.isActive, isTrue);
        expect(messageOf(bloc.state), t.wallet.savedMessage);
        verifyNever(() => transactionRepository.saveTransaction(any()));
      },
    );

    blocTest<WalletBloc, WalletState>(
      'saldo awal nol diterima',
      setUp: () {
        when(
          () => walletRepository.saveWallet(any()),
        ).thenAnswer((_) async => const Right(unit));
        when(
          () => walletRepository.listWallets(),
        ).thenAnswer((_) async => Right([wallet('kosong', name: 'Kosong')]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const WalletAdded(
          name: 'Kosong',
          iconKey: 'walletCash',
          initialBalance: 0,
        ),
      ),
      verify: (bloc) => expect(bloc.state.wallets.single.currentBalance, 0),
    );
  });

  group('WalletBloc -- sunting (FR-WAL-001/002)', () {
    blocTest<WalletBloc, WalletState>(
      'menyunting nama dan ikon TIDAK mengubah saldo tercatat maupun saldo awal',
      setUp: () {
        when(
          () => walletRepository.saveWallet(any()),
        ).thenAnswer((_) async => const Right(unit));
        when(() => walletRepository.listWallets()).thenAnswer(
          (_) async => Right([
            wallet(
              'a',
              name: 'BCA Utama',
              iconKey: 'walletSavings',
              current: 10000000,
            ),
          ]),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        WalletEdited(
          original: wallet('a', current: 10000000),
          name: 'BCA Utama',
          iconKey: 'walletSavings',
          isActive: true,
        ),
      ),
      verify: (bloc) {
        final edited = bloc.state.wallets.single;
        expect(edited.name, 'BCA Utama');
        expect(edited.iconKey, 'walletSavings');
        expect(edited.initialBalance, 0);
        expect(edited.currentBalance, 10000000);
        expect(messageOf(bloc.state), t.wallet.updatedMessage);
        verify(() => walletRepository.saveWallet(any())).called(1);
        verifyNever(() => transactionRepository.listAllTransactions());
      },
    );

    blocTest<WalletBloc, WalletState>(
      'mengganti saldo awal menghitung ulang saldo tercatat dari seluruh transaksi',
      setUp: () {
        // Saldo awal baru (50.000.000) + pemasukan yang sudah ada (10.000.000) = 60.000.000.
        when(
          () => walletRepository.saveWallet(any()),
        ).thenAnswer((_) async => const Right(unit));
        when(
          () => walletRepository.listWallets(),
        ).thenAnswer(
          (_) async => Right([wallet('a', initial: 50000000, current: 50000000)]),
        );
        when(() => transactionRepository.listAllTransactions()).thenAnswer(
          (_) async => Right([
            IncomeTransaction(
              id: 'i1',
              date: DateTime(2026, 9, 5),
              amount: 10000000,
              note: '',
              walletId: 'a',
            ),
          ]),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        WalletEdited(
          original: wallet('a'),
          name: 'BCA',
          iconKey: 'walletBank',
          isActive: true,
          initialBalance: 50000000,
        ),
      ),
      verify: (bloc) {
        final captured = verify(
          () => walletRepository.saveWallet(captureAny()),
        ).captured;
        expect(
          captured,
          hasLength(2),
          reason: 'sekali dari sunting, sekali dari recompute',
        );
        final recomputed = captured.last as Wallet;
        expect(recomputed.initialBalance, 50000000);
        expect(
          recomputed.currentBalance,
          60000000,
          reason: 'saldo awal baru + pemasukan yang sudah ada',
        );
      },
    );

    blocTest<WalletBloc, WalletState>(
      'menonaktifkan dompet mengeluarkannya dari daftar aktif dan total, transaksinya tetap ada',
      setUp: () {
        when(
          () => walletRepository.saveWallet(any()),
        ).thenAnswer((_) async => const Right(unit));
        when(
          () => walletRepository.listWallets(),
        ).thenAnswer(
          (_) async => Right([wallet('a', current: 10000000, isActive: false)]),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        WalletEdited(
          original: wallet('a', current: 10000000),
          name: 'BCA',
          iconKey: 'walletBank',
          isActive: false,
        ),
      ),
      verify: (bloc) {
        expect(bloc.state.activeWallets, isEmpty);
        expect(bloc.state.inactiveWallets.single.id, 'a');
        expect(bloc.state.totalBalance, 0);
        verifyNever(() => transactionRepository.listAllTransactions());
      },
    );
  });

  group('WalletBloc -- hapus (FR-WAL-001)', () {
    blocTest<WalletBloc, WalletState>(
      'dompet tanpa transaksi dihapus',
      setUp: () {
        when(
          () => transactionRepository.listAllTransactions(),
        ).thenAnswer((_) async => const Right([]));
        when(
          () => walletRepository.deleteWallet(any()),
        ).thenAnswer((_) async => const Right(unit));
        when(
          () => walletRepository.listWallets(),
        ).thenAnswer((_) async => Right([wallet('b', name: 'GoPay')]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(WalletDeleted(wallet('a'))),
      verify: (bloc) {
        expect(bloc.state.wallets.map((w) => w.id), ['b']);
        expect(messageOf(bloc.state), t.wallet.deletedMessage);
        verify(() => walletRepository.deleteWallet('a')).called(1);
      },
    );

    blocTest<WalletBloc, WalletState>(
      'dompet yang punya transaksi (pemasukan) TIDAK dihapus',
      setUp: () {
        when(() => transactionRepository.listAllTransactions()).thenAnswer(
          (_) async => Right([
            IncomeTransaction(
              id: 'i1',
              date: DateTime(2026, 9, 5),
              amount: 100,
              note: '',
              walletId: 'a',
            ),
          ]),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(WalletDeleted(wallet('a'))),
      verify: (bloc) {
        expect(messageOf(bloc.state), t.wallet.deleteBlockedMessage);
        verifyNever(() => walletRepository.deleteWallet(any()));
      },
    );

    blocTest<WalletBloc, WalletState>(
      'dompet yang hanya muncul sebagai TUJUAN transfer juga tidak boleh dihapus',
      setUp: () {
        when(() => transactionRepository.listAllTransactions()).thenAnswer(
          (_) async => Right([
            TransferTransaction(
              id: 't1',
              date: DateTime(2026, 9, 5),
              amount: 100,
              note: '',
              fromWalletId: 'a',
              toWalletId: 'b',
            ),
          ]),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(WalletDeleted(wallet('b', name: 'GoPay'))),
      verify: (bloc) {
        expect(messageOf(bloc.state), t.wallet.deleteBlockedMessage);
        verifyNever(() => walletRepository.deleteWallet(any()));
      },
    );
  });
}
