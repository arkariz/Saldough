import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/shared/savings_goal/domain/savings_goal.dart';
import 'package:saldough/shared/savings_goal/domain/savings_goal_repository.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Kode [ValidationFailure] tujuan tabungan (ADR-048 §3.3, §8).
abstract final class SavingsGoalFailures {
  SavingsGoalFailures._();

  /// Nama kosong.
  static const nameRequired = FailureCode('SAVINGS_GOAL_NAME_REQUIRED');

  /// Target tidak positif.
  static const targetNotPositive = FailureCode('SAVINGS_GOAL_TARGET_NOT_POSITIVE');

  /// Batas tujuan Active Gratis tercapai (P11). Pemanggil menyimpan draf dan
  /// membuka paywall.
  static const activeLimitReached = FailureCode('SAVINGS_GOAL_ACTIVE_LIMIT_REACHED');

  /// Tujuan tidak ditemukan.
  static const notFound = FailureCode('SAVINGS_GOAL_NOT_FOUND');
}

/// Jumlah tujuan berstatus Active di [goals], kecuali yang ber-`id` [exceptId].
int activeGoalCount(Iterable<SavingsGoal> goals, {String? exceptId}) =>
    goals.where((g) => g.status == SavingsGoalStatus.active && g.id != exceptId).length;

Either<Failure, SavingsGoal> _validated(SavingsGoal goal) {
  final trimmed = goal.copyWith(name: goal.name.trim());
  if (trimmed.name.isEmpty) {
    return left(const ValidationFailure(code: SavingsGoalFailures.nameRequired, message: 'Nama tujuan kosong.'));
  }
  if (trimmed.targetAmount <= 0) {
    return left(
      const ValidationFailure(code: SavingsGoalFailures.targetNotPositive, message: 'Target harus lebih dari nol.'),
    );
  }
  return right(trimmed);
}

/// Membuat tujuan beserta dompetnya sendiri (ADR-048 §8.2). Dompet bernama
/// dan berikon sama dengan tujuan; [initialAmount] ("Sudah terkumpul") menjadi
/// saldo awalnya, bukan transaksi. Batas Active diperiksa sebelum apa pun
/// ditulis ([activeLimit] `null` = Plus). Bila tujuan gagal disimpan, dompet
/// yang baru dibuat dihapus lagi.
final class CreateSavingsGoal {
  /// Membuat [CreateSavingsGoal].
  const CreateSavingsGoal({
    required this.goalRepository,
    required this.walletRepository,
    this.now = DateTime.now,
  });

  /// Penyimpanan tujuan.
  final SavingsGoalRepository goalRepository;

  /// Penyimpanan dompet.
  final WalletRepository walletRepository;

  /// Jam, bisa diganti di uji.
  final DateTime Function() now;

  /// Menyimpan [goal] (field `walletId`-nya diabaikan, dompet dibuat baru)
  /// dan mengembalikan tujuan yang tersimpan.
  Future<Either<Failure, SavingsGoal>> call(SavingsGoal goal, {int initialAmount = 0, int? activeLimit}) async {
    final SavingsGoal valid;
    switch (_validated(goal)) {
      case Left(value: final failure):
        return left(failure);
      case Right(: final value):
        valid = value;
    }
    final List<SavingsGoal> goals;
    switch (await goalRepository.listGoals()) {
      case Left(value: final failure):
        return left(failure);
      case Right(: final value):
        goals = value;
    }
    if (activeLimit != null && activeGoalCount(goals) >= activeLimit) {
      return left(
        const ValidationFailure(code: SavingsGoalFailures.activeLimitReached, message: 'Batas tujuan aktif tercapai.'),
      );
    }
    final wallet = Wallet(
      id: 'goal-${valid.id}',
      name: valid.name,
      iconKey: valid.iconKey,
      initialBalance: initialAmount,
      currentBalance: initialAmount,
    );
    if (await walletRepository.saveWallet(wallet) case Left(value: final failure)) return left(failure);
    final reached = initialAmount >= valid.targetAmount;
    final saved = SavingsGoal(
      id: valid.id,
      name: valid.name,
      targetAmount: valid.targetAmount,
      iconKey: valid.iconKey,
      walletId: wallet.id,
      createdAt: valid.createdAt,
      status: reached ? SavingsGoalStatus.completed : SavingsGoalStatus.active,
      targetDate: valid.targetDate,
      description: valid.description,
      completedAt: reached ? now() : null,
    );
    switch (await goalRepository.saveGoal(saved)) {
      case Left(value: final failure):
        await walletRepository.deleteWallet(wallet.id);
        return left(failure);
      case Right():
        return right(saved);
    }
  }
}

