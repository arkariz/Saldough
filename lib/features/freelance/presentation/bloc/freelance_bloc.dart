import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/freelance/domain/entities/deduction_rule.dart';
import 'package:saldough/features/freelance/domain/entities/freelance_payment.dart';
import 'package:saldough/features/freelance/domain/entities/freelance_project.dart';
import 'package:saldough/features/freelance/domain/entities/worklog_entry.dart';
import 'package:saldough/features/freelance/domain/repositories/freelance_repository.dart';
import 'package:saldough/features/freelance/domain/usecases/receive_freelance_payment.dart';
import 'package:saldough/features/freelance/presentation/bloc/freelance_state.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

part 'freelance_effect.dart';
part 'freelance_event.dart';

/// Bloc Ikhtisar Freelance (FR-FRL-001..005): proyek, worklog, pembayaran,
/// dan pencatatan pembayaran diterima.
///
/// ⚠ Hanya [FreelancePaymentReceived] dan [FreelanceReceiptCancelled] yang
/// menyentuh saldo, lewat [ReceiveFreelancePayment]. Proyek, worklog, dan
/// pembayaran tertunda tidak pernah mengubah saldo dompet mana pun (aturan 6
/// CLAUDE.md).
///
/// Penulisan dua dokumen berurutan supaya kegagalan di tengah tidak pernah
/// menagihkan satu entri dua kali: membuat pembayaran menandai entrinya
/// lebih dulu, menghapus pembayaran menghapus pembayarannya lebih dulu.
/// `paymentId` yang menunjuk pembayaran yang tidak ada dibaca sebagai belum
/// ditagihkan (lihat [FreelanceState.paymentOf]).
final class FreelanceBloc extends Bloc<FreelanceEvent, FreelanceState> {
  /// Membuat [FreelanceBloc].
  FreelanceBloc({
    required this._freelanceRepository,
    required this._walletRepository,
    required this._receivePayment,
  }) : super(FreelanceState.initial()) {
    on<FreelanceStarted>(_onStarted);
    on<FreelanceProjectAdded>(_onProjectAdded);
    on<FreelanceProjectEdited>(_onProjectEdited);
    on<FreelanceProjectDeleted>(_onProjectDeleted);
    on<FreelanceEntryAdded>(_onEntryAdded);
    on<FreelanceEntryEdited>(_onEntryEdited);
    on<FreelanceEntryDeleted>(_onEntryDeleted);
    on<FreelancePaymentCreated>(_onPaymentCreated);
    on<FreelancePaymentDateChanged>(_onPaymentDateChanged);
    on<FreelancePaymentDeleted>(_onPaymentDeleted);
    on<FreelancePaymentReceived>(_onPaymentReceived);
    on<FreelanceReceiptCancelled>(_onReceiptCancelled);
  }

  final FreelanceRepository _freelanceRepository;
  final WalletRepository _walletRepository;
  final ReceiveFreelancePayment _receivePayment;

  static String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  Future<void> _onStarted(FreelanceStarted event, Emitter<FreelanceState> emit) async {
    emit(state.copyWith(isLoading: true, loadFailed: false));
    await _load(
      emit,
      onFailure: (failure) => state.copyWith(isLoading: false, loadFailed: true, effect: _effectError(failure)),
    );
  }

  Future<void> _onProjectAdded(FreelanceProjectAdded event, Emitter<FreelanceState> emit) async {
    final project = FreelanceProject(
      id: _newId(),
      name: event.name.trim(),
      hourlyRate: event.hourlyRate,
      deductionRules: event.deductionRules,
    );
    await _afterWrite(await _freelanceRepository.saveProject(project), t.freelance.projectSavedMessage, emit);
  }

  Future<void> _onProjectEdited(FreelanceProjectEdited event, Emitter<FreelanceState> emit) async {
    await _afterWrite(await _freelanceRepository.saveProject(event.project), t.freelance.projectUpdatedMessage, emit);
  }

  Future<void> _onProjectDeleted(FreelanceProjectDeleted event, Emitter<FreelanceState> emit) async {
    if (state.projectHasEntries(event.project)) {
      emit(state.copyWith(effect: _effectRefused(t.freelance.projectDeleteRefused)));
      return;
    }
    await _afterWrite(
      await _freelanceRepository.deleteProject(event.project.id),
      t.freelance.projectDeletedMessage,
      emit,
    );
  }

  Future<void> _onEntryAdded(FreelanceEntryAdded event, Emitter<FreelanceState> emit) async {
    final note = event.note?.trim();
    final entry = WorklogEntry(
      id: _newId(),
      projectId: event.projectId,
      date: event.date,
      hours: event.hours,
      hourlyRate: event.hourlyRate,
      note: note == null || note.isEmpty ? null : note,
    );
    await _afterWrite(await _freelanceRepository.saveEntries([entry]), t.freelance.entrySavedMessage, emit);
  }

  Future<void> _onEntryEdited(FreelanceEntryEdited event, Emitter<FreelanceState> emit) async {
    if (_isBilled(event.entry.id)) {
      emit(state.copyWith(effect: _effectRefused(t.freelance.entryLockedMessage)));
      return;
    }
    // `paymentId` yang basi (pembayarannya sudah tidak ada) dibersihkan.
    final entry = event.entry.copyWith(paymentId: () => null);
    await _afterWrite(await _freelanceRepository.saveEntries([entry]), t.freelance.entryUpdatedMessage, emit);
  }

  Future<void> _onEntryDeleted(FreelanceEntryDeleted event, Emitter<FreelanceState> emit) async {
    if (_isBilled(event.entry.id)) {
      emit(state.copyWith(effect: _effectRefused(t.freelance.entryLockedMessage)));
      return;
    }
    await _afterWrite(await _freelanceRepository.deleteEntry(event.entry.id), t.freelance.entryDeletedMessage, emit);
  }

