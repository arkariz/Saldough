import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/cycle/domain/entities/budget_line.dart';
import 'package:saldough/features/cycle/domain/entities/income_line.dart';
import 'package:saldough/features/cycle/domain/entities/monthly_cycle.dart';
import 'package:saldough/features/cycle/domain/entities/roll_up_source.dart';
import 'package:saldough/features/cycle/domain/repositories/card_catalog.dart';
import 'package:saldough/features/cycle/domain/repositories/cycle_repository.dart';
import 'package:saldough/features/cycle/domain/repositories/cycle_template_repository.dart';
import 'package:saldough/features/cycle/domain/usecases/roll_over_cycle.dart';
import 'package:saldough/features/cycle/presentation/bloc/cycle_state.dart';
import 'package:saldough/shared/income/income.dart';
import 'package:state_management/state_management.dart';

part 'cycle_effect.dart';
part 'cycle_event.dart';

/// Bloc layar siklus bulanan. Lihat ARCHITECTURE_OVERVIEW.md bagian
/// "Menulis satu fitur" — pola ini diikuti persis.
///
/// Helper transisi state dan getter turunan ([totals]/[unreviewedCount])
/// hidup di [CycleState] ([CycleState.withCycle]), bukan di sini — bloc ini
/// murni mengorkestrasi use case dan repository.
final class CycleBloc extends Bloc<CycleEvent, CycleState> {
  /// Membuat [CycleBloc].
  CycleBloc({
    required this._cycleRepository,
    required this._templateRepository,
    required this._rollOverCycle,
    required this._sourceRepository,
    required this._cardCatalog,
  }) : super(CycleState.initial()) {
    on<CycleOpened>(_onOpened);
    on<IncomeLineSaved>(_onIncomeLineSaved);
    on<IncomeLineRemoved>(_onIncomeLineRemoved);
    on<BudgetLineSaved>(_onBudgetLineSaved);
    on<BudgetLineRemoved>(_onBudgetLineRemoved);
    on<IncomeLineTemplateToggled>(_onIncomeLineTemplateToggled);
    on<BudgetLineTemplateToggled>(_onBudgetLineTemplateToggled);
    on<IncomeLineReviewed>(
      (event, emit) => _updateIncomeLine(
        emit,
        event.lineId,
        (line) => line.copyWith(needsReview: false),
      ),
    );
    on<BudgetLineReviewed>(
      (event, emit) => _updateBudgetLine(
        emit,
        event.lineId,
        (line) => line.copyWith(needsReview: false),
      ),
    );
    on<CycleRollOverRequested>(_onRollOverRequested);
    on<CycleClosed>(_onClosed);
    on<CycleReopened>(_onReopened);
    on<CycleDeleteRequested>(_onDeleteRequested);
    on<CycleIncomeSourcesRefreshRequested>(_onIncomeSourcesRefreshRequested);
  }

  final CycleRepository _cycleRepository;
  final CycleTemplateRepository _templateRepository;
  final RollOverCycle _rollOverCycle;
  final IncomeSourceRepository _sourceRepository;
  final CardCatalog _cardCatalog;

  Future<void> _onOpened(CycleOpened event, Emitter<CycleState> emit) =>
      _loadCycle(event.cycleId, emit);

