import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/shared/transaction/domain/transaction.dart';

/// Penjaga posisi investasi (ADR-049 §3.6): mencatat, menyunting, atau
/// menghapus transaksi investasi ditolak bila membuat jumlah instrumen
/// negatif di titik mana pun. Port di sini supaya `RecordTransaction` bisa
/// menegakkannya tanpa mengimpor modul investasi; implementasinya di
/// `shared/investment`, dipasang akar komposisi.
// Port DI (ADR-030), bukan fungsi: dipasang lewat kontainer.
// ignore: one_member_abstracts
abstract interface class InvestmentLedgerGuard {
  /// Memeriksa perubahan buku besar: [next] menggantikan [previous] (catat
  /// baru: [previous] `null`; hapus: [next] `null`). `Right` bila sah.
  Future<Either<Failure, Unit>> check({Transaction? next, Transaction? previous});
}

/// [InvestmentLedgerGuard] yang selalu mengizinkan: untuk lingkup dan uji
/// yang tidak memasang investasi.
final class NoInvestmentLedgerGuard implements InvestmentLedgerGuard {
  /// Membuat [NoInvestmentLedgerGuard].
  const NoInvestmentLedgerGuard();

  @override
  Future<Either<Failure, Unit>> check({Transaction? next, Transaction? previous}) async => right(unit);
}
