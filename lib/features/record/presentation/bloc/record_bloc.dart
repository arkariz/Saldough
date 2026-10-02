import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/features/record/domain/record_defaults.dart';
import 'package:saldough/features/record/presentation/bloc/record_state.dart';
import 'package:saldough/shared/budget_catalog/budget_catalog.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/recurring/recurring.dart';
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
  RecordBloc({
    required this._walletRepository,
    required this._transactionRepository,
    required this._recordTransaction,
    required this._budgetItemCatalog,
    required this._createCategory,
    required this._recurringRepository,
    required this._recurringChanges,
    this._now = DateTime.now,
  }) : super(RecordState.initial()) {
    on<RecordWalletsLoaded>(_onWalletsLoaded);
    on<IncomeRecorded>(_onIncomeRecorded);
    on<ExpenseRecorded>(_onExpenseRecorded);
    on<TransferRecorded>(_onTransferRecorded);
    on<RecordMadeRecurring>(_onMadeRecurring);
    on<RecordFailureOccurred>((event, emit) => emit(state.copyWith(effect: _effectError(event.failure))));
  }

  final WalletRepository _walletRepository;
  final TransactionRepository _transactionRepository;
  final RecordTransaction _recordTransaction;
  final BudgetItemCatalog _budgetItemCatalog;
  final CreateCategory _createCategory;
  final RecurringRuleRepository _recurringRepository;
  final RecurringChanges _recurringChanges;
  final DateTime Function() _now;

  /// Jumlah transaksi terbaru yang dibaca untuk isian bawaan.
  static const _recentLimit = 100;

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
        final active = wallets.where((w) => w.isActive).toList();
        // Isian bawaan juga data sekunder (UX-2, UX-3). Biayanya mengikuti
        // [_recentLimit], bukan panjang riwayat (NFR-PERF-002).
        final recent = (await _transactionRepository.listRecentTransactions(_recentLimit)).getOrElse((_) => const []);
        emit(
          state.copyWith(
            wallets: active,
            budgetItems: budgetItems,
            defaults: RecordDefaults.from(recent, activeWalletIds: {for (final w in active) w.id}),
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
      categoryId: event.categoryId,
      walletId: event.walletId,
      sourceIconId: event.sourceIconId,
    );
    await _saveOrSchedule(transaction, event.repeat, emit, _effectSaved(t.record.incomeSavedMessage));
  }

  Future<void> _onExpenseRecorded(ExpenseRecorded event, Emitter<RecordState> emit) async {
    final transaction = ExpenseTransaction(
      id: _newId(),
      date: event.date,
      amount: event.amount,
      note: event.note,
      categoryId: event.categoryId,
      walletId: event.walletId,
      budgetItemId: event.budgetItemId,
      sourceIconId: event.sourceIconId,
    );
    await _saveOrSchedule(transaction, event.repeat, emit, _effectSaved(t.record.expenseSavedMessage));
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
      sourceIconId: event.sourceIconId,
    );
    await _saveOrSchedule(transaction, event.repeat, emit, _effectSaved(t.record.transferSavedMessage));
  }

  /// Mencatat [transaction]; dengan [repeat], juga menyimpan rutinnya
  /// (ADR-034 §3.3, J2). Tanggal masa depan tidak pernah membuat transaksi:
  /// hanya rutinnya yang tersimpan ("Simpan Jadwal"). Rutin ditulis lebih
  /// dulu; kalau transaksinya gagal dicatat, rutin itu dihapus lagi supaya
  /// tidak ada rutin setengah jadi.
  Future<void> _saveOrSchedule(
    Transaction transaction,
    RecurringPattern? repeat,
    Emitter<RecordState> emit,
    UiEffect onSaved,
  ) async {
    if (repeat == null) return _save(transaction, emit, onSaved);
    emit(state.copyWith(isSaving: true));
    final rule = ruleFrom(transaction, repeat, id: _newId());
    if (await _recurringRepository.saveRule(rule) case Left(value: final failure)) {
      emit(state.copyWith(isSaving: false, effect: _effectError(failure)));
      return;
    }
    final anchor = rule.schedule.anchorDate;
    if (anchor.isAfter(_today)) {
      _recurringChanges.notifyChanged(source: this);
      emit(
        state.copyWith(
          isSaving: false,
          saveCount: state.saveCount + 1,
          effect: _effectSaved(
            t.record.repeat.scheduledMessage(name: _nameOf(rule), date: CycleMonthFormatter.formatDayMonth(anchor)),
          ),
        ),
      );
      return;
    }
    final linked = transaction.withRecurrence(RecurrenceLink(ruleId: rule.id, occurrenceDate: anchor));
    final result = await _recordTransaction(linked);
    switch (result) {
      case Left(value: final failure):
        await _recurringRepository.deleteRule(rule.id);
        emit(state.copyWith(isSaving: false, effect: _effectError(failure)));
      case Right():
        _recurringChanges.notifyChanged(source: this);
        emit(state.copyWith(isSaving: false, saveCount: state.saveCount + 1, effect: _effectRecordedAndScheduled(rule)));
    }
  }

  /// Jadikan Rutin: rutin baru yang kemunculan pertamanya adalah
  /// `event.source`. Hanya menautkan, tidak membuat transaksi baru.
  Future<void> _onMadeRecurring(RecordMadeRecurring event, Emitter<RecordState> emit) async {
    final recorded = event.recorded;
    final (Transaction? transaction, RecurringPattern? repeat) = switch (recorded) {
      IncomeRecorded(:final repeat?) => (_incomeFrom(recorded), repeat),
      ExpenseRecorded(:final repeat?) => (_expenseFrom(recorded), repeat),
      TransferRecorded(:final repeat?) => (_transferFrom(recorded), repeat),
      _ => (null, null),
    };
    if (transaction == null || repeat == null) return;
    emit(state.copyWith(isSaving: true));
    final rule = ruleFrom(transaction, repeat, id: _newId());
    if (await _recurringRepository.saveRule(rule) case Left(value: final failure)) {
      emit(state.copyWith(isSaving: false, effect: _effectError(failure)));
      return;
    }
    final linked = event.source.withRecurrence(RecurrenceLink(ruleId: rule.id, occurrenceDate: rule.schedule.anchorDate));
    final result = await _recordTransaction(linked, previousTransaction: event.source);
    switch (result) {
      case Left(value: final failure):
        await _recurringRepository.deleteRule(rule.id);
        emit(state.copyWith(isSaving: false, effect: _effectError(failure)));
      case Right():
        _recurringChanges.notifyChanged(source: this);
        emit(state.copyWith(isSaving: false, saveCount: state.saveCount + 1, effect: _effectRecordedAndScheduled(rule)));
    }
  }

  UiEffect _effectRecordedAndScheduled(RecurringRule rule) {
    final anchor = rule.schedule.anchorDate;
    final next = nextOccurrence(rule, DateTime(anchor.year, anchor.month, anchor.day + 1));
    return _effectSaved(
      next == null
          ? t.record.repeat.recordedMessage(name: _nameOf(rule))
          : t.record.repeat.recordedNextMessage(name: _nameOf(rule), date: CycleMonthFormatter.formatDayMonth(next)),
    );
  }

  String _nameOf(RecurringRule rule) => rule.note.isEmpty ? t.record.repeat.fallbackName : rule.note;

  DateTime get _today {
    final now = _now();
    return DateTime(now.year, now.month, now.day);
  }

  IncomeTransaction _incomeFrom(IncomeRecorded e) => IncomeTransaction(
    id: _newId(),
    date: e.date,
    amount: e.amount,
    note: e.note,
    categoryId: e.categoryId,
    walletId: e.walletId,
  );

  ExpenseTransaction _expenseFrom(ExpenseRecorded e) => ExpenseTransaction(
    id: _newId(),
    date: e.date,
    amount: e.amount,
    note: e.note,
    categoryId: e.categoryId,
    walletId: e.walletId,
  );

  TransferTransaction _transferFrom(TransferRecorded e) => TransferTransaction(
    id: _newId(),
    date: e.date,
    amount: e.amount,
    note: e.note,
    fromWalletId: e.fromWalletId,
    toWalletId: e.toWalletId,
  );

  Future<void> _save(Transaction transaction, Emitter<RecordState> emit, UiEffect onSaved) async {
    emit(state.copyWith(isSaving: true));
    final result = await _recordTransaction(transaction);
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(isSaving: false, effect: _effectError(failure)));
      case Right():
        emit(state.copyWith(isSaving: false, saveCount: state.saveCount + 1, effect: onSaved));
    }
  }

  /// "Tambah kategori" dari formulir CATAT maupun sunting (ADR-026 §3.6).
  ///
  /// Bukan event: formulir butuh kategori hasilnya untuk langsung
  /// memilihnya, dan membuat kategori tidak mengubah state CATAT (daftar
  /// kategori dibaca dari `ActiveCategories`, yang diperbarui repository).
  /// Gagal menyimpan ditampilkan lewat efek galat biasa dan mengembalikan
  /// `null`.
  Future<Category?> createCategory(CategoryKind kind, String name) async {
    final result = await _createCategory(kind, name);
    switch (result) {
      case Left(value: final failure):
        if (!isClosed) add(RecordFailureOccurred(failure));
        return null;
      case Right(value: final category):
        return category;
    }
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();
}

/// Rutin dari isian [transaction] dan pola [repeat]; tanggal transaksinya
/// menjadi patokan (kemunculan pertama).
RecurringRule ruleFrom(Transaction transaction, RecurringPattern repeat, {required String id}) => switch (transaction) {
  IncomeTransaction(:final walletId, :final categoryId) => repeat.toRule(
    id: id,
    kind: RecurringKind.income,
    amount: transaction.amount,
    walletId: walletId,
    categoryId: categoryId,
    note: transaction.note,
    anchorDate: transaction.date,
  ),
  ExpenseTransaction(:final walletId, :final categoryId) => repeat.toRule(
    id: id,
    kind: RecurringKind.expense,
    amount: transaction.amount,
    walletId: walletId,
    categoryId: categoryId,
    note: transaction.note,
    anchorDate: transaction.date,
  ),
  TransferTransaction(:final fromWalletId, :final toWalletId) => repeat.toRule(
    id: id,
    kind: RecurringKind.transfer,
    amount: transaction.amount,
    walletId: fromWalletId,
    toWalletId: toWalletId,
    note: transaction.note,
    anchorDate: transaction.date,
  ),
};
