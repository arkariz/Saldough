import 'package:saldough/features/card/domain/entities/card_statement.dart';
import 'package:saldough/features/card/domain/entities/credit_card.dart';
import 'package:saldough/features/card/domain/entities/recurring_subscription.dart';
import 'package:state_management/state_management.dart';

/// State [CardBloc]. `effect` tidak pernah masuk [props] (ADR-0003).
final class CardState extends UiState<CardState> {
  /// Membuat [CardState].
  const CardState({
    required this.cards,
    required this.cardId,
    required this.statements,
    required this.subscriptions,
    required this.isLoading,
    super.effect,
  });

  /// State awal sebelum kartu dimuat.
  factory CardState.initial() =>
      const CardState(cards: [], cardId: '', statements: [], subscriptions: [], isLoading: true);

  /// Seluruh kartu terdaftar (FR-CARD-001).
  final List<CreditCard> cards;

  /// Kartu yang sedang dipilih. Kosong berarti belum ada yang dipilih.
  final String cardId;

  /// Siklus tagihan milik [cardId].
  final List<CardStatement> statements;

  /// Seluruh langganan terdaftar, lintas kartu.
  final List<RecurringSubscription> subscriptions;

  /// Sedang memuat/menyimpan.
  final bool isLoading;

  /// Kartu yang sedang dipilih, atau `null` kalau [cardId] kosong.
  CreditCard? get selectedCard => cards.where((c) => c.id == cardId).firstOrNull;

  /// Siklus tagihan yang masih terbuka, atau `null` kalau belum ada.
  CardStatement? get openStatement => statements.where((s) => !s.isClosed).firstOrNull;

  /// Siklus tagihan yang sudah ditutup, terurut dari yang terbaru.
  List<CardStatement> get closedStatements =>
      statements.where((s) => s.isClosed).toList().reversed.toList();

  /// Langganan milik [cardId].
  List<RecurringSubscription> get cardSubscriptions =>
      subscriptions.where((s) => s.cardId == cardId).toList();

  @override
  CardState copyWith({
    List<CreditCard>? cards,
    String? cardId,
    List<CardStatement>? statements,
    List<RecurringSubscription>? subscriptions,
    bool? isLoading,
    UiEffect? effect,
  }) {
    return CardState(
      cards: cards ?? this.cards,
      cardId: cardId ?? this.cardId,
      statements: statements ?? this.statements,
      subscriptions: subscriptions ?? this.subscriptions,
      isLoading: isLoading ?? this.isLoading,
      effect: effect,
    );
  }

  /// Helper transisi state — berpindah menampilkan [statements] milik kartu
  /// yang sedang dipilih.
  CardState withStatements(List<CardStatement> statements, {UiEffect? effect}) =>
      copyWith(statements: statements, isLoading: false, effect: effect);

  @override
  List<Object?> get props => [cards, cardId, statements, subscriptions, isLoading];
}
