import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/cycle/domain/entities/budget_line.dart';
import 'package:saldough/features/cycle/domain/entities/budget_line_kind.dart';
import 'package:saldough/features/cycle/domain/entities/cycle_template.dart';
import 'package:saldough/features/cycle/domain/entities/income_line.dart';
import 'package:saldough/features/cycle/domain/entities/monthly_cycle.dart';
import 'package:saldough/features/cycle/domain/repositories/cycle_repository.dart';
import 'package:saldough/features/cycle/domain/repositories/cycle_template_repository.dart';
import 'package:saldough/features/cycle/domain/usecases/calculate_cycle_totals.dart';
import 'package:saldough/features/cycle/domain/usecases/roll_over_cycle.dart';
import 'package:saldough/features/cycle/presentation/bloc/cycle_state.dart';
import 'package:state_management/state_management.dart';

part 'cycle_effect.dart';
part 'cycle_event.dart';

/// Bloc layar siklus bulanan. Lihat ARCHITECTURE_OVERVIEW.md bagian
/// "Menulis satu fitur" — pola ini diikuti persis.
final class CycleBloc extends Bloc<CycleEvent, CycleState> {
  /// Membuat [CycleBloc].
  CycleBloc({
    required CycleRepository cycleRepository,
    required CycleTemplateRepository templateRepository,
    required RollOverCycle rollOverCycle,
  })  : _cycleRepository = cycleRepository,
        _templateRepository = templateRepository,
        _rollOverCycle = rollOverCycle,
        _calculateTotals = CalculateCycleTotals(),
        super(CycleState.initial()) {
    on<CycleOpened>(_onOpened);
    on<IncomeLineSaved>(_onIncomeLineSaved);
    on<IncomeLineRemoved>(_onIncomeLineRemoved);
    on<BudgetLineSaved>(_onBudgetLineSaved);
    on<BudgetLineRemoved>(_onBudgetLineRemoved);
    on<IncomeLineTemplateToggled>(_onIncomeLineTemplateToggled);
    on<BudgetLineTemplateToggled>(_onBudgetLineTemplateToggled);
    on<IncomeLineReviewed>((event, emit) => _updateIncomeLine(
          emit,
          event.lineId,
          (line) => line.copyWith(needsReview: false),
        ));
    on<BudgetLineReviewed>((event, emit) => _updateBudgetLine(
          emit,
          event.lineId,
          (line) => line.copyWith(needsReview: false),
        ));
    on<CycleRollOverRequested>(_onRollOverRequested);
    on<CycleClosed>(_onClosed);
    on<CycleReopened>(_onReopened);
  }

  final CycleRepository _cycleRepository;
  final CycleTemplateRepository _templateRepository;
  final RollOverCycle _rollOverCycle;
  final CalculateCycleTotals _calculateTotals;

