import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/card/domain/entities/card_transaction.dart';
import 'package:saldough/features/card/domain/entities/credit_card.dart';
import 'package:saldough/features/card/domain/entities/recurring_subscription.dart';
import 'package:saldough/features/card/domain/repositories/card_statement_repository.dart';
import 'package:saldough/features/card/domain/repositories/credit_card_repository.dart';
import 'package:saldough/features/card/domain/repositories/recurring_subscription_repository.dart';
import 'package:saldough/features/card/domain/usecases/close_card_statement.dart';
import 'package:saldough/features/card/presentation/bloc/card_state.dart';
import 'package:state_management/state_management.dart';

part 'card_effect.dart';
part 'card_event.dart';

/// Bloc layar kartu kredit: kelola kartu, catat transaksi, tutup siklus
/// tagihan, kelola langganan (FR-CARD-001 sampai FR-CARD-005).
final class CardBloc extends Bloc<CardEvent, CardState> {
  /// Membuat [CardBloc].
  CardBloc({
    required this._cardRepository,
    required this._statementRepository,
    required this._subscriptionRepository,
    required this._closeCardStatement,
  }) : super(CardState.initial()) {
    on<CardOpened>(_onOpened);
    on<CardSelected>(_onSelected);
    on<CreditCardSaved>(_onCreditCardSaved);
    on<CreditCardDeleted>(_onCreditCardDeleted);
    on<CardTransactionAdded>(_onTransactionAdded);
    on<CardTransactionConfirmed>(_onTransactionConfirmed);
    on<CardStatementClosed>(_onStatementClosed);
    on<RecurringSubscriptionSaved>(_onSubscriptionSaved);
    on<RecurringSubscriptionDeleted>(_onSubscriptionDeleted);
  }

  final CreditCardRepository _cardRepository;
  final CardStatementRepository _statementRepository;
  final RecurringSubscriptionRepository _subscriptionRepository;
  final CloseCardStatement _closeCardStatement;

  Future<void> _onOpened(CardOpened event, Emitter<CardState> emit) async {
    emit(state.copyWith(isLoading: true));
    final cards = await _loadCards(emit);
    if (cards == null) return;

    final subsResult = await _subscriptionRepository.listSubscriptions();
    final subscriptions = switch (subsResult) {
      Right(value: final s) => s,
      Left() => const <RecurringSubscription>[],
    };

    final firstId = cards.firstOrNull?.id ?? '';
    emit(state.copyWith(cards: cards, subscriptions: subscriptions, cardId: firstId, isLoading: firstId.isEmpty));
    if (firstId.isNotEmpty) add(CardSelected(firstId));
  }

  Future<void> _onSelected(CardSelected event, Emitter<CardState> emit) async {
    emit(state.copyWith(cardId: event.cardId, isLoading: true));
    final result = await _statementRepository.listStatements(event.cardId);
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(isLoading: false, effect: _effectError(failure)));
      case Right(value: final statements):
        emit(state.withStatements(statements));
    }
  }

  Future<void> _onCreditCardSaved(CreditCardSaved event, Emitter<CardState> emit) async {
    final saveResult = await _cardRepository.saveCard(event.card);
    if (saveResult case Left(value: final failure)) {
      emit(state.copyWith(effect: _effectError(failure)));
      return;
    }
    final cards = await _loadCards(emit);
    if (cards == null) return;
    final keepSelected = cards.any((c) => c.id == state.cardId);
    final nextId = keepSelected ? state.cardId : (cards.firstOrNull?.id ?? '');
    emit(state.copyWith(cards: cards, cardId: nextId));
    if (!keepSelected && nextId.isNotEmpty) add(CardSelected(nextId));
  }

  Future<void> _onCreditCardDeleted(CreditCardDeleted event, Emitter<CardState> emit) async {
    final deleteResult = await _cardRepository.deleteCard(event.id);
    if (deleteResult case Left(value: final failure)) {
      emit(state.copyWith(effect: _effectError(failure)));
      return;
    }
    final cards = await _loadCards(emit);
    if (cards == null) return;
    final keepSelected = cards.any((c) => c.id == state.cardId);
    final nextId = keepSelected ? state.cardId : (cards.firstOrNull?.id ?? '');
    emit(state.copyWith(cards: cards, cardId: nextId, statements: keepSelected ? state.statements : const []));
    if (!keepSelected && nextId.isNotEmpty) add(CardSelected(nextId));
  }

  Future<void> _onTransactionAdded(CardTransactionAdded event, Emitter<CardState> emit) async {
    final card = state.selectedCard;
    if (card == null) return;
    final transaction = CardTransaction(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      date: event.date,
      merchant: event.merchant,
      amount: event.amount,
      note: event.note,
    );
    final result = await _statementRepository.addTransaction(
      cardId: card.id,
      statementDayOfMonth: card.statementDayOfMonth,
      transaction: transaction,
    );
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _effectError(failure)));
      case Right():
        add(CardSelected(card.id));
    }
  }

  Future<void> _onTransactionConfirmed(CardTransactionConfirmed event, Emitter<CardState> emit) async {
    final open = state.openStatement;
    if (open == null) return;
    final target = open.transactions.where((t) => t.id == event.transactionId).firstOrNull;
    if (target == null) return;

    final updated = target.copyWith(amount: event.amount, isConfirmed: true);
    final nextStatement = open.copyWith(
      transactions: [for (final t in open.transactions) if (t.id == updated.id) updated else t],
    );
    final result = await _statementRepository.saveStatement(nextStatement);
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _effectError(failure)));
      case Right():
        add(CardSelected(nextStatement.cardId));
    }
  }

  Future<void> _onStatementClosed(CardStatementClosed event, Emitter<CardState> emit) async {
    final card = state.selectedCard;
    if (card == null) return;
    final result = await _closeCardStatement(cardId: card.id, statementDayOfMonth: card.statementDayOfMonth);
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _effectError(failure)));
      case Right():
        await _reloadStatements(card.id, emit, effect: _effectStatementClosed());
    }
  }

  Future<void> _onSubscriptionSaved(RecurringSubscriptionSaved event, Emitter<CardState> emit) async {
    final result = await _subscriptionRepository.saveSubscription(event.subscription);
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _effectError(failure)));
      case Right():
        await _reloadSubscriptions(emit);
    }
  }

  Future<void> _onSubscriptionDeleted(RecurringSubscriptionDeleted event, Emitter<CardState> emit) async {
    final result = await _subscriptionRepository.deleteSubscription(event.id);
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _effectError(failure)));
      case Right():
        await _reloadSubscriptions(emit);
    }
  }

  Future<List<CreditCard>?> _loadCards(Emitter<CardState> emit) async {
    final result = await _cardRepository.listCards();
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(isLoading: false, effect: _effectError(failure)));
        return null;
      case Right(value: final cards):
        return cards;
    }
  }

  Future<void> _reloadStatements(String cardId, Emitter<CardState> emit, {UiEffect? effect}) async {
    final result = await _statementRepository.listStatements(cardId);
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _effectError(failure)));
      case Right(value: final statements):
        emit(state.withStatements(statements, effect: effect));
    }
  }

  Future<void> _reloadSubscriptions(Emitter<CardState> emit) async {
    final result = await _subscriptionRepository.listSubscriptions();
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _effectError(failure)));
      case Right(value: final subscriptions):
        emit(state.copyWith(subscriptions: subscriptions));
    }
  }
}
