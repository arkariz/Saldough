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
  late LedgerChanges ledgerChanges;

  setUpAll(() {
    registerFallbackValue(fallbackWallet);
    registerFallbackValue(fallbackTransaction);
  });

  setUp(() {
    walletRepository = MockWalletRepository();
    transactionRepository = MockTransactionRepository();
    ledgerChanges = LedgerChanges();
  });

  WalletBloc buildBloc() => WalletBloc(
    ledgerChanges: ledgerChanges,
    walletRepository: walletRepository,
    transactionRepository: transactionRepository,
    recordTransaction: RecordTransaction(
      ledgerChanges: ledgerChanges,
      transactionRepository: transactionRepository,
      recomputeWalletBalances: RecomputeWalletBalances(
        walletRepository: walletRepository,
        transactionRepository: transactionRepository,
      ),
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

  String? messageOf(WalletState state) =>
      (state.effect as ShowSnackBarEffect?)?.message;

  group('WalletBloc -- memuat', () {
    blocTest<WalletBloc, WalletState>(
      'WalletStarted memuat dompet aktif maupun tidak',
      setUp: () {
        when(
          () => walletRepository.listWallets(),
        ).thenAnswer(
          (_) async =>
              Right([wallet('a'), wallet('b', name: 'Lama', isActive: false)]),
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

    // ADR-047 §3.2 (KT-W1 = B): selisih dicatat sebagai penyesuaian saldo
    // bertanggal hari ini; saldo awal tidak pernah digeser.
    group('penyesuaian saldo (ADR-047)', () {
      final income = IncomeTransaction(
        id: 'i1',
        date: DateTime(2026, 9, 5),
        amount: 10000000,
        note: '',
        walletId: 'a',
      );

      void stubLedger({Either<Failure, Unit> save = const Right(unit)}) {
        when(() => walletRepository.saveWallet(any())).thenAnswer((_) async => const Right(unit));
        when(
          () => walletRepository.listWallets(),
        ).thenAnswer((_) async => Right([wallet('a', current: 10000000)]));
        when(() => transactionRepository.listAllTransactions()).thenAnswer((_) async => Right([income]));
        when(
          () => transactionRepository.saveTransaction(any(), previousDate: any(named: 'previousDate')),
        ).thenAnswer((_) async => save);
      }

      BalanceAdjustmentTransaction savedAdjustment() =>
          verify(
                () => transactionRepository.saveTransaction(captureAny(), previousDate: any(named: 'previousDate')),
              ).captured.single
              as BalanceAdjustmentTransaction;

      blocTest<WalletBloc, WalletState>(
        'menaikkan saldo mencatat satu penyesuaian "increase" sebesar selisihnya, saldo awal tetap',
        setUp: stubLedger,
        build: buildBloc,
        act: (bloc) => bloc.add(
          WalletEdited(
            original: wallet('a', current: 10000000),
            name: 'BCA',
            iconKey: 'walletBank',
            isActive: true,
            currentBalance: 10050000,
          ),
        ),
        verify: (bloc) {
          final adjustment = savedAdjustment();
          expect(adjustment.walletId, 'a');
          expect(adjustment.direction, AdjustmentDirection.increase);
          expect(adjustment.amount, 50000);
          expect(adjustment.categoryId, isNull);
          expect(adjustment.recurrence, isNull);
          final today = DateTime.now();
          expect(DateTime(adjustment.date.year, adjustment.date.month, adjustment.date.day), DateTime(today.year, today.month, today.day));
          final edited = verify(() => walletRepository.saveWallet(captureAny())).captured.first as Wallet;
          expect(edited.initialBalance, 0, reason: 'saldo awal tidak digeser lagi');
          expect(messageOf(bloc.state), t.assets.adjust.savedMessage(amount: '+Rp500'));
        },
      );

      blocTest<WalletBloc, WalletState>(
        'menurunkan saldo (sampai negatif) mencatat penyesuaian "decrease"',
        setUp: stubLedger,
        build: buildBloc,
        act: (bloc) => bloc.add(
          WalletEdited(
            original: wallet('a', current: 10000000),
            name: 'BCA',
            iconKey: 'walletBank',
            isActive: true,
            currentBalance: -2500,
          ),
        ),
        verify: (_) {
          final adjustment = savedAdjustment();
          expect(adjustment.direction, AdjustmentDirection.decrease);
          expect(adjustment.amount, 10002500);
        },
      );

      blocTest<WalletBloc, WalletState>(
        'selisih dihitung dari transaksi, bukan dari cache saldo yang basi',
        setUp: stubLedger,
        build: buildBloc,
        act: (bloc) => bloc.add(
          WalletEdited(
            // Cache bilang 9.000.000, padahal transaksinya 10.000.000.
            original: wallet('a', current: 9000000),
            name: 'BCA',
            iconKey: 'walletBank',
            isActive: true,
            currentBalance: 10000000,
          ),
        ),
        verify: (_) {
          verify(() => transactionRepository.listAllTransactions()).called(greaterThanOrEqualTo(1));
          verifyNever(
            () => transactionRepository.saveTransaction(any(), previousDate: any(named: 'previousDate')),
          );
        },
      );

      blocTest<WalletBloc, WalletState>(
        'gagal mencatat penyesuaian: nama tetap tersimpan, galat ditampilkan',
        setUp: () => stubLedger(save: const Left(_forcedFailure)),
        build: buildBloc,
        act: (bloc) => bloc.add(
          WalletEdited(
            original: wallet('a', current: 10000000),
            name: 'BCA Baru',
            iconKey: 'walletBank',
            isActive: true,
            currentBalance: 20000000,
          ),
        ),
        verify: (bloc) {
          final edited = verify(() => walletRepository.saveWallet(captureAny())).captured.first as Wallet;
          expect(edited.name, 'BCA Baru');
          expect(messageOf(bloc.state), isNot(t.wallet.updatedMessage));
        },
      );
    });

    blocTest<WalletBloc, WalletState>(
      'saldo saat ini yang sama dengan saldo tercatat tidak mengubah apa pun',
      setUp: () {
        when(() => walletRepository.saveWallet(any())).thenAnswer((_) async => const Right(unit));
        when(() => walletRepository.listWallets()).thenAnswer((_) async => Right([wallet('a', current: 10000000)]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        WalletEdited(
          original: wallet('a', current: 10000000),
          name: 'BCA',
          iconKey: 'walletBank',
          isActive: true,
          currentBalance: 10000000,
        ),
      ),
      verify: (bloc) {
        verify(() => walletRepository.saveWallet(any())).called(1);
        verifyNever(() => transactionRepository.listAllTransactions());
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

  group('WalletBloc -- LedgerChanges (ADR-030 §3.4)', () {
    blocTest<WalletBloc, WalletState>(
      'sinyal dari tempat lain memuat ulang tanpa kerangka',
      setUp: () {
        var calls = 0;
        when(() => walletRepository.listWallets()).thenAnswer(
          (_) async => Right([wallet('a', initial: calls++ == 0 ? 100 : 250)]),
        );
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const WalletStarted());
        await pumpEventQueue();
        ledgerChanges.notifyChanged();
      },
      expect: () => [
        isA<WalletState>().having((s) => s.isLoading, 'isLoading', isTrue),
        isA<WalletState>().having((s) => s.wallets.single.currentBalance, 'saldo', 100),
        isA<WalletState>()
            .having((s) => s.wallets.single.currentBalance, 'saldo', 250)
            .having((s) => s.isLoading, 'isLoading', isFalse),
      ],
    );

    test('menyimpan dompet memancarkan sinyal sekali, dengan dirinya sebagai sumber', () async {
      when(() => walletRepository.saveWallet(any())).thenAnswer((_) async => const Right(unit));
      when(() => walletRepository.listWallets()).thenAnswer((_) async => Right([wallet('a')]));
      final sources = <Object?>[];
      final subscription = ledgerChanges.changes.listen(sources.add);
      addTearDown(subscription.cancel);
      final bloc = buildBloc();
      addTearDown(bloc.close);

      bloc.add(const WalletAdded(name: 'BCA', iconKey: 'walletBank', initialBalance: 0));
      await pumpEventQueue();

      expect(sources, [same(bloc)]);
      expect(messageOf(bloc.state), t.wallet.savedMessage);
      verify(() => walletRepository.listWallets()).called(1);
    });
  });

  group('WalletBloc -- urutan dompet (B-34)', () {
    test('WalletsReordered menyimpan urutan, memuat ulang dalam urutan baru, dan memancarkan sinyal', () async {
      // Stub mencerminkan penulisan terakhir: listWallets mengikuti urutan
      // yang terakhir disimpan.
      var stored = [wallet('a'), wallet('b', name: 'Tunai'), wallet('c', name: 'GoPay')];
      when(() => walletRepository.reorderWallets(any())).thenAnswer((invocation) async {
        final ids = invocation.positionalArguments.single as List<String>;
        stored = [for (final id in ids) stored.firstWhere((w) => w.id == id)];
        return const Right(unit);
      });
      when(() => walletRepository.listWallets()).thenAnswer((_) async => Right(stored));
      final sources = <Object?>[];
      final subscription = ledgerChanges.changes.listen(sources.add);
      addTearDown(subscription.cancel);
      final bloc = buildBloc();
      addTearDown(bloc.close);

      bloc.add(const WalletsReordered(['c', 'a', 'b']));
      await pumpEventQueue();

      verify(() => walletRepository.reorderWallets(['c', 'a', 'b'])).called(1);
      expect(bloc.state.wallets.map((w) => w.id), ['c', 'a', 'b']);
      expect(messageOf(bloc.state), t.wallet.reorderedMessage);
      expect(sources, [same(bloc)]);
    });

    blocTest<WalletBloc, WalletState>(
      'gagal menyimpan urutan: daftar tetap, galat tampil, tanpa sinyal',
      setUp: () {
        when(() => walletRepository.reorderWallets(any())).thenAnswer((_) async => const Left(_forcedFailure));
      },
      build: buildBloc,
      seed: () => WalletState.initial().copyWith(wallets: [wallet('a'), wallet('b')], isLoading: false),
      act: (bloc) => bloc.add(const WalletsReordered(['b', 'a'])),
      expect: () => [
        isA<WalletState>()
            .having((s) => s.wallets.map((w) => w.id), 'urutan', ['a', 'b'])
            .having((s) => s.effect, 'effect', isNotNull),
      ],
      verify: (_) => verifyNever(() => walletRepository.listWallets()),
    );
  });
}