  Future<void> _onOpened(CycleOpened event, Emitter<CycleState> emit) async {
    emit(state.copyWith(isLoading: true));
    final result = await _cycleRepository.getCycle(event.cycleId);
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(isLoading: false, effect: _effectError(failure)));
      case Right(value: final cycle):
        _emitCycle(emit, cycle ?? MonthlyCycle.empty(event.cycleId), isLoading: false);
    }
  }

  Future<void> _onIncomeLineSaved(IncomeLineSaved event, Emitter<CycleState> emit) async {
    final existing = event.id == null ? null : _findIncomeLine(event.id!);
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

  Future<void> _onIncomeLineRemoved(IncomeLineRemoved event, Emitter<CycleState> emit) async {
    final lines = state.cycle.incomeLines.where((l) => l.id != event.id).toList();
    await _saveAndEmit(emit, state.cycle.copyWith(incomeLines: lines));
  }

  Future<void> _onBudgetLineSaved(BudgetLineSaved event, Emitter<CycleState> emit) async {
    final isNew = event.id == null;
    final existing = isNew ? null : _findBudgetLine(event.id!);
    if (existing != null && existing.kind == BudgetLineKind.rollUp) {
      emit(state.copyWith(effect: _effectRollUpNotEditable()));
      return;
    }
    final line = BudgetLine(
      id: event.id ?? _freshId(),
      label: event.label,
      amount: event.amount,
      kind: BudgetLineKind.manual,
      isTemplate: existing?.isTemplate ?? false,
      needsReview: existing?.needsReview ?? false,
    );
    final lines = [
      ...state.cycle.budgetLines.where((l) => l.id != line.id),
      line,
    ];
    await _saveAndEmit(emit, state.cycle.copyWith(budgetLines: lines));
  }

  Future<void> _onBudgetLineRemoved(BudgetLineRemoved event, Emitter<CycleState> emit) async {
    final lines = state.cycle.budgetLines.where((l) => l.id != event.id).toList();
    await _saveAndEmit(emit, state.cycle.copyWith(budgetLines: lines));
  }

  Future<void> _onIncomeLineTemplateToggled(
    IncomeLineTemplateToggled event,
    Emitter<CycleState> emit,
  ) async {
    final line = _findIncomeLine(event.lineId);
    if (line == null) return;
    final toggled = line.copyWith(isTemplate: !line.isTemplate);
    await _syncIncomeTemplate(toggled);
    await _updateIncomeLine(emit, event.lineId, (_) => toggled);
  }

  Future<void> _onBudgetLineTemplateToggled(
    BudgetLineTemplateToggled event,
    Emitter<CycleState> emit,
  ) async {
    final line = _findBudgetLine(event.lineId);
    if (line == null) return;
    final toggled = line.copyWith(isTemplate: !line.isTemplate);
    await _syncBudgetTemplate(toggled);
    await _updateBudgetLine(emit, event.lineId, (_) => toggled);
  }

  /// Mendaftarkan/melepas [line] dari `CycleTemplate` — menandai baris
  /// sebagai tetap adalah tindakan sadar yang mendaftarkannya ke template
  /// untuk rollover berikutnya (ADR-0008), bukan cuma penanda lokal.
  Future<void> _syncIncomeTemplate(IncomeLine line) async {
    final result = await _templateRepository.getTemplate();
    final template = result.getOrElse((_) => CycleTemplate.empty());
    final lines = [
      ...template.incomeLines.where((l) => l.id != line.id),
      if (line.isTemplate) line.copyWith(needsReview: false),
    ];
    await _templateRepository.saveTemplate(template.copyWith(incomeLines: lines));
  }

  Future<void> _syncBudgetTemplate(BudgetLine line) async {
    final result = await _templateRepository.getTemplate();
    final template = result.getOrElse((_) => CycleTemplate.empty());
    final lines = [
      ...template.budgetLines.where((l) => l.id != line.id),
      if (line.isTemplate) line.copyWith(needsReview: false),
    ];
    await _templateRepository.saveTemplate(template.copyWith(budgetLines: lines));
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
        _emitCycle(emit, next, isLoading: false, effect: _effectCycleCreated(next.id));
    }
  }

  Future<void> _onClosed(CycleClosed event, Emitter<CycleState> emit) async {
    await _saveAndEmit(emit, state.cycle.close());
  }

  Future<void> _onReopened(CycleReopened event, Emitter<CycleState> emit) async {
    // Tidak lewat _saveAndEmit: itu justru MENOLAK penyuntingan saat siklus
    // masih terkunci — dan membuka kembali kuncinya, secara sadar, adalah
    // tepat apa yang dilakukan aksi ini (ADR-0008).
    final reopened = state.cycle.reopen();
    final result = await _cycleRepository.saveCycle(reopened);
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _effectError(failure)));
      case Right():
        _emitCycle(emit, reopened, isLoading: false);
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

  Future<void> _saveAndEmit(Emitter<CycleState> emit, MonthlyCycle cycle) async {
    if (state.cycle.isClosed) {
      emit(state.copyWith(effect: _effectCycleClosed()));
      return;
    }
    final result = await _cycleRepository.saveCycle(cycle);
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _effectError(failure)));
      case Right():
        _emitCycle(emit, cycle, isLoading: false);
    }
  }

  void _emitCycle(
    Emitter<CycleState> emit,
    MonthlyCycle cycle, {
    required bool isLoading,
    UiEffect? effect,
  }) {
    final unreviewed = cycle.incomeLines.where((l) => l.needsReview).length +
        cycle.budgetLines.where((l) => l.needsReview).length;
    emit(state.copyWith(
      cycle: cycle,
      totals: _calculateTotals(cycle),
      isLoading: isLoading,
      unreviewedCount: unreviewed,
      effect: effect,
    ));
  }

  IncomeLine? _findIncomeLine(String id) =>
      state.cycle.incomeLines.where((l) => l.id == id).firstOrNull;

  BudgetLine? _findBudgetLine(String id) =>
      state.cycle.budgetLines.where((l) => l.id == id).firstOrNull;

  String _freshId() => DateTime.now().microsecondsSinceEpoch.toString();
}