  Future<void> _onPaymentCreated(FreelancePaymentCreated event, Emitter<FreelanceState> emit) async {
    final project = state.projectOf(event.projectId);
    final unbilled = {for (final entry in state.unbilledEntriesOf(event.projectId)) entry.id: entry};
    final entries = [for (final id in event.entryIds) ?unbilled[id]];
    if (project == null || entries.isEmpty || entries.length != event.entryIds.length) {
      emit(state.copyWith(effect: _effectRefused(t.freelance.paymentEntriesInvalid)));
      return;
    }
    final payment = FreelancePayment(
      id: _newId(),
      projectId: project.id,
      entryIds: [for (final entry in entries) entry.id],
      expectedDate: event.expectedDate,
      deductionRules: project.deductionRules,
    );
    final marked = await _freelanceRepository.saveEntries([
      for (final entry in entries) entry.copyWith(paymentId: () => payment.id),
    ]);
    if (marked case Left(value: final failure)) {
      emit(state.copyWith(effect: _effectError(failure)));
      return;
    }
    await _afterWrite(await _freelanceRepository.savePayment(payment), t.freelance.paymentCreatedMessage, emit);
  }

  Future<void> _onPaymentDateChanged(FreelancePaymentDateChanged event, Emitter<FreelanceState> emit) async {
    final payment = _current(event.payment);
    if (payment == null) return;
    await _afterWrite(
      await _freelanceRepository.savePayment(payment.withExpectedDate(event.expectedDate)),
      t.freelance.paymentUpdatedMessage,
      emit,
    );
  }

  Future<void> _onPaymentDeleted(FreelancePaymentDeleted event, Emitter<FreelanceState> emit) async {
    final payment = _current(event.payment);
    if (payment == null) return;
    if (payment.isPaid) {
      emit(state.copyWith(effect: _effectRefused(t.freelance.paymentPaidLocked)));
      return;
    }
    final entries = state.entriesOf(payment);
    final deleted = await _freelanceRepository.deletePayment(payment.id);
    if (deleted case Left(value: final failure)) {
      emit(state.copyWith(effect: _effectError(failure)));
      return;
    }
    await _afterWrite(
      await _freelanceRepository.saveEntries([for (final entry in entries) entry.copyWith(paymentId: () => null)]),
      t.freelance.paymentDeletedMessage,
      emit,
    );
  }

  Future<void> _onPaymentReceived(FreelancePaymentReceived event, Emitter<FreelanceState> emit) async {
    final payment = _current(event.payment);
    if (payment == null) return;
    if (payment.isPaid) {
      emit(state.copyWith(effect: _effectRefused(t.freelance.paymentAlreadyPaid)));
      return;
    }
    final netPay = state.breakdownOf(payment).netPay;
    if (netPay <= 0) {
      emit(state.copyWith(effect: _effectRefused(t.freelance.netPayNotPositive)));
      return;
    }
    await _afterWrite(
      await _receivePayment(
        payment: payment,
        netPay: netPay,
        walletId: event.walletId,
        date: event.date,
        note: event.note.trim(),
      ),
      t.freelance.paymentReceivedMessage,
      emit,
    );
  }

  Future<void> _onReceiptCancelled(FreelanceReceiptCancelled event, Emitter<FreelanceState> emit) async {
    final payment = _current(event.payment);
    if (payment == null || !payment.isPaid) return;
    await _afterWrite(
      await _receivePayment.undo(payment: payment, netPay: state.breakdownOf(payment).netPay),
      t.freelance.receiptCancelledMessage,
      emit,
    );
  }

  /// Versi terbaru [payment] di state — pemanggil bisa memegang salinan
  /// yang sudah basi (mis. layar rincian yang dibuka sebelum pembaruan).
  FreelancePayment? _current(FreelancePayment payment) => state.payments.where((p) => p.id == payment.id).firstOrNull;

  bool _isBilled(String entryId) {
    final current = state.entries.where((e) => e.id == entryId).firstOrNull;
    return current != null && state.paymentOf(current) != null;
  }

  Future<void> _load(
    Emitter<FreelanceState> emit, {
    required FreelanceState Function(Failure) onFailure,
    UiEffect? onSuccess,
  }) async {
    final projects = await _freelanceRepository.listProjects();
    final entries = await _freelanceRepository.listEntries();
    final payments = await _freelanceRepository.listPayments();
    final wallets = await _walletRepository.listWallets();
    switch ((projects, entries, payments, wallets)) {
      case (
        Right(value: final projects),
        Right(value: final entries),
        Right(value: final payments),
        Right(value: final wallets),
      ):
        emit(
          state.copyWith(
            projects: projects,
            entries: entries,
            payments: payments,
            wallets: wallets,
            isLoading: false,
            loadFailed: false,
            effect: onSuccess,
          ),
        );
      case (Left(value: final failure), _, _, _) ||
          (_, Left(value: final failure), _, _) ||
          (_, _, Left(value: final failure), _) ||
          (_, _, _, Left(value: final failure)):
        emit(onFailure(failure));
    }
  }

  /// Sesudah menulis: kalau gagal, tampilkan galat; kalau berhasil, muat
  /// ulang lalu tampilkan pesan berhasil.
  Future<void> _afterWrite(Either<Failure, Unit> result, String successMessage, Emitter<FreelanceState> emit) async {
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _effectError(failure)));
        // Muat ulang juga: sebagian penulisan mungkin sudah berhasil.
        await _load(emit, onFailure: (_) => state);
      case Right():
        await _load(
          emit,
          onFailure: (failure) => state.copyWith(effect: _effectError(failure)),
          onSuccess: _effectSaved(successMessage),
        );
    }
  }
}
