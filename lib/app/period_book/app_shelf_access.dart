import 'package:saldough/app/period_book/period_book_gate.dart';
import 'package:saldough/features/period_book/domain/services/period_book_shelf.dart';
import 'package:saldough/features/period_book/presentation/period_book_shelf_access.dart';

/// [PeriodBookShelfAccess] di akar komposisi: isi rak dari [PeriodBookGate]
/// (periode tertutup, ingatan buku, hak Plus; BP-9, BP-10).
final class AppShelfAccess implements PeriodBookShelfAccess {
  /// Membuat [AppShelfAccess].
  const AppShelfAccess(this._gate);

  final PeriodBookGate _gate;

  @override
  Future<List<ShelfEntry>> shelf() => _gate.shelf();
}
