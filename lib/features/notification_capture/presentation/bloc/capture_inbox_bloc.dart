import 'dart:async';

import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/notification_capture/domain/entities/capture_inbox_entry.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_store.dart';
import 'package:saldough/features/notification_capture/domain/services/capture_inbox_changes.dart';
import 'package:saldough/features/notification_capture/domain/usecases/capture_inbox_actions.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:state_management/state_management.dart';

/// State kotak masuk Catat dari notifikasi.
final class CaptureInboxState extends UiState<CaptureInboxState> {
  /// Membuat [CaptureInboxState].
  const CaptureInboxState({
    this.isLoading = true,
    this.pending = const [],
    this.auto = const [],
    this.matches = const {},
    this.linked = const [],
    super.effect,
  });

  /// Sedang memuat.
  final bool isLoading;

  /// Perlu ditinjau, terbaru dulu.
  final List<CaptureInboxEntry> pending;

  /// Tercatat otomatis, terbaru dulu.
  final List<AutoRecordedEntry> auto;

  /// Kemunculan rutin yang cocok dengan item [pending], per id item.
  final Map<String, OccurrenceMatch> matches;

  /// Tautan otomatis ke rutin (7 hari), terbaru dulu.
  final List<RecurrenceMatchEntry> linked;

  @override
  CaptureInboxState copyWith({
    bool? isLoading,
    List<CaptureInboxEntry>? pending,
    List<AutoRecordedEntry>? auto,
    Map<String, OccurrenceMatch>? matches,
    List<RecurrenceMatchEntry>? linked,
    UiEffect? effect,
  }) => CaptureInboxState(
    isLoading: isLoading ?? this.isLoading,
    pending: pending ?? this.pending,
    auto: auto ?? this.auto,
    matches: matches ?? this.matches,
    linked: linked ?? this.linked,
    effect: effect,
  );

  @override
  List<Object?> get props => [isLoading, pending, auto, matches, linked];
}

/// Event [CaptureInboxBloc].
sealed class CaptureInboxEvent {
  /// Membuat [CaptureInboxEvent].
  const CaptureInboxEvent();
}

/// Layar dibuka.
final class CaptureInboxStarted extends CaptureInboxEvent {
  /// Membuat [CaptureInboxStarted].
  const CaptureInboxStarted();
}

/// Muat ulang (sinyal perubahan, atau sesudah CATAT/pola).
final class CaptureInboxRefreshed extends CaptureInboxEvent {
  /// Membuat [CaptureInboxRefreshed].
  const CaptureInboxRefreshed();
}

/// Abaikan satu tangkapan.
final class CaptureInboxDismissed extends CaptureInboxEvent {
  /// Membuat [CaptureInboxDismissed].
  const CaptureInboxDismissed(this.id);

  /// Id tangkapan.
  final String id;
}

/// Tangkapan sudah dicatat lewat CATAT.
final class CaptureInboxRecorded extends CaptureInboxEvent {
  /// Membuat [CaptureInboxRecorded].
  const CaptureInboxRecorded(this.id);

  /// Id tangkapan.
  final String id;
}

/// Batalkan transaksi otomatis.
final class CaptureInboxUndone extends CaptureInboxEvent {
  /// Membuat [CaptureInboxUndone].
  const CaptureInboxUndone(this.entry);

  /// Entri log.
  final AutoRecordedEntry entry;
}

/// Lepaskan tautan otomatis ke rutin.
final class CaptureInboxUnlinked extends CaptureInboxEvent {
  /// Membuat [CaptureInboxUnlinked].
  const CaptureInboxUnlinked(this.entry);

  /// Entri log tautan.
  final RecurrenceMatchEntry entry;
}

/// Bloc kotak masuk (ADR-032 §3.6).
final class CaptureInboxBloc extends Bloc<CaptureInboxEvent, CaptureInboxState> {
  /// Membuat [CaptureInboxBloc].
  CaptureInboxBloc({
    required this._store,
    required this._actions,
    required this._transactionRepository,
    required CaptureInboxChanges changes,
  }) : super(const CaptureInboxState()) {
    on<CaptureInboxStarted>((_, emit) => _reload(emit));
    on<CaptureInboxRefreshed>((_, emit) => _reload(emit));
    on<CaptureInboxDismissed>(_onDismissed);
    on<CaptureInboxRecorded>(_onRecorded);
    on<CaptureInboxUndone>(_onUndone);
    on<CaptureInboxUnlinked>(_onUnlinked);
    _changes = changes.stream.listen((_) => add(const CaptureInboxRefreshed()));
  }

  final NotificationCaptureStore _store;
  final CaptureInboxActions _actions;
  final TransactionRepository _transactionRepository;
  late final StreamSubscription<void> _changes;

  Future<void> _reload(Emitter<CaptureInboxState> emit, {UiEffect? effect}) async {
    final pending = (await _store.loadInbox()).getOrElse((_) => const []);
    final auto = (await _store.loadAutoRecorded()).getOrElse((_) => const []);
    final matches = await _actions.matchesFor(pending);
    final linked = (await _actions.matchLog?.list(DateTime.now()))?.getOrElse((_) => const []) ?? const [];
    emit(
      state.copyWith(isLoading: false, pending: pending, auto: auto, matches: matches, linked: linked, effect: effect),
    );
  }

  Future<void> _onDismissed(CaptureInboxDismissed event, Emitter<CaptureInboxState> emit) async {
    await _actions.remove(event.id);
    await _reload(emit, effect: ShowSnackBarEffect(message: t.notificationCapture.dismissed));
  }

  Future<void> _onRecorded(CaptureInboxRecorded event, Emitter<CaptureInboxState> emit) async {
    await _actions.remove(event.id);
    await _reload(emit);
  }

  Future<void> _onUndone(CaptureInboxUndone event, Emitter<CaptureInboxState> emit) async {
    final result = await _actions.undo(event.entry);
    await _reload(
      emit,
      effect: result.isRight()
          ? ShowSnackBarEffect(message: t.notificationCapture.undone, severity: .success)
          : ShowSnackBarEffect(message: t.common.genericErrorMessage, severity: .error),
    );
  }

  Future<void> _onUnlinked(CaptureInboxUnlinked event, Emitter<CaptureInboxState> emit) async {
    final result = await _actions.unlink(event.entry);
    await _reload(
      emit,
      effect: result.isRight()
          ? ShowSnackBarEffect(message: t.recurring.unlinkedMessage, severity: .success)
          : ShowSnackBarEffect(message: t.common.genericErrorMessage, severity: .error),
    );
  }

  /// Transaksi dari [entry] untuk "Tinjau", atau `null` bila sudah dihapus.
  Future<Transaction?> findTransaction(AutoRecordedEntry entry) async {
    final month = (await _transactionRepository.listTransactionsInMonth(
      entry.transactionDate,
    )).getOrElse((_) => const []);
    return month.where((t) => t.id == entry.transactionId).firstOrNull;
  }

  /// Menafsirkan ulang item [id] sesudah pola baru disimpan.
  Future<void> reinterpret(String id) async {
    await _actions.reinterpret(id);
  }

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}
