import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/worklog/domain/entities/work_log_entry.dart';
import 'package:saldough/features/worklog/domain/repositories/worklog_repository.dart';
import 'package:saldough/features/worklog/domain/usecases/close_billing_book.dart';
import 'package:saldough/features/worklog/domain/usecases/inject_net_pay.dart';
import 'package:saldough/features/worklog/presentation/bloc/worklog_state.dart';
import 'package:saldough/shared/income/income.dart';
import 'package:state_management/state_management.dart';

part 'worklog_effect.dart';
part 'worklog_event.dart';

/// Bloc layar catatan jam kerja dan buku jam. Lihat ARCHITECTURE_OVERVIEW.md
/// bagian "Menulis satu fitur".
final class WorklogBloc extends Bloc<WorklogEvent, WorklogState> {
  /// Membuat [WorklogBloc].
  WorklogBloc({
    required this._sourceRepository,
    required this._worklogRepository,
    required this._closeBillingBook,
    required this._injectNetPay,
  }) : super(WorklogState.initial()) {
    on<WorklogOpened>(_onOpened);
    on<WorklogSourceSelected>(_onSourceSelected);
    on<WorkLogEntryAdded>(_onEntryAdded);
    on<BillingBookClosed>(_onBookClosed);
    on<NetPayInjected>(_onInjected);
  }

  final IncomeSourceRepository _sourceRepository;
  final WorklogRepository _worklogRepository;
  final CloseBillingBook _closeBillingBook;
  final InjectNetPay _injectNetPay;

  Future<void> _onOpened(WorklogOpened event, Emitter<WorklogState> emit) async {
    emit(state.copyWith(isLoading: true));
    final result = await _sourceRepository.listSources();
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(isLoading: false, effect: _effectError(failure)));
      case Right(value: final sources):
        final freelance = sources.where((s) => s.kind == .hourlyFreelance).toList();
        final firstId = freelance.firstOrNull?.id ?? '';
        emit(state.copyWith(sources: freelance, sourceId: firstId, isLoading: firstId.isEmpty));
        if (firstId.isNotEmpty) add(WorklogSourceSelected(firstId));
    }
  }

  Future<void> _onSourceSelected(WorklogSourceSelected event, Emitter<WorklogState> emit) async {
    emit(state.copyWith(sourceId: event.sourceId, isLoading: true));
    final result = await _worklogRepository.listBooks(event.sourceId);
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(isLoading: false, effect: _effectError(failure)));
      case Right(value: final books):
        emit(state.withBooks(books));
    }
  }

  Future<void> _onEntryAdded(WorkLogEntryAdded event, Emitter<WorklogState> emit) async {
    final entry = WorkLogEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      date: event.date,
      hours: event.hours,
      startsNewBook: event.startsNewBook,
    );
    final result = await _worklogRepository.addEntry(sourceId: state.sourceId, entry: entry);
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _effectError(failure)));
      case Right():
        add(WorklogSourceSelected(state.sourceId));
    }
  }

  Future<void> _onBookClosed(BillingBookClosed event, Emitter<WorklogState> emit) async {
    final source = state.selectedSource;
    final book = state.books.where((b) => b.id == event.bookId).firstOrNull;
    if (source == null || book == null) return;

    final result = await _closeBillingBook(book: book, source: source);
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _effectError(failure)));
      case Right(value: final breakdown):
        await _reloadBooks(emit, effect: _effectBookClosed(breakdown));
    }
  }

  Future<void> _onInjected(NetPayInjected event, Emitter<WorklogState> emit) async {
    final source = state.selectedSource;
    final book = state.books.where((b) => b.id == event.bookId).firstOrNull;
    if (source == null || book == null) return;

    final result = await _injectNetPay(book: book, sourceLabel: source.name, cycleId: event.cycleId);
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _effectError(failure)));
      case Right():
        await _reloadBooks(emit, effect: _effectInjected(event.cycleId));
    }
  }

  Future<void> _reloadBooks(Emitter<WorklogState> emit, {required UiEffect effect}) async {
    final result = await _worklogRepository.listBooks(state.sourceId);
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _effectError(failure)));
      case Right(value: final books):
        emit(state.withBooks(books, effect: effect));
    }
  }
}
