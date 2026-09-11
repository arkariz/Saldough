import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/features/card/data/models/credit_card_model.dart';
import 'package:saldough/features/card/domain/entities/credit_card.dart';
import 'package:saldough/features/card/domain/repositories/credit_card_repository.dart';

const _cardsKey = StorageKey(namespace: 'card', name: 'cards');

/// Implementasi [CreditCardRepository] di atas [KeyValueStorage], mengikuti
/// pola `GoalRepositoryImpl` (ADR-0009): seluruh kartu disimpan sebagai satu
/// dokumen JSON (daftar kecil).
final class CreditCardRepositoryImpl with RepositoryGuard implements CreditCardRepository {
  /// Membuat [CreditCardRepositoryImpl] di atas [_storage].
  const CreditCardRepositoryImpl({required this._storage});

  final KeyValueStorage _storage;

  StoredValue<List<CreditCardModel>> get _store => StoredValue<List<CreditCardModel>>.json(
        key: _cardsKey,
        fromJson: (json) => (json['items'] as List<dynamic>)
            .map((e) => CreditCardModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        toJson: (models) => {
          'schemaVersion': CreditCardModel.schemaVersion,
          'items': models.map((m) => m.toJson()).toList(),
        },
        storage: _storage,
      );

  @override
  Future<Either<Failure, List<CreditCard>>> listCards() => guard(() async {
        final models = await _store.read();
        return (models ?? const []).map((m) => m.toEntity()).toList();
      });

  @override
  Future<Either<Failure, Unit>> saveCard(CreditCard card) => guardVoid(() async {
        final models = await _store.read() ?? <CreditCardModel>[];
        final next = [
          ...models.where((m) => m.id != card.id),
          CreditCardModel.fromEntity(card),
        ];
        await _store.write(next);
      });

  @override
  Future<Either<Failure, Unit>> deleteCard(String id) => guardVoid(() async {
        final models = await _store.read() ?? <CreditCardModel>[];
        await _store.write(models.where((m) => m.id != id).toList());
      });
}
