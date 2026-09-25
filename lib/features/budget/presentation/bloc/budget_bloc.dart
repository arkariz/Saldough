import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/budget/domain/entities/budget.dart';
import 'package:saldough/features/budget/domain/entities/budget_item.dart';
import 'package:saldough/features/budget/domain/entities/budget_period.dart';
import 'package:saldough/features/budget/domain/repositories/budget_repository.dart';
import 'package:saldough/features/budget/domain/usecases/calculate_budget_progress.dart';
import 'package:saldough/features/budget/presentation/bloc/budget_state.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

part 'budget_effect.dart';
part 'budget_event.dart';

/// Bloc layar Anggaran (FR-BUD-001..007): memuat anggaran beserta progresnya,
/// menambah, menyunting, mengarsipkan, menghapus, dan menyaring.
///
/// ⚠ Tidak satu pun jalur di sini menyentuh `WalletRepository.saveWallet`
/// atau `TransactionRepository` untuk menulis — anggaran adalah rencana,
/// bukan pemesanan uang (aturan 5 CLAUDE.md).
///
/// ⚠ Progres dihitung dari [TransactionRepository.listAllTransactions],
/// bukan transaksi satu bulan. Rumus `spent` (DOMAIN_MODEL.md) tidak punya
/// saringan tanggal — tautan pos yang menentukan — jadi transaksi tertaut
/// yang tanggalnya di luar periode tetap harus terhitung. Membatasi ke bulan
/// periode akan membuat angkanya salah tanpa gejala; ketepatan didahulukan.
final class BudgetBloc extends Bloc<BudgetEvent, BudgetState> {
  /// Membuat [BudgetBloc]. [now] bisa diganti di uji.
  BudgetBloc({
    required this._budgetRepository,
    required this._walletRepository,
    required this._transactionRepository,
    this._calculateProgress = const CalculateBudgetProgress(),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(BudgetState.initial()) {
    on<BudgetStarted>(_onStarted);
    on<BudgetRefreshed>(_onRefreshed);
    on<BudgetAdded>(_onAdded);
    on<BudgetEdited>(_onEdited);
    on<BudgetArchiveToggled>(_onArchiveToggled);
    on<BudgetDeleted>(_onDeleted);
    on<BudgetStatusFilterChanged>((event, emit) => emit(state.copyWith(statusFilter: event.filter)));
    on<BudgetWalletFilterChanged>((event, emit) => emit(state.copyWith(walletFilter: () => event.walletId)));
  }

  final BudgetRepository _budgetRepository;
  final WalletRepository _walletRepository;
  final TransactionRepository _transactionRepository;
  final CalculateBudgetProgress _calculateProgress;
  final DateTime Function() _now;

  Future<void> _onStarted(BudgetStarted event, Emitter<BudgetState> emit) async {
    emit(state.copyWith(isLoading: true, loadFailed: false));
    await _load(
      emit,
      onFailure: (failure) => state.copyWith(isLoading: false, loadFailed: true, effect: _effectError(failure)),
    );
  }

  Future<void> _onRefreshed(BudgetRefreshed event, Emitter<BudgetState> emit) =>
      _load(emit, onFailure: (failure) => state.copyWith(effect: _effectError(failure)));

  Future<void> _onAdded(BudgetAdded event, Emitter<BudgetState> emit) async {
    final budget = Budget(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: event.name.trim(),
      walletId: event.walletId,
      period: event.period,
      startDate: event.startDate,
      items: event.items,
    );
    await _afterWrite(await _budgetRepository.saveBudget(budget), t.budget.savedMessage, emit);
  }

  Future<void> _onEdited(BudgetEdited event, Emitter<BudgetState> emit) async {
    await _afterWrite(await _budgetRepository.saveBudget(event.budget), t.budget.updatedMessage, emit);
  }

  Future<void> _onArchiveToggled(BudgetArchiveToggled event, Emitter<BudgetState> emit) async {
    final archived = !event.budget.isArchived;
    await _afterWrite(
      await _budgetRepository.saveBudget(event.budget.copyWith(isArchived: archived)),
      archived ? t.budget.archivedMessage : t.budget.unarchivedMessage,
      emit,
    );
  }

  Future<void> _onDeleted(BudgetDeleted event, Emitter<BudgetState> emit) async {
    await _afterWrite(await _budgetRepository.deleteBudget(event.budget.id), t.budget.deletedMessage, emit);
  }

  /// Membaca anggaran, dompet, dan seluruh transaksi, lalu menghitung progres
  /// tiap anggaran pada saat [_now].
  Future<void> _load(
    Emitter<BudgetState> emit, {
    required BudgetState Function(Failure) onFailure,
    UiEffect? onSuccess,
  }) async {
    final budgets = await _budgetRepository.listBudgets();
    final wallets = await _walletRepository.listWallets();
    final transactions = await _transactionRepository.listAllTransactions();
    switch ((budgets, wallets, transactions)) {
      case (Right(value: final budgets), Right(value: final wallets), Right(value: final transactions)):
        final now = _now();
        emit(
          state.copyWith(
            budgets: budgets,
            wallets: wallets,
            transactions: transactions,
            progress: {for (final budget in budgets) budget.id: _calculateProgress(budget, transactions, now: now)},
            isLoading: false,
            loadFailed: false,
            effect: onSuccess,
          ),
        );
      case (Left(value: final failure), _, _) ||
          (_, Left(value: final failure), _) ||
          (_, _, Left(value: final failure)):
        emit(onFailure(failure));
    }
  }

  /// Sesudah menulis: kalau gagal, tampilkan galat; kalau berhasil, muat
  /// ulang TANPA `isLoading` lalu tampilkan pesan berhasil.
  Future<void> _afterWrite(Either<Failure, Unit> result, String successMessage, Emitter<BudgetState> emit) async {
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _effectError(failure)));
      case Right():
        await _load(
          emit,
          onFailure: (failure) => state.copyWith(effect: _effectError(failure)),
          onSuccess: _effectSaved(successMessage),
        );
    }
  }
}
