import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/budget/domain/entities/budget.dart';
import 'package:saldough/features/budget/domain/entities/budget_item.dart';
import 'package:saldough/features/budget/domain/entities/budget_period.dart';
import 'package:saldough/features/budget/domain/entities/budget_status.dart';
import 'package:saldough/features/budget/domain/repositories/budget_repository.dart';
import 'package:saldough/features/budget/domain/usecases/calculate_budget_progress.dart';
import 'package:saldough/features/budget/domain/usecases/read_transactions_in_months.dart';
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
/// Progres hanya dihitung untuk anggaran yang ditampilkan, dari dokumen bulan
/// yang disentuh periodenya saja — bukan seluruh riwayat (keputusan KT-1,
/// NFR-PERF-002). Transaksi hanya terhitung ke anggaran yang periodenya
/// mencakup tanggalnya, jadi bulan periode sudah cukup untuk angka yang tepat.
/// Penyaring bawaan "Aktif"; bulan anggaran selesai dan nonaktif baru dibaca
/// saat penyaringnya dipilih.
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
    on<BudgetStatusFilterChanged>((event, emit) => _showFiltered((s) => s.copyWith(statusFilter: event.filter), emit));
    on<BudgetWalletFilterChanged>(
      (event, emit) => _showFiltered((s) => s.copyWith(walletFilter: () => event.walletId), emit),
    );
  }

  final BudgetRepository _budgetRepository;
  final WalletRepository _walletRepository;
  final TransactionRepository _transactionRepository;
  final CalculateBudgetProgress _calculateProgress;
  final DateTime Function() _now;
  late final _readMonths = ReadTransactionsInMonths(_transactionRepository);

  /// Bulan buku besar yang isinya sudah ada di `state.transactions` sejak
  /// pemuatan terakhir.
  final Set<DateTime> _loadedMonths = {};

  /// Ekor antrean [_serial].
  Future<void> _queue = Future.value();

  /// Menjalankan [body] sesudah pemuatan atau penggantian penyaring
  /// sebelumnya selesai. Keduanya membaca bulan buku besar dan memancarkan
  /// state utuh; tanpa antrean, penyaring yang dipilih saat pemuatan masih
  /// berjalan tertimpa hasil pemuatan itu.
  Future<void> _serial(Future<void> Function() body) {
    final run = _queue.then((_) => body());
    _queue = run.then((_) {}, onError: (Object _) {});
    return run;
  }

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

  /// Membaca anggaran dan dompet, lalu menghitung progres anggaran yang
  /// ditampilkan pada saat [_now]. Progres yang sudah ada tetap dihitung
  /// ulang, supaya layar rincian yang sedang terbuka tidak kehilangan angkanya.
  Future<void> _load(
    Emitter<BudgetState> emit, {
    required BudgetState Function(Failure) onFailure,
    UiEffect? onSuccess,
  }) => _serial(() async {
    final budgets = await _budgetRepository.listBudgets();
    final wallets = await _walletRepository.listWallets();
    switch ((budgets, wallets)) {
      case (Right(value: final budgets), Right(value: final wallets)):
        final now = _now();
        _loadedMonths.clear();
        final next = state.copyWith(
          budgets: budgets,
          wallets: wallets,
          statuses: {for (final budget in budgets) budget.id: budget.statusAt(now)},
          transactions: const [],
        );
        switch (await _withProgress(next, now)) {
          case Left(value: final failure):
            emit(onFailure(failure));
          case Right(value: final loaded):
            emit(loaded.copyWith(isLoading: false, loadFailed: false, effect: onSuccess));
        }
      case (Left(value: final failure), _) || (_, Left(value: final failure)):
        emit(onFailure(failure));
    }
  });

  /// Menerapkan penyaring baru, membaca bulan yang belum dibaca kalau
  /// penyaring itu menampilkan anggaran lain.
  Future<void> _showFiltered(BudgetState Function(BudgetState) change, Emitter<BudgetState> emit) => _serial(() async {
    switch (await _withProgress(change(state), _now())) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _effectError(failure)));
      case Right(value: final updated):
        emit(updated);
    }
  });

  /// [next] dengan progres setiap anggaran yang dibutuhkan layar: yang aktif
  /// (ringkasan), yang lolos penyaring, dan yang progresnya sudah ada. Hanya
  /// bulan periode yang belum ada di [_loadedMonths] yang dibaca.
  Future<Either<Failure, BudgetState>> _withProgress(BudgetState next, DateTime now) async {
    final needed = [
      for (final budget in next.budgets)
        if (next.statuses[budget.id] == BudgetStatus.active ||
            next.passesFilters(budget) ||
            next.progress.containsKey(budget.id))
          budget,
    ];
    final missing = {for (final budget in needed) ...budget.months}.difference(_loadedMonths);
    var transactions = next.transactions;
    if (missing.isNotEmpty) {
      switch (await _readMonths(missing)) {
        case Left(:final value):
          return Left(value);
        case Right(:final value):
          _loadedMonths.addAll(missing);
          transactions = [...transactions, ...value];
      }
    }
    return Right(
      next.copyWith(
        transactions: transactions,
        progress: {for (final budget in needed) budget.id: _calculateProgress(budget, transactions, now: now)},
      ),
    );
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