  Future<void> _loadCycle(String cycleId, Emitter<CycleState> emit) async {
    emit(state.copyWith(isLoading: true));
    final sourcesResult = await _sourceRepository.listSources();
    final sources = sourcesResult.getOrElse((_) => const []);
    final existingIds = await _listCycleIds();
    final cards = await _listCards();

    final result = await _cycleRepository.getCycle(cycleId);
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(isLoading: false, effect: _effectError(failure)));
      case Right(value: final cycle):
        emit(
          state
              .withCycle(
                cycle ?? .empty(cycleId),
                existingCycleIds: existingIds,
                cards: cards,
              )
              .copyWith(incomeSources: sources),
        );
    }
  }

  Future<void> _onIncomeSourcesRefreshRequested(
    CycleIncomeSourcesRefreshRequested event,
    Emitter<CycleState> emit,
  ) async {
    final result = await _sourceRepository.listSources();
    emit(state.copyWith(incomeSources: result.getOrElse((_) => const [])));
  }

  Future<List<CardSummary>> _listCards() async {
    final result = await _cardCatalog.listCards();
    return result.getOrElse((_) => const []);
  }

  Future<List<String>> _listCycleIds() async {
    final result = await _cycleRepository.listCycleIds();
    return result.getOrElse((_) => const []);
  }

  Future<void> _onDeleteRequested(
    CycleDeleteRequested event,
    Emitter<CycleState> emit,
  ) async {
    if (!state.canDeleteCycle) return;
    final deletedId = state.cycle.id;
    emit(state.copyWith(isLoading: true));
    final result = await _cycleRepository.deleteCycle(deletedId);
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(isLoading: false, effect: _effectError(failure)));
      case Right():
        final remainingIds = await _listCycleIds();
        await _loadCycle(
          remainingIds.isEmpty ? deletedId : remainingIds.last,
          emit,
        );
    }
  }

  Future<void> _onIncomeLineSaved(
    IncomeLineSaved event,
    Emitter<CycleState> emit,
  ) async {
    final existing = event.id == null ? null : state.findIncomeLine(event.id!);
    final line = IncomeLine(
      id: event.id ?? _freshId(),
      label: event.label,
      amount: event.amount,
      sourceId: event.sourceId,
      isTemplate: existing?.isTemplate ?? false,
      needsReview: existing?.needsReview ?? false,
    );
    final lines = [
      ...state.cycle.incomeLines.where((l) => l.id != line.id),
      line,
    ];
    await _saveAndEmit(emit, state.cycle.copyWith(incomeLines: lines));
  }

  Future<void> _onIncomeLineRemoved(
    IncomeLineRemoved event,
    Emitter<CycleState> emit,
  ) async {
    final lines = state.cycle.incomeLines
        .where((l) => l.id != event.id)
        .toList();
    await _saveAndEmit(emit, state.cycle.copyWith(incomeLines: lines));
  }

  Future<void> _onBudgetLineSaved(
    BudgetLineSaved event,
    Emitter<CycleState> emit,
  ) async {
    final isNew = event.id == null;
    final existing = isNew ? null : state.findBudgetLine(event.id!);
    if (existing != null && existing.kind == .rollUp) {
      emit(state.copyWith(effect: _effectRollUpNotEditable()));
      return;
    }
    // `rollUpSource` hanya berlaku untuk baris BARU — menautkan baris yang
    // sudah ada ke sumber roll-up tidak didukung (penyuntingan baris rollUp
    // sudah ditolak di atas), jadi diamkan kalau UI keliru mengirimkannya
    // bersama `id` baris lama.
    final rollUpSource = isNew ? event.rollUpSource : null;
    // Satu sumber roll-up (Rencana Belanja, atau satu kartu tertentu) hanya
    // boleh ditautkan ke SATU baris anggaran — kalau tidak, baris anggaran
    // jadi duplikat hitungan yang sama (laporan pemilik). Kartu yang
    // berbeda tetap boleh masing-masing punya baris sendiri. Ini jaring
    // pengaman lapis kedua — `LineEditSheet` sudah menonaktifkan pilihan
    // yang terpakai di UI, tapi bloc tidak boleh ikut percaya begitu saja.
    if (rollUpSource != null &&
        state.cycle.budgetLines.any(
          (l) => l.kind == .rollUp && l.rollUpSource == rollUpSource,
        )) {
      emit(state.copyWith(effect: _effectRollUpSourceAlreadyUsed()));
      return;
    }
    final line = BudgetLine(
      id: event.id ?? _freshId(),
      label: event.label,
      // Sama seperti `RollOverCycle` mengisi baris rollUp baru: nominal
      // sungguhan dihitung ulang dari sumbernya, bukan dari input pemilik —
      // lihat penyegaran lewat `_cycleRepository.getCycle` di bawah.
      amount: rollUpSource == null ? event.amount : 0,
      kind: rollUpSource == null ? .manual : .rollUp,
      rollUpSource: rollUpSource,
      isTemplate: existing?.isTemplate ?? false,
      needsReview: existing?.needsReview ?? false,
    );
    final lines = [
      ...state.cycle.budgetLines.where((l) => l.id != line.id),
      line,
    ];
    await _saveAndEmit(emit, state.cycle.copyWith(budgetLines: lines));
    if (rollUpSource != null) {
      await _refreshRollUpAmounts(emit);
    }
  }

  /// Membaca ulang siklus lewat [_cycleRepository] supaya nominal baris
  /// rollUp yang baru ditautkan langsung menyegarkan angkanya (bukan `Rp 0`
  /// sampai pemilik pindah dan kembali) — lihat catatan [_onBudgetLineSaved].
  Future<void> _refreshRollUpAmounts(Emitter<CycleState> emit) async {
    final result = await _cycleRepository.getCycle(state.cycle.id);
    final resolved = result.getOrElse((_) => null);
    if (resolved != null) {
      emit(state.withCycle(resolved, existingCycleIds: state.existingCycleIds));
    }
  }

  Future<void> _onBudgetLineRemoved(
    BudgetLineRemoved event,
    Emitter<CycleState> emit,
  ) async {
    final lines = state.cycle.budgetLines
        .where((l) => l.id != event.id)
        .toList();
    await _saveAndEmit(emit, state.cycle.copyWith(budgetLines: lines));
  }

  Future<void> _onIncomeLineTemplateToggled(
    IncomeLineTemplateToggled event,
    Emitter<CycleState> emit,
  ) async {
    final line = state.findIncomeLine(event.lineId);
    if (line == null) return;
    final toggled = line.copyWith(isTemplate: !line.isTemplate);
    final syncFailure = await _syncIncomeTemplate(toggled);
    // Kalau template gagal ditulis, JANGAN lanjut menyunting baris siklus --
    // itu akan membuat pin di layar terlihat berhasil padahal baris tidak
    // ikut terbawa saat rollover bulan depan, tanpa pemilik pernah tahu
    // (UX-06). Batalkan keduanya sekaligus dan tunjukkan galatnya.
    if (syncFailure != null) {
      emit(state.copyWith(effect: _effectError(syncFailure)));
      return;
    }
    await _updateIncomeLine(emit, event.lineId, (_) => toggled);
  }

  Future<void> _onBudgetLineTemplateToggled(
    BudgetLineTemplateToggled event,
    Emitter<CycleState> emit,
  ) async {
    final line = state.findBudgetLine(event.lineId);
    if (line == null) return;
    final toggled = line.copyWith(isTemplate: !line.isTemplate);
    final syncFailure = await _syncBudgetTemplate(toggled);
    if (syncFailure != null) {
      emit(state.copyWith(effect: _effectError(syncFailure)));
      return;
    }
    await _updateBudgetLine(emit, event.lineId, (_) => toggled);
  }

  /// Mendaftarkan/melepas [line] dari `CycleTemplate` — menandai baris
  /// sebagai tetap adalah tindakan sadar yang mendaftarkannya ke template
  /// untuk rollover berikutnya (ADR-0008), bukan cuma penanda lokal.
  ///
  /// Mengembalikan `null` kalau penulisan template berhasil, atau
  /// [Failure]-nya kalau gagal — pembacaan template (`getTemplate`) TETAP
  /// memakai `getOrElse` di sini (bukan bagian UX-06; lihat BUG-3 di
  /// `UX_REVIEW_FIXES.md` untuk masalah terpisah pada pembacaannya).
  Future<Failure?> _syncIncomeTemplate(IncomeLine line) async {
    final result = await _templateRepository.getTemplate();
    final template = result.getOrElse((_) => .empty());
    final lines = [
      ...template.incomeLines.where((l) => l.id != line.id),
      if (line.isTemplate) line.copyWith(needsReview: false),
    ];
    final saveResult = await _templateRepository.saveTemplate(
      template.copyWith(incomeLines: lines),
    );
    return switch (saveResult) {
      Left(value: final failure) => failure,
      Right() => null,
    };
  }

  Future<Failure?> _syncBudgetTemplate(BudgetLine line) async {
    final result = await _templateRepository.getTemplate();
    final template = result.getOrElse((_) => .empty());
    final lines = [
      ...template.budgetLines.where((l) => l.id != line.id),
      if (line.isTemplate) line.copyWith(needsReview: false),
    ];
    final saveResult = await _templateRepository.saveTemplate(
      template.copyWith(budgetLines: lines),
    );
    return switch (saveResult) {
      Left(value: final failure) => failure,
      Right() => null,
    };
  }

  Future<void> _onRollOverRequested(
    CycleRollOverRequested event,
    Emitter<CycleState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    final result = await _rollOverCycle(state.cycle.id);
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(isLoading: false, effect: _effectError(failure)));
      case Right(value: final next):
        final existingIds = await _listCycleIds();
        emit(
          state.withCycle(
            next,
            existingCycleIds: existingIds,
            effect: _effectCycleCreated(next.id),
          ),
        );
    }
  }

  Future<void> _onClosed(CycleClosed event, Emitter<CycleState> emit) async {
    await _saveAndEmit(emit, state.cycle.close());
  }

  Future<void> _onReopened(
    CycleReopened event,
    Emitter<CycleState> emit,
  ) async {
    // Tidak lewat _saveAndEmit: itu justru MENOLAK penyuntingan saat siklus
    // masih terkunci — dan membuka kembali kuncinya, secara sadar, adalah
    // tepat apa yang dilakukan aksi ini (ADR-0008).
    final reopened = state.cycle.reopen();
    final result = await _cycleRepository.saveCycle(reopened);
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _effectError(failure)));
      case Right():
        emit(state.withCycle(reopened));
    }
  }

  Future<void> _updateIncomeLine(
    Emitter<CycleState> emit,
    String lineId,
    IncomeLine Function(IncomeLine) update,
  ) async {
    final lines = state.cycle.incomeLines
        .map((l) => l.id == lineId ? update(l) : l)
        .toList();
    await _saveAndEmit(emit, state.cycle.copyWith(incomeLines: lines));
  }

  Future<void> _updateBudgetLine(
    Emitter<CycleState> emit,
    String lineId,
    BudgetLine Function(BudgetLine) update,
  ) async {
    final lines = state.cycle.budgetLines
        .map((l) => l.id == lineId ? update(l) : l)
        .toList();
    await _saveAndEmit(emit, state.cycle.copyWith(budgetLines: lines));
  }

  Future<void> _saveAndEmit(
    Emitter<CycleState> emit,
    MonthlyCycle cycle,
  ) async {
    if (state.cycle.isClosed) {
      emit(state.copyWith(effect: _effectCycleClosed()));
      return;
    }
    final result = await _cycleRepository.saveCycle(cycle);
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _effectError(failure)));
      case Right():
        // Baris pertama yang ditambah ke siklus yang sebelumnya belum ada
        // (lihat `CycleOpened`) adalah yang benar-benar membuatnya — daftar
        // `existingCycleIds` perlu ikut diperbarui supaya chevron navigasi
        // langsung membuka untuk siklus ini juga.
        final ids = state.existingCycleIds.contains(cycle.id)
            ? state.existingCycleIds
            : await _listCycleIds();
        emit(state.withCycle(cycle, existingCycleIds: ids));
    }
  }

  String _freshId() => DateTime.now().microsecondsSinceEpoch.toString();
}
