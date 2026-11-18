import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/shared/savings_goal/savings_goal.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// ADR-048 §8: tiap tujuan punya satu dompet sendiri; dompet itu hanya untuk
/// transfer; menghapus tujuan menghapus semuanya.
void main() {
  late InMemoryKeyValueStorage storage;
  late SavingsGoalRepositoryImpl goals;
  late WalletRepositoryImpl wallets;
  late TransactionRepositoryImpl transactions;
  final now = DateTime(2026, 11, 17, 9);

  RecordTransaction record() => RecordTransaction(
    transferOnlyWallets: GoalTransferOnlyWallets(goals),
    ledgerChanges: LedgerChanges(),
    transactionRepository: transactions,
    recomputeWalletBalances: RecomputeWalletBalances(walletRepository: wallets, transactionRepository: transactions),
  );
  CreateSavingsGoal create() => CreateSavingsGoal(goalRepository: goals, walletRepository: wallets, now: () => now);
  UpdateSavingsGoal update() => UpdateSavingsGoal(goalRepository: goals, walletRepository: wallets, now: () => now);
  SyncSavingsGoalStatus sync() =>
      SyncSavingsGoalStatus(goalRepository: goals, walletRepository: wallets, now: () => now);
  ChangeSavingsGoalStatus change() =>
      ChangeSavingsGoalStatus(goalRepository: goals, walletRepository: wallets, now: () => now);

  SavingsGoal draft(String id, {int target = 1000000, SavingsGoalStatus status = SavingsGoalStatus.active}) =>
      SavingsGoal(
        id: id,
        name: 'Tujuan $id',
        targetAmount: target,
        iconKey: 'home',
        walletId: 'goal-$id',
        createdAt: DateTime(2026, 11),
        status: status,
      );

  const bca = Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 1000000, currentBalance: 1000000);

  Future<List<SavingsGoal>> storedGoals() async => (await goals.listGoals()).getOrElse((_) => throw StateError('x'));
  Future<List<Wallet>> storedWallets() async => (await wallets.listWallets()).getOrElse((_) => throw StateError('x'));
  Future<int> balanceOf(String id) async => (await storedWallets()).firstWhere((w) => w.id == id).currentBalance;
  FailureCode? codeOf<T>(Either<Failure, T> result) => result.fold((f) => f.code, (_) => null);
  T ok<T>(Either<Failure, T> result) => result.getOrElse((f) => throw StateError('$f'));

  setUp(() {
    storage = InMemoryKeyValueStorage();
    goals = SavingsGoalRepositoryImpl(storage: storage);
    wallets = WalletRepositoryImpl(storage: storage);
    transactions = TransactionRepositoryImpl(storage: storage);
  });

  test('SavingsGoalProgress: saldo dompet tujuan; dompet hilang 0; negatif tampil 0%', () {
    final goal = draft('g', target: 1000);
    const wallet = Wallet(id: 'goal-g', name: 'x', iconKey: 'x', initialBalance: 0, currentBalance: 550);
    expect(SavingsGoalProgress.of(goal, const [wallet]).percent, 55);
    expect(SavingsGoalProgress.of(goal, const []).collected, 0);
    expect(const SavingsGoalProgress(collected: -5, target: 1000).percent, 0);
    expect(const SavingsGoalProgress(collected: 1500, target: 1000).remaining, 0);
  });

  group('CreateSavingsGoal (§8.2)', () {
    test('membuat dompet sendiri; Sudah terkumpul jadi saldo awal, bukan transaksi', () async {
      final saved = ok(await create()(draft('g'), initialAmount: 300000));
      final wallet = (await storedWallets()).single;
      expect(saved.walletId, wallet.id);
      expect(
        (wallet.name, wallet.iconKey, wallet.initialBalance, wallet.currentBalance),
        ('Tujuan g', 'home', 300000, 300000),
      );
      expect(ok(await transactions.listAllTransactions()), isEmpty);
    });

    test('Sudah terkumpul ≥ target: langsung Completed', () async {
      final saved = ok(await create()(draft('g', target: 100), initialAmount: 100));
      expect(saved.status, SavingsGoalStatus.completed);
      expect(saved.completedAt, now);
    });

    test('nama kosong, target bukan positif, dan batas Gratis ditolak sebelum dompet dibuat', () async {
      expect(codeOf(await create()(draft('g').copyWith(name: ' '))), SavingsGoalFailures.nameRequired);
      expect(codeOf(await create()(draft('g', target: 0))), SavingsGoalFailures.targetNotPositive);
      await goals.saveGoals([draft('a'), draft('b'), draft('c', status: SavingsGoalStatus.archived)]);
      expect(codeOf(await create()(draft('d'), activeLimit: 2)), SavingsGoalFailures.activeLimitReached);
      expect(await storedWallets(), isEmpty, reason: 'tidak ada dompet yatim');
    });
  });

  test('UpdateSavingsGoal menyalin nama dan ikon ke dompet; target turun sampai tercapai jadi Completed', () async {
    final saved = ok(await create()(draft('g'), initialAmount: 500));
    final updated = ok(await update()(saved.copyWith(name: 'Liburan', iconKey: 'beach', targetAmount: 400)));
    final wallet = (await storedWallets()).single;
    expect((wallet.name, wallet.iconKey, wallet.currentBalance), ('Liburan', 'beach', 500));
    expect(updated.status, SavingsGoalStatus.completed);
  });

  test('dompet tujuan hanya untuk transfer (§8.2a)', () async {
    await wallets.saveWallet(bca);
    final goal = ok(await create()(draft('g')));
    final income = IncomeTransaction(id: 'i', date: now, amount: 100, note: '', walletId: goal.walletId);
    final expense = ExpenseTransaction(id: 'e', date: now, amount: 100, note: '', walletId: goal.walletId);
    expect(codeOf(await record()(income)), RecordTransaction.goalWalletTransferOnlyCode);
    expect(codeOf(await record()(expense)), RecordTransaction.goalWalletTransferOnlyCode);
    final transfer = TransferTransaction(
      id: 't',
      date: now,
      amount: 250000,
      note: '',
      fromWalletId: 'bca',
      toWalletId: goal.walletId,
    );
    expect((await record()(transfer)).isRight(), isTrue);
    expect(await balanceOf(goal.walletId), 250000);
  });

  test('DeleteSavingsGoal menghapus transaksi, dompet, dan tujuan; saldo dompet asal kembali', () async {
    await wallets.saveWallet(bca);
    final goal = ok(await create()(draft('g'), initialAmount: 50000));
    await record()(
      TransferTransaction(id: 't', date: now, amount: 300000, note: '', fromWalletId: 'bca', toWalletId: goal.walletId),
    );
    expect(await balanceOf('bca'), 700000);

    final result = await DeleteSavingsGoal(
      goalRepository: goals,
      walletRepository: wallets,
      transactionRepository: transactions,
      recordTransaction: record(),
    )(goal.id);

    expect(result.isRight(), isTrue);
    expect(await storedGoals(), isEmpty);
    expect((await storedWallets()).map((w) => w.id), ['bca']);
    expect(await balanceOf('bca'), 1000000);
    expect(ok(await transactions.listAllTransactions()), isEmpty);
  });

  test('status: tercapai jadi Completed sekali dan menetap walau saldo turun', () async {
    await wallets.saveWallet(
      const Wallet(id: 'goal-g', name: 'g', iconKey: 'home', initialBalance: 0, currentBalance: 2000000),
    );
    await goals.saveGoal(draft('g'));
    expect(ok(await sync()()).map((g) => g.id), ['g']);
    expect(ok(await sync()()), isEmpty);
    await wallets.saveWallet(
      const Wallet(id: 'goal-g', name: 'g', iconKey: 'home', initialBalance: 0, currentBalance: 1),
    );
    await sync()();
    expect((await storedGoals()).single.status, SavingsGoalStatus.completed);
  });

  test('arsip, lalu aktifkan lagi tunduk batas', () async {
    await goals.saveGoals([draft('a'), draft('b'), draft('arsip', status: SavingsGoalStatus.archived)]);
    expect(ok(await change().archive('a')).status, SavingsGoalStatus.archived);
    await goals.saveGoal(draft('a'));
    expect(codeOf(await change().reactivate('arsip', activeLimit: 2)), SavingsGoalFailures.activeLimitReached);
    expect((await change().reactivate('arsip')).isRight(), isTrue);
  });

  test('model JSON bolak-balik, field opsional ikut', () {
    final full = draft('g').copyWith(
      targetDate: DateTime(2027, 6),
      description: 'Untuk jaga-jaga',
      status: SavingsGoalStatus.completed,
      completedAt: DateTime(2026, 12),
    );
    expect(SavingsGoalModel.fromJson(SavingsGoalModel.toJson(full)), full);
    expect(SavingsGoalModel.fromJson(SavingsGoalModel.toJson(draft('h'))), draft('h'));
  });
}
