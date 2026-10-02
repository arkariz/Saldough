import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/shared/recurring/domain/recurring_rule.dart';

/// Kontrak akses data [RecurringRule]. Lihat ADR-0005 — selalu
/// `Either<Failure, T>`, tidak pernah `throw Failure`.
abstract interface class RecurringRuleRepository {
  /// Seluruh rutin, termasuk yang dijeda dan yang sudah berakhir.
  Future<Either<Failure, List<RecurringRule>>> listRules();

  /// Menyimpan [rule] — menambah kalau `id` baru, menimpa kalau sudah ada.
  Future<Either<Failure, Unit>> saveRule(RecurringRule rule);

  /// Menghapus rutin ber-`id` [id]. Tidak berefek kalau `id` tidak
  /// ditemukan.
  ///
  /// ⚠ Transaksi yang pernah dicatat dari rutin ini tidak ikut terhapus
  /// (FR-RUT-005); tautan `recurrence`-nya tetap ada tetapi tidak menunjuk
  /// rutin mana pun.
  Future<Either<Failure, Unit>> deleteRule(String id);
}
