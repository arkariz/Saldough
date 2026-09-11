import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/card/domain/repositories/credit_card_repository.dart';
import 'package:saldough/features/cycle/domain/repositories/card_catalog.dart';

/// Implementasi [CardCatalog] (antarmuka milik fitur `cycle`) di atas
/// [CreditCardRepository] sungguhan — lihat catatan di `card_catalog.dart`.
final class CardCatalogImpl implements CardCatalog {
  /// Membuat [CardCatalogImpl] di atas [_repository].
  const CardCatalogImpl({required this._repository});

  final CreditCardRepository _repository;

  @override
  Future<Either<Failure, List<CardSummary>>> listCards() async {
    final result = await _repository.listCards();
    return result.map(
      (cards) => cards.map((card) => CardSummary(id: card.id, name: card.name)).toList(),
    );
  }
}
