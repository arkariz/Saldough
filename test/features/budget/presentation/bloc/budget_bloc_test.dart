import 'package:bloc_test/bloc_test.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saldough/features/budget/domain/entities/budget.dart';
import 'package:saldough/features/budget/domain/entities/budget_item.dart';
import 'package:saldough/features/budget/domain/entities/budget_period.dart';
import 'package:saldough/features/budget/domain/entities/budget_status.dart';
import 'package:saldough/features/budget/presentation/bloc/budget_bloc.dart';
import 'package:saldough/features/budget/presentation/bloc/budget_state.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

import '../../../../helpers/mocks.dart';

const _forcedFailure = SystemFailure(code: FailureCode('TEST_FORCED_FAILURE'), message: 'dipaksa gagal untuk uji');

void main() {
  late MockBudgetRepository budgetRepository;
  late MockWalletRepository walletRepository;
  late MockTransactionRepository transactionRepository;

  final now = DateTime(2026, 9, 15);

  // Aktif (September, BCA), selesai (Agustus, BCA), nonaktif (GoPay).
  final household = Budget(
    id: 'rumah',
    name: 'Rumah tangga',
    walletId: 'bca',
    period: BudgetPeriod.monthly,
    startDate: DateTime(2026, 9),
    items: const [BudgetItem(id: 'belanja', name: 'Belanja', enteredAmount: 230640000)],
  );
  final august = Budget(
    id: 'agustus',
    name: 'Agustus',
    walletId: 'bca',
    period: BudgetPeriod.monthly,
    startDate: DateTime(2026, 8),
  );
  final archived = Budget(
    id: 'jajan',
    name: 'Jajan',
    walletId: 'gopay',
    period: BudgetPeriod.weekly,
    startDate: DateTime(2026, 9, 14),
    isArchived: true,
  );

  setUpAll(() {
    registerFallbackValue(fallbackBudget);
    registerFallbackValue(fallbackWallet);
    registerFallbackValue(fallbackTransaction);
  });

  setUp(() {
    budgetRepository = MockBudgetRepository();
    walletRepository = MockWalletRepository();
    transactionRepository = MockTransactionRepository();
    when(() => budgetRepository.listBudgets()).thenAnswer((_) async => Right([household, august, archived]));
    when(() => walletRepository.listWallets()).thenAnswer(
      (_) async => const Right([
        Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 0, currentBalance: 500000000),
        Wallet(id: 'gopay', name: 'GoPay', iconKey: 'walletEwallet', initialBalance: 0, currentBalance: 0),
      ]),
    );
    when(() => transactionRepository.listAllTransactions()).thenAnswer(
      (_) async => Right([
        ExpenseTransaction(
          id: 'e1',
          date: DateTime(2026, 9, 5),
          amount: 57660000,
          note: '',
          walletId: 'bca',
          budgetItemId: 'belanja',
        ),
        // Tertaut ke pos yang sama, tetapi dari dompet lain — tidak terhitung.
        ExpenseTransaction(
          id: 'e2',
          date: DateTime(2026, 9, 6),
          amount: 1000000,
          note: '',
          walletId: 'gopay',
          budgetItemId: 'belanja',
        ),
      ]),
    );
    when(() => budgetRepository.saveBudget(any())).thenAnswer((_) async => const Right(unit));
    when(() => budgetRepository.deleteBudget(any())).thenAnswer((_) async => const Right(unit));
  });

  BudgetBloc buildBloc() => BudgetBloc(
    budgetRepository: budgetRepository,
    walletRepository: walletRepository,
    transactionRepository: transactionRepository,
    now: () => now,
  );

  /// Anggaran tidak pernah menulis dompet maupun transaksi (aturan 5).
  void verifyNoMoneyWrites() {
    verifyNever(() => walletRepository.saveWallet(any()));
    verifyNever(() => transactionRepository.saveTransaction(any(), previousDate: any(named: 'previousDate')));
    verifyNever(() => transactionRepository.deleteTransaction(any(), any()));
  }

  group('BudgetBloc', () {
    blocTest<BudgetBloc, BudgetState>(
      'BudgetStarted memuat anggaran dan menghitung progres dari transaksi tertaut',
      build: buildBloc,
      act: (bloc) => bloc.add(const BudgetStarted()),
      verify: (bloc) {
        final state = bloc.state;
        expect(state.isLoading, isFalse);
        expect(state.progress['rumah']!.spent, 57660000);
        expect(state.progress['rumah']!.status, BudgetStatus.active);
        expect(state.progress['agustus']!.status, BudgetStatus.finished);
        expect(state.progress['jajan']!.status, BudgetStatus.archived);
        expect(state.linkedTransactions(household).map((t) => t.id), ['e1']);
      },
    );

    blocTest<BudgetBloc, BudgetState>(
      'ringkasan puncak hanya menjumlahkan anggaran AKTIF',
      build: buildBloc,
      act: (bloc) => bloc.add(const BudgetStarted()),
      verify: (bloc) {
        // Rencana = jumlah pos anggaran aktif (satu pos Rp2.306.400), ADR-017.
        expect(bloc.state.activePlanned, 230640000);
        expect(bloc.state.activeSpent, 57660000);
      },
    );

    blocTest<BudgetBloc, BudgetState>(
      'kegagalan pemuatan menyetel loadFailed, bukan daftar kosong',
      setUp: () => when(() => budgetRepository.listBudgets()).thenAnswer((_) async => const Left(_forcedFailure)),
      build: buildBloc,
      act: (bloc) => bloc.add(const BudgetStarted()),
      verify: (bloc) {
        expect(bloc.state.loadFailed, isTrue);
        expect(bloc.state.isLoading, isFalse);
      },
    );

    blocTest<BudgetBloc, BudgetState>(
      'penyaring status dan dompet (FR-BUD-006)',
      build: buildBloc,
      act: (bloc) => bloc
        ..add(const BudgetStarted())
        ..add(const BudgetStatusFilterChanged(BudgetStatusFilter.finished)),
      verify: (bloc) {
        expect(bloc.state.visibleBudgets.map((b) => b.id), ['agustus']);
        expect(bloc.state.statusCounts[BudgetStatusFilter.all], 3);
        expect(bloc.state.statusCounts[BudgetStatusFilter.active], 1);
        expect(bloc.state.statusCounts[BudgetStatusFilter.archived], 1);
      },
    );

    blocTest<BudgetBloc, BudgetState>(
      'penyaring dompet menyempitkan daftar dan hitungan, lalu bisa dikosongkan',
      build: buildBloc,
      act: (bloc) => bloc
        ..add(const BudgetStarted())
        ..add(const BudgetWalletFilterChanged('gopay'))
        ..add(const BudgetWalletFilterChanged(null)),
      verify: (bloc) {
        expect(bloc.state.walletFilter, isNull);
        expect(bloc.state.visibleBudgets.map((b) => b.id), ['rumah', 'agustus', 'jajan']);
      },
    );

    blocTest<BudgetBloc, BudgetState>(
      'BudgetAdded menyimpan anggaran baru tanpa menyentuh saldo dompet mana pun',
      build: buildBloc,
      act: (bloc) => bloc.add(
        BudgetAdded(
          name: '  Belanja  ',
          walletId: 'bca',
          period: BudgetPeriod.weekly,
          startDate: DateTime(2026, 9, 14),
          items: const [],
        ),
      ),
      verify: (_) {
        final saved = verify(() => budgetRepository.saveBudget(captureAny())).captured.single as Budget;
        expect(saved.name, 'Belanja');
        expect(saved.walletId, 'bca');
        expect(saved.isArchived, isFalse);
        verifyNoMoneyWrites();
      },
    );

    blocTest<BudgetBloc, BudgetState>(
      'BudgetArchiveToggled membalik isArchived tanpa menyentuh saldo atau transaksi',
      build: buildBloc,
      act: (bloc) => bloc.add(BudgetArchiveToggled(household)),
      verify: (_) {
        final saved = verify(() => budgetRepository.saveBudget(captureAny())).captured.single as Budget;
        expect(saved.isArchived, isTrue);
        expect(saved.items, household.items);
        verifyNoMoneyWrites();
      },
    );

    blocTest<BudgetBloc, BudgetState>(
      'BudgetDeleted menghapus anggaran saja — transaksi tertaut dan saldo tidak disentuh',
      build: buildBloc,
      act: (bloc) => bloc.add(BudgetDeleted(household)),
      verify: (_) {
        verify(() => budgetRepository.deleteBudget('rumah')).called(1);
        verifyNoMoneyWrites();
      },
    );

    blocTest<BudgetBloc, BudgetState>(
      'penulisan yang gagal memancarkan efek galat dan tidak memuat ulang',
      setUp: () => when(() => budgetRepository.saveBudget(any())).thenAnswer((_) async => const Left(_forcedFailure)),
      build: buildBloc,
      act: (bloc) => bloc.add(BudgetEdited(household.copyWith(name: 'x'))),
      verify: (_) => verifyNever(() => budgetRepository.listBudgets()),
    );
  });
}
