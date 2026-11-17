import 'package:saldough/features/period_book/domain/services/period_book_shelf.dart';

/// Pintu Rak Buku ke data (ADR-045, ADR-030): isi rak dihitung di akar
/// komposisi dari periode tertutup, ingatan buku, dan hak Plus (BP-9, BP-10).
// ignore: one_member_abstracts
abstract interface class PeriodBookShelfAccess {
  /// Semua buku, terbaru di atas, dengan keadaannya (dibuka, belum dibuka, terkunci).
  Future<List<ShelfEntry>> shelf();
}
