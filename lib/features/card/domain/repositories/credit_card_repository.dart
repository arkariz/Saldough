import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/card/domain/entities/credit_card.dart';

/// Kontrak akses data [CreditCard]. Lihat ADR-0005 — selalu
/// `Either<Failure, T>`, tidak pernah `throw Failure`.
abstract interface class CreditCardRepository {
  /// Daftar seluruh kartu terdaftar (FR-CARD-001: lebih dari satu kartu).
  Future<Either<Failure, List<CreditCard>>> listCards();

  /// Menyimpan [card] — menambah kalau `id` baru, menimpa kalau sudah ada.
  Future<Either<Failure, Unit>> saveCard(CreditCard card);

  /// Menghapus kartu ber-`id` [id]. Tidak berefek kalau `id` tidak ditemukan.
  Future<Either<Failure, Unit>> deleteCard(String id);
}
