import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/features/worklog/domain/entities/work_log_entry.dart';
import 'package:saldough/features/worklog/domain/repositories/cycle_income_writer.dart';
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
    required this._cycleIncomeWriter,
  }) : super(WorklogState.initial()) {
    on<WorklogOpened>(_onOpened);
    on<WorklogSourceSelected>(_onSourceSelected);
    on<WorkLogEntryAdded>(_onEntryAdded);
    on<WorkLogEntryUpdated>(_onEntryUpdated);
    on<WorkLogEntryRemoved>(_onEntryRemoved);
    on<BillingBookClosed>(_onBookClosed);
    on<NetPayInjected>(_onInjected);
  }

  final IncomeSourceRepository _sourceRepository;
  final WorklogRepository _worklogRepository;
  final CloseBillingBook _closeBillingBook;
  final InjectNetPay _injectNetPay;
  final CycleIncomeWriter _cycleIncomeWriter;

  Future<void> _onOpened(WorklogOpened event, Emitter<WorklogState> emit) async {
    emit(state.copyWith(isLoading: true));
    final result = await _sourceRepository.listSources();
    // UX-09: daftar siklus untuk pemilih siklus tujuan penyuntikan --
    // kegagalannya tidak menghalangi layar tampil (sama seperti
    // `CycleBloc._listCycleIds`), field jadi kosong dan pemilih tidak
    // menawarkan opsi.
    final cycleIdsResult = await _cycleIncomeWriter.listCycleIds();
    final cycleIds = cycleIdsResult.getOrElse((_) => const []);
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(isLoading: false, effect: _effectError(failure)));
      case Right(value: final sources):
        final freelance = sources.where((s) => s.kind == .hourlyFreelance).toList();
        // Laporan pemilik: layar ini sebelumnya selalu lompat ke sumber
        // freelance PERTAMA, walau dicapai dari tombol milik sumber
        // tertentu di layar Sumber Pemasukan -- pakai `initialSourceId`
        // kalau ada dan benar-benar salah satu sumber freelance, jatuh
        // balik ke yang pertama kalau tidak.
        final requestedId = event.initialSourceId;
        final firstId = requestedId != null && freelance.any((s) => s.id == requestedId)
            ? requestedId
            : freelance.firstOrNull?.id ?? '';
        emit(
          state.copyWith(
            sources: freelance,
            sourceId: firstId,
            cycleIds: cycleIds,
            isLoading: firstId.isEmpty,
          ),
        );
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
    // `startsNewBook` tidak lagi ditentukan pemilik lewat layar ini (lihat
    // catatan di `WorkLogEntryAdded`) -- selalu `false`, yang tetap memulai
    // buku baru kalau memang belum ada buku terbuka (`WorklogRepositoryImpl`
    // bagian `else`), dan menyambung ke yang terbuka kalau ada.
    final entry = WorkLogEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      date: event.date,
      hours: event.hours,
    );
    final result = await _worklogRepository.addEntry(sourceId: state.sourceId, entry: entry);
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _effectError(failure)));
      case Right():
        add(WorklogSourceSelected(state.sourceId));
    }
  }

  Future<void> _onEntryUpdated(WorkLogEntryUpdated event, Emitter<WorklogState> emit) async {
    final book = state.openBook;
    if (book == null || book.id != event.bookId) return;
    final entries = [
      for (final entry in book.entries)
        if (entry.id == event.entryId) entry.copyWith(hours: event.hours) else entry,
    ];
    final result = await _worklogRepository.saveBook(book.copyWith(entries: entries));
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _effectError(failure)));
      case Right():
        add(WorklogSourceSelected(state.sourceId));
    }
  }

  Future<void> _onEntryRemoved(WorkLogEntryRemoved event, Emitter<WorklogState> emit) async {
    final book = state.openBook;
    if (book == null || book.id != event.bookId) return;
    final entries = book.entries.where((entry) => entry.id != event.entryId).toList();
    final result = await _worklogRepository.saveBook(book.copyWith(entries: entries));
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
      case Right():
        // Tidak ada efek snackbar di sini -- `WorklogPage` mendeteksi buku
        // yang baru tertutup lewat `BlocListener` (openBook berubah jadi
        // null) dan langsung menampilkan dialog rincian gaji + tawaran
        // suntik (laporan pemilik: sebelumnya cuma snackbar sekilas lalu
        // pemilik harus mencari sendiri buku itu di riwayat).
        await _reloadBooks(emit);
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

  Future<void> _reloadBooks(Emitter<WorklogState> emit, {UiEffect? effect}) async {
    final result = await _worklogRepository.listBooks(state.sourceId);
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _effectError(failure)));
      case Right(value: final books):
        emit(state.withBooks(books, effect: effect));
    }
  }
}
