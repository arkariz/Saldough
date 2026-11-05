import 'dart:async';

import 'package:dependencies/dependencies.dart' hide State;
import 'package:flutter/material.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/app_action_snack_bar.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/notification_capture/domain/entities/capture_inbox_entry.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_store.dart';
import 'package:saldough/features/notification_capture/domain/services/capture_card_class.dart';
import 'package:saldough/features/notification_capture/domain/services/capture_inbox_changes.dart';
import 'package:saldough/features/notification_capture/domain/usecases/capture_inbox_actions.dart';
import 'package:saldough/features/notification_capture/presentation/widgets/auto_offer.dart';
import 'package:saldough/shared/budget_catalog/budget_catalog.dart';
import 'package:saldough/shared/capture/capture.dart';
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
    this.budgetSuggestions = const {},
    this.linked = const [],
    this.duplicates = const {},
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

  /// Saran pos anggaran per id kartu (E2).
  final Map<String, BudgetItemOption> budgetSuggestions;

  /// Tautan otomatis ke rutin (7 hari), terbaru dulu.
  final List<RecurrenceMatchEntry> linked;

  /// Transaksi yang tampak sama dengan kartu yang menunggu, per id item
  /// (ADR-044 §3.3); dihitung ulang tiap muat.
  final Map<String, Transaction> duplicates;

  @override
  CaptureInboxState copyWith({
    bool? isLoading,
    List<CaptureInboxEntry>? pending,
    List<AutoRecordedEntry>? auto,
    Map<String, OccurrenceMatch>? matches,
    Map<String, BudgetItemOption>? budgetSuggestions,
    List<RecurrenceMatchEntry>? linked,
    Map<String, Transaction>? duplicates,
    UiEffect? effect,
  }) => CaptureInboxState(
    isLoading: isLoading ?? this.isLoading,
    pending: pending ?? this.pending,
    auto: auto ?? this.auto,
    matches: matches ?? this.matches,
    budgetSuggestions: budgetSuggestions ?? this.budgetSuggestions,
    linked: linked ?? this.linked,
    duplicates: duplicates ?? this.duplicates,
    effect: effect,
  );

  /// Kelas kartu [entry] menurut rencana dan duplikat yang sedang berlaku.
  CaptureCardClass cardClassFor(CaptureInboxEntry entry) =>
      cardClassOf(entry, match: matches[entry.id], existing: duplicates[entry.id]);

  @override
  List<Object?> get props => [isLoading, pending, auto, matches, budgetSuggestions, linked, duplicates];
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

/// "Bukan transaksi": tutup kartu dan pelajari bentuknya (E1).
final class CaptureInboxMarkedNotTransaction extends CaptureInboxEvent {
  /// Membuat [CaptureInboxMarkedNotTransaction].
  const CaptureInboxMarkedNotTransaction(this.id);

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

/// Kartu dicatat satu ketuk tanpa formulir (ADR-044 §3.6): satu kartu, atau
/// "Catat semua yang cocok". Tiap pasangan: kartu dan kemunculan rutin yang
/// cocok (bila ada).
final class CaptureInboxConfirmed extends CaptureInboxEvent {
  /// Membuat [CaptureInboxConfirmed].
  const CaptureInboxConfirmed(this.items);

  /// Kartu beserta kemunculan rutinnya.
  final List<(CaptureInboxEntry, OccurrenceMatch?)> items;
}

/// Kartu yang menunggu ditautkan ke transaksi yang sudah dicatat manual
/// ([existing]) sekaligus ke kemunculan rutin [match] (ADR-044 §3.3).
final class CaptureInboxLinkedToExisting extends CaptureInboxEvent {
  /// Membuat [CaptureInboxLinkedToExisting].
  const CaptureInboxLinkedToExisting({required this.id, required this.existing, required this.match});

  /// Id kartu.
  final String id;

  /// Transaksi yang sudah ada.
  final Transaction existing;

