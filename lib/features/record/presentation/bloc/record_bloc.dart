import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/record/domain/budget_item_catalog.dart';
import 'package:saldough/features/record/presentation/bloc/record_state.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

part 'record_effect.dart';
part 'record_event.dart';

/// Bloc lembar CATAT — satu-satunya jalur pembuatan transaksi manual
/// (FR-REC-001). Memuat daftar dompet untuk pemilih tiap formulir, lalu
/// mendelegasikan penyimpanan tiga jenis transaksi ke [RecordTransaction]
/// dari `shared/transaction`, yang juga menjaga `Wallet.currentBalance`
/// tetap sesuai (ADR-012).
final class RecordBloc extends Bloc<RecordEvent, RecordState> {
  /// Membuat [RecordBloc].
  RecordBloc({required this._walletRepository, required this._recordTransaction, required this._budgetItemCatalog})
    : super(RecordState.initial()) {
    on<RecordWalletsLoaded>(_onWalletsLoaded);
    on<IncomeRecorded>(_onIncomeRecorded);
    on<ExpenseRecorded>(_onExpenseRecorded);
    on<TransferRecorded>(_onTransferRecorded);
  }

  final WalletRepository _walletRepository;
  final RecordTransaction _recordTransaction;
  final BudgetItemCatalog _budgetItemCatalog;

  Future<void> _onWalletsLoaded(RecordWalletsLoaded event, Emitter<RecordState> emit) async {
    emit(state.copyWith(isLoading: true));
    final result = await _walletRepository.listWallets();
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(isLoading: false, loadFailed: true, effect: _effectError(failure)));
      case Right(value: final wallets):
        // Pos anggaran adalah data sekunder: kegagalan membacanya tidak
        // boleh menghalangi pencatatan, cukup tanpa pilihan tautan anggaran.
        final budgetItems = (await _budgetItemCatalog.listOptions()).getOrElse((_) => const []);
        emit(
          state.copyWith(
            wallets: wallets.where((w) => w.isActive).toList(),
            budgetItems: budgetItems,
            isLoading: false,
            loadFailed: false,
          ),
        );
    }
  }

  Future<void> _onIncomeRecorded(IncomeRecorded event, Emitter<RecordState> emit) async {
    final transaction = IncomeTransaction(
      id: _newId(),
      date: event.date,
      amount: event.amount,
      note: event.note,
      categoryKey: event.categoryKey,
      walletId: event.walletId,
    );
    await _save(transaction, emit, _effectSaved(t.record.incomeSavedMessage));
  }

  Future<void> _onExpenseRecorded(ExpenseRecorded event, Emitter<RecordState> emit) async {
    final transaction = ExpenseTransaction(
      id: _newId(),
      date: event.date,
      amount: event.amount,
      note: event.note,
      categoryKey: event.categoryKey,
      walletId: event.walletId,
      budgetItemId: event.budgetItemId,
    );
    await _save(transaction, emit, _effectSaved(t.record.expenseSavedMessage));
  }

  Future<void> _onTransferRecorded(TransferRecorded event, Emitter<RecordState> emit) async {
    final transaction = TransferTransaction(
      id: _newId(),
      date: event.date,
      amount: event.amount,
      note: event.note,
      fromWalletId: event.fromWalletId,
      toWalletId: event.toWalletId,
      budgetItemId: event.budgetItemId,
    );
    await _save(transaction, emit, _effectSaved(t.record.transferSavedMessage));
  }

  Future<void> _save(Transaction transaction, Emitter<RecordState> emit, UiEffect onSaved) async {
    emit(state.copyWith(isSaving: true));
    final result = await _recordTransaction(transaction);
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(isSaving: false, effect: _effectError(failure)));
      case Right():
        emit(state.copyWith(isSaving: false, effect: onSaved));
    }
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();
}