/// Mengubah tujuan (ADR-048 §8.2): nama dan ikon disalin ke dompetnya; target
/// yang turun sampai tercapai menjadikan Active Completed. Tidak pernah
/// mengubah saldo.
final class UpdateSavingsGoal {
  /// Membuat [UpdateSavingsGoal].
  const UpdateSavingsGoal({
    required this.goalRepository,
    required this.walletRepository,
    this.now = DateTime.now,
  });

  /// Penyimpanan tujuan.
  final SavingsGoalRepository goalRepository;

  /// Penyimpanan dompet.
  final WalletRepository walletRepository;

  /// Jam, bisa diganti di uji.
  final DateTime Function() now;

  /// Menyimpan [goal] yang sudah ada.
  Future<Either<Failure, SavingsGoal>> call(SavingsGoal goal) async {
    final SavingsGoal valid;
    switch (_validated(goal)) {
      case Left(value: final failure):
        return left(failure);
      case Right(: final value):
        valid = value;
    }
    final List<Wallet> wallets;
    switch (await walletRepository.listWallets()) {
      case Left(value: final failure):
        return left(failure);
      case Right(: final value):
        wallets = value;
    }
    final wallet = wallets.where((w) => w.id == valid.walletId).firstOrNull;
    if (wallet != null && (wallet.name != valid.name || wallet.iconKey != valid.iconKey)) {
      final renamed = wallet.copyWith(name: valid.name, iconKey: valid.iconKey);
      if (await walletRepository.saveWallet(renamed) case Left(value: final failure)) return left(failure);
    }
    final saved = _completedIfReached(valid, wallets, now());
    return switch (await goalRepository.saveGoal(saved)) {
      Left(value: final failure) => left(failure),
      Right() => right(saved),
    };
  }
}

SavingsGoal _completedIfReached(SavingsGoal goal, List<Wallet> wallets, DateTime now) {
  if (goal.status != SavingsGoalStatus.active || !SavingsGoalProgress.of(goal, wallets).reached) return goal;
  return goal.copyWith(status: SavingsGoalStatus.completed, completedAt: goal.completedAt ?? now);
}

/// Menandai tujuan Active yang terkumpulnya sudah ≥ target sebagai Completed
/// (ADR-048 §3.3). Dipanggil sesudah buku besar berubah. Completed tidak
/// pernah kembali ke Active otomatis.
final class SyncSavingsGoalStatus {
  /// Membuat [SyncSavingsGoalStatus].
  const SyncSavingsGoalStatus({required this.goalRepository, required this.walletRepository, this.now = DateTime.now});

  /// Penyimpanan tujuan.
  final SavingsGoalRepository goalRepository;

  /// Sumber saldo dompet.
  final WalletRepository walletRepository;

  /// Jam, bisa diganti di uji.
  final DateTime Function() now;

  /// Tujuan yang BARU tercapai pada panggilan ini (untuk umpan balik dan
  /// analitik `goal_completed`); kosong bila tidak ada.
  Future<Either<Failure, List<SavingsGoal>>> call() async {
    final List<SavingsGoal> goals;
    switch (await goalRepository.listGoals()) {
      case Left(value: final failure):
        return left(failure);
      case Right(:final value):
        goals = value;
    }
    if (!goals.any((g) => g.status == SavingsGoalStatus.active)) return right(const []);
    final List<Wallet> wallets;
    switch (await walletRepository.listWallets()) {
      case Left(value: final failure):
        return left(failure);
      case Right(:final value):
        wallets = value;
    }
    final at = now();
    final next = [for (final g in goals) _completedIfReached(g, wallets, at)];
    final reached = [
      for (var i = 0; i < goals.length; i++)
        if (goals[i].status != next[i].status) next[i],
    ];
    if (reached.isEmpty) return right(const []);
    return switch (await goalRepository.saveGoals(next)) {
      Left(value: final failure) => left(failure),
      Right() => right(reached),
    };
  }
}

/// Mengarsipkan dan mengaktifkan lagi tujuan (ADR-048 §3.3, §3.5).
final class ChangeSavingsGoalStatus {
  /// Membuat [ChangeSavingsGoalStatus].
  const ChangeSavingsGoalStatus({
    required this.goalRepository,
    required this.walletRepository,
    this.now = DateTime.now,
  });

  /// Penyimpanan tujuan.
  final SavingsGoalRepository goalRepository;

  /// Sumber saldo dompet.
  final WalletRepository walletRepository;

  /// Jam, bisa diganti di uji.
  final DateTime Function() now;

  /// Mengarsipkan tujuan ber-`id` [id]; dompetnya tetap terpegang.
  Future<Either<Failure, SavingsGoal>> archive(String id) =>
      _update(id, (goal, _) => right(goal.copyWith(status: SavingsGoalStatus.archived)));

