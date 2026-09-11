import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/card/domain/entities/recurring_subscription.dart';

/// Kontrak akses data [RecurringSubscription]. Lihat ADR-0005 — selalu
/// `Either<Failure, T>`, tidak pernah `throw Failure`.
abstract interface class RecurringSubscriptionRepository {
  /// Seluruh langganan terdaftar, lintas kartu.
  Future<Either<Failure, List<RecurringSubscription>>> listSubscriptions();

  /// Menyimpan [subscription] — menambah kalau `id` baru, menimpa kalau
  /// sudah ada.
  Future<Either<Failure, Unit>> saveSubscription(RecurringSubscription subscription);

  /// Menghapus langganan ber-`id` [id]. Tidak berefek kalau `id` tidak
  /// ditemukan.
  Future<Either<Failure, Unit>> deleteSubscription(String id);
}
