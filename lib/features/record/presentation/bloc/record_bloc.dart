import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/language/language.dart';
import 'package:saldough/features/record/domain/record_defaults.dart';
import 'package:saldough/features/record/presentation/bloc/record_state.dart';
import 'package:saldough/features/record/presentation/capture/bloc/voice_capture_bloc.dart';
import 'package:saldough/shared/budget_catalog/budget_catalog.dart';
import 'package:saldough/shared/category/category.dart';
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
    this.voiceCaptureFactory,
    this.speechLanguagePrompt,
  }) : super(RecordState.initial()) {
    on<RecordWalletsLoaded>(_onWalletsLoaded);
    on<IncomeRecorded>(_onIncomeRecorded);
    on<ExpenseRecorded>(_onExpenseRecorded);
    on<TransferRecorded>(_onTransferRecorded);
    on<RecordFailureOccurred>((event, emit) => emit(state.copyWith(effect: _effectError(event.failure))));
  }

  final WalletRepository _walletRepository;
  final TransactionRepository _transactionRepository;
  final RecordTransaction _recordTransaction;
  final BudgetItemCatalog _budgetItemCatalog;
  final CreateCategory _createCategory;

  /// Membuat [VoiceCaptureBloc] baru untuk satu lembar rekam Catat Cerdas
  /// (ADR-027). `null` berarti tombol suara tidak ditawarkan di CATAT.
  final VoiceCaptureBloc Function()? voiceCaptureFactory;

  /// Pertanyaan bahasa ucapan sekali sebelum lembar rekam pertama (ADR-028
  /// §3.8), atau `null`.
  final SpeechLanguagePrompt? speechLanguagePrompt;

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
    );
    await _save(transaction, emit, _effectSaved(t.record.incomeSavedMessage));
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