  /// Mengaktifkan lagi tujuan yang diarsipkan atau Completed: menjadi Active,
  /// atau langsung Completed bila sudah tercapai. Menjadi Active ditolak bila
  /// jumlah Active sudah mencapai [activeLimit] (`null` = tanpa batas).
  Future<Either<Failure, SavingsGoal>> reactivate(String id, {int? activeLimit}) => _update(id, (goal, all) {
    final wallets = all.wallets;
    final reached = SavingsGoalProgress.of(goal, wallets).reached;
    if (reached) {
      return right(goal.copyWith(status: SavingsGoalStatus.completed, completedAt: goal.completedAt ?? now()));
    }
    if (activeLimit != null && activeGoalCount(all.goals, exceptId: id) >= activeLimit) {
      return left(
        const ValidationFailure(code: SavingsGoalFailures.activeLimitReached, message: 'Batas tujuan aktif tercapai.'),
      );
    }
    return right(goal.copyWith(status: SavingsGoalStatus.active));
  });

  Future<Either<Failure, SavingsGoal>> _update(
    String id,
    Either<Failure, SavingsGoal> Function(SavingsGoal goal, ({List<SavingsGoal> goals, List<Wallet> wallets}) all)
    change,
  ) async {
    final List<SavingsGoal> goals;
    switch (await goalRepository.listGoals()) {
      case Left(value: final failure):
        return left(failure);
      case Right(:final value):
        goals = value;
    }
    final goal = goals.where((g) => g.id == id).firstOrNull;
    if (goal == null) {
      return left(const ValidationFailure(code: SavingsGoalFailures.notFound, message: 'Tujuan tidak ditemukan.'));
    }
    final List<Wallet> wallets;
    switch (await walletRepository.listWallets()) {
      case Left(value: final failure):
        return left(failure);
      case Right(:final value):
        wallets = value;
    }
    switch (change(goal, (goals: goals, wallets: wallets))) {
      case Left(value: final failure):
        return left(failure);
      case Right(value: final updated):
        return switch (await goalRepository.saveGoal(updated)) {
          Left(value: final failure) => left(failure),
          Right() => right(updated),
        };
    }
  }
}

/// Menghapus tujuan beserta SEMUANYA (keputusan pemilik, ADR-048 §8.2):
/// transaksi yang menyentuh dompet tujuan (lewat [RecordTransaction.delete]
/// supaya dompet lain dihitung ulang), dompetnya, lalu tujuannya. Berhenti di
/// kegagalan pertama.
final class DeleteSavingsGoal {
  /// Membuat [DeleteSavingsGoal].
  const DeleteSavingsGoal({
    required this.goalRepository,
    required this.walletRepository,
    required this.transactionRepository,
    required this.recordTransaction,
  });

  /// Penyimpanan tujuan.
  final SavingsGoalRepository goalRepository;

  /// Penyimpanan dompet.
  final WalletRepository walletRepository;

  /// Sumber transaksi.
  final TransactionRepository transactionRepository;

  /// Penghapus transaksi yang menghitung ulang saldo.
  final RecordTransaction recordTransaction;

  /// Menghapus tujuan ber-`id` [goalId]. [source] diteruskan ke
  /// `LedgerChanges`.
  Future<Either<Failure, Unit>> call(String goalId, {Object? source}) async {
    final List<SavingsGoal> goals;
    switch (await goalRepository.listGoals()) {
      case Left(value: final failure):
        return left(failure);
      case Right(: final value):
        goals = value;
    }
    final goal = goals.where((g) => g.id == goalId).firstOrNull;
    if (goal == null) {
      return left(const ValidationFailure(code: SavingsGoalFailures.notFound, message: 'Tujuan tidak ditemukan.'));
    }
    final List<Transaction> all;
    switch (await transactionRepository.listAllTransactions()) {
      case Left(value: final failure):
        return left(failure);
      case Right(: final value):
        all = value;
    }
    for (final tx in all.where((t) => walletIdsOf(t).contains(goal.walletId))) {
      if (await recordTransaction.delete(tx, source: source) case Left(value: final failure)) return left(failure);
    }
    if (await walletRepository.deleteWallet(goal.walletId) case Left(value: final failure)) return left(failure);
    return goalRepository.deleteGoal(goalId);
  }
}

/// [TransferOnlyWallets] dari tujuan tabungan: dompet milik tujuan mana pun
/// (ADR-048 §8.2a). Gagal membaca tujuan dianggap tidak ada dompet tujuan,
/// supaya pencatatan inti tidak pernah terhenti karenanya.
final class GoalTransferOnlyWallets implements TransferOnlyWallets {
  /// Membuat [GoalTransferOnlyWallets].
  const GoalTransferOnlyWallets(this.goalRepository);

  /// Penyimpanan tujuan.
  final SavingsGoalRepository goalRepository;

  @override
  Future<Set<String>> walletIds() async => goalWalletIds((await goalRepository.listGoals()).getOrElse((_) => const []));
}