  /// Kemunculan rutin yang cocok.
  final OccurrenceMatch match;
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
    LedgerChanges? ledgerChanges,
  }) : super(const CaptureInboxState()) {
    on<CaptureInboxStarted>(_onStarted);
    on<CaptureInboxRefreshed>((_, emit) => _reload(emit));
    on<CaptureInboxDismissed>(_onDismissed);
    on<CaptureInboxMarkedNotTransaction>(_onMarkedNotTransaction);
    on<CaptureInboxRecorded>(_onRecorded);
    on<CaptureInboxUndone>(_onUndone);
    on<CaptureInboxUnlinked>(_onUnlinked);
    on<CaptureInboxLinkedToExisting>(_onLinkedToExisting);
    on<CaptureInboxConfirmed>(_onConfirmed);
    _changes = changes.stream.listen((_) => add(const CaptureInboxRefreshed()));
    // Transaksi manual yang cocok dengan kartu yang menunggu (ADR-044 §3.3).
    _ledger = ledgerChanges?.changes.listen((_) => add(const CaptureInboxRefreshed()));
  }

  final NotificationCaptureStore _store;
  final CaptureInboxActions _actions;
  final TransactionRepository _transactionRepository;
  late final StreamSubscription<void> _changes;
  StreamSubscription<void>? _ledger;

  /// Belajar dari kartu yang dicatat (E1); mengembalikan Batalkan atau `null`.
  Future<Future<void> Function()?> rememberCategory(
    CaptureInboxEntry entry, {
    required String? categoryId,
    required String note,
  }) => _actions.rememberCategory(entry, categoryId: categoryId, note: note);

  /// Belajar dompet dari kartu yang dicatat (E1); `null` bila tidak ada yang dipelajari.
  Future<({String hint, Future<void> Function() undo})?> rememberWallet(
    CaptureInboxEntry entry, {
    required String? walletId,
  }) => _actions.rememberWallet(entry, walletId: walletId);

  /// Belajar pos dari kartu yang dicatat (E2); `null` bila tidak ada yang dipelajari.
  Future<({String name, Future<void> Function() undo})?> rememberBudgetItem(
    CaptureInboxEntry entry, {
    required String? budgetItemId,
    required String? suggestedItemId,
  }) => _actions.rememberBudgetItem(entry, budgetItemId: budgetItemId, suggestedItemId: suggestedItemId);

  /// Tawaran catat otomatis per bentuk (E3); templat bentuk, atau `null`.
  Future<String?> autoOfferFor(
    CaptureInboxEntry entry, {
    required DraftKind? savedKind,
    required int? savedAmountSen,
    required String? savedWalletId,
  }) => _actions.autoOfferFor(
    entry,
    savedKind: savedKind,
    savedAmountSen: savedAmountSen,
    savedWalletId: savedWalletId,
  );

  /// Menyetujui bentuk [entry] dicatat otomatis (E3); fungsi Batalkan atau `null`.
  Future<Future<void> Function()?> approveShape(CaptureInboxEntry entry, {required int? amountSen}) =>
      _actions.approveShape(entry, amountSen: amountSen);

  Future<void> _reload(Emitter<CaptureInboxState> emit, {UiEffect? effect}) async {
    final pending = (await _store.loadInbox()).getOrElse((_) => const []);
    final auto = (await _store.loadAutoRecorded()).getOrElse((_) => const []);
    final matches = await _actions.matchesFor(pending);
    final suggestions = await _actions.budgetSuggestionsFor(pending, matches);
    final duplicates = await _actions.duplicatesFor(pending);
    final linked = (await _actions.matchLog?.list(DateTime.now()))?.getOrElse((_) => const []) ?? const [];
    emit(
      state.copyWith(
        isLoading: false,
        pending: pending,
        auto: auto,
        matches: matches,
        budgetSuggestions: suggestions,
        linked: linked,
        duplicates: duplicates,
        effect: effect,
      ),
    );
  }

  Future<void> _onStarted(CaptureInboxStarted event, Emitter<CaptureInboxState> emit) async {
    await _reload(emit);
    final classes = [for (final e in state.pending) state.cardClassFor(e)];
    if (classes.isEmpty) return;
    AppAnalytics.log(
      CaptureEvents.inboxOpened(
        planned: classes.where((c) => c == CaptureCardClass.planned).length,
        recognized: classes.where((c) => c == CaptureCardClass.recognized).length,
        needsInput: classes.where((c) => c == CaptureCardClass.needsInput).length,
      ),
    );
  }

  Future<void> _onDismissed(CaptureInboxDismissed event, Emitter<CaptureInboxState> emit) async {
    final entry = state.pending.where((e) => e.id == event.id).firstOrNull;
    if (entry != null) {
      AppAnalytics.log(
        CaptureEvents.cardAction(
          action: state.duplicates.containsKey(entry.id) ? 'close_duplicate' : 'dismiss',
          cardClass: captureClassName(state.cardClassFor(entry)),
        ),
      );
    }
    await _actions.remove(event.id);
    await _reload(
      emit,
      effect: entry == null ? ShowSnackBarEffect(message: t.notificationCapture.dismissed) : _dismissedWithUndo(entry),
    );
  }

  Future<void> _onMarkedNotTransaction(
    CaptureInboxMarkedNotTransaction event,
    Emitter<CaptureInboxState> emit,
  ) async {
    final entry = state.pending.where((e) => e.id == event.id).firstOrNull;
    if (entry == null) return;
    AppAnalytics.log(
      CaptureEvents.cardAction(action: 'not_transaction', cardClass: captureClassName(state.cardClassFor(entry))),
    );
    final undo = await _actions.markNotTransaction(entry);
    await _reload(
      emit,
      effect: undo == null
          ? _dismissedWithUndo(entry)
          : CallbackEffect(
              callback: (context) {
                final colors = context.appColors;
                ScaffoldMessenger.of(context).showSnackBar(
                  actionSnackBar(
                    context,
                    content: Text(t.notificationCapture.notTransactionDone, style: TextStyle(color: colors.bg)),
                    backgroundColor: colors.ink,
                    action: SnackBarAction(
                      key: const ValueKey('inbox-not-transaction-undo'),
                      label: t.transaction.undoDeleteAction,
                      textColor: colors.brand,
                      onPressed: () => unawaited(undo()),
                    ),
                  ),
                );
              },
            ),
    );
  }

  /// "Notifikasi diabaikan." dengan Urungkan yang mengembalikan [entry] ke
  /// Perlu dicek (QA PR #43 F18), pola yang sama dengan hapus transaksi
  /// (`TransactionBloc`). Urungkan memanggil [CaptureInboxActions.restore]
  /// langsung; `CaptureInboxChanges` memuat ulang kotak masuk yang tampil.
  UiEffect _dismissedWithUndo(CaptureInboxEntry entry) => CallbackEffect(
    callback: (context) {
      final colors = context.appColors;
      final restore = _actions.restore;
      ScaffoldMessenger.of(context).showSnackBar(
        actionSnackBar(
          context,
          content: Text(t.notificationCapture.dismissed, style: TextStyle(color: colors.bg)),
          backgroundColor: colors.ink,
          action: SnackBarAction(
            key: const ValueKey('inbox-dismiss-undo'),
            label: t.transaction.undoDeleteAction,
            textColor: colors.brand,
            onPressed: () => unawaited(restore(entry)),
          ),
        ),
      );
    },
  );

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

  Future<void> _onConfirmed(CaptureInboxConfirmed event, Emitter<CaptureInboxState> emit) async {
    final done = <(CaptureInboxEntry, Transaction)>[];
    for (final (entry, match) in event.items) {
      final cardClass = captureClassName(state.cardClassFor(entry));
      if (await _actions.confirm(entry, match: match) case Right(:final value)) {
        done.add((entry, value));
        AppAnalytics.log(
          CaptureEvents.cardAction(action: event.items.length > 1 ? 'confirm_all' : 'one_tap', cardClass: cardClass),
        );
      }
    }
    // Tawaran catat otomatis (E3) hanya untuk satu kartu: jenis, dompet, dan nominal
    // pasti tidak berubah dari draf.
    final offer = done.length == 1
        ? await _actions.autoOfferFor(
            done.single.$1,
            savedKind: done.single.$1.draft.kind,
            savedAmountSen: done.single.$2.amount,
            savedWalletId: done.single.$1.draft.walletId,
          )
        : null;
    await _reload(emit, effect: done.isEmpty ? _confirmFailed() : _confirmedWithUndo(done, offer: offer));
  }

  UiEffect _confirmFailed() => ShowSnackBarEffect(message: t.common.genericErrorMessage, severity: .error);

  UiEffect _confirmedWithUndo(List<(CaptureInboxEntry, Transaction)> done, {String? offer}) => CallbackEffect(
    callback: (context) {
      final colors = context.appColors;
      final message = done.length == 1
          ? t.notificationCapture.oneTapRecorded(
              amount: AppMoneyFormatter.format(done.single.$2.amount),
              app: done.single.$1.appLabel,
            )
          : t.notificationCapture.oneTapRecordedMany(n: done.length);
      final controller = ScaffoldMessenger.of(context).showSnackBar(
        actionSnackBar(
          context,
          content: Text(message, style: TextStyle(color: colors.bg)),
          backgroundColor: colors.ink,
          action: SnackBarAction(
            key: const ValueKey('inbox-confirm-undo'),
            label: t.notificationCapture.undoAction,
            textColor: colors.brand,
            onPressed: () => unawaited(_undoConfirmed(done)),
          ),
        ),
      );
      // Tawaran menyusul sesudah snackbar hasil ditutup, kecuali dibatalkan.
      if (offer != null) {
        unawaited(
          controller.closed.then((reason) {
            if (reason == SnackBarClosedReason.action || !context.mounted) return;
            showAutoOffer(
              context,
              template: offer,
              approve: () => _actions.approveShape(done.single.$1, amountSen: done.single.$2.amount),
            );
          }),
        );
      }
    },
  );

  Future<void> _undoConfirmed(List<(CaptureInboxEntry, Transaction)> done) async {
    for (final (entry, transaction) in done) {
      await _actions.undoConfirm(entry, transaction);
    }
  }

  Future<void> _onLinkedToExisting(CaptureInboxLinkedToExisting event, Emitter<CaptureInboxState> emit) async {
    final linkedEntry = state.pending.where((e) => e.id == event.id).firstOrNull;
    final result = await _actions.linkExisting(event.id, event.existing, event.match);
    if (result.isRight() && linkedEntry != null) {
      AppAnalytics.log(
        CaptureEvents.cardAction(action: 'link_existing', cardClass: captureClassName(state.cardClassFor(linkedEntry))),
      );
    }
    await _reload(
      emit,
      effect: result.isRight()
          ? ShowSnackBarEffect(
              message: t.notificationCapture.linkedExisting(name: event.match.rule.note),
              severity: .success,
            )
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
    await _ledger?.cancel();
    return super.close();
  }
}
