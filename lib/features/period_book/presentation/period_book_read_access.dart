import 'package:flutter/widgets.dart';
import 'package:saldough/features/period_book/domain/entities/period_book_content.dart';

/// Hasil membuka buku satu periode (sampul dan rapor).
sealed class BookLoad {
  const BookLoad();
}

/// Siap: isi buku dan stempel yang tercetak di sampulnya (urut tetap).
final class BookReady extends BookLoad {
  /// Membuat [BookReady].
  const BookReady({required this.content, required this.stamps});

  /// Isi halaman 1-4 dan bahan halaman 5.
  final PeriodBookContent content;

  /// Id stempel tercetak di sampul periode ini (bisa kosong).
  final List<String> stamps;
}

/// Terkunci untuk paket sekarang dan belum pernah dibuka (BP-10).
final class BookLocked extends BookLoad {
  /// Membuat [BookLocked].
  const BookLocked();
}

/// Gagal membaca data.
final class BookFailed extends BookLoad {
  /// Membuat [BookFailed].
  const BookFailed();
}

/// Pintu sampul dan rapor ke data dan tindakan di luar fitur (ADR-045, ADR-030).
abstract interface class PeriodBookReadAccess {
  /// Membuka buku [periodId]: mengecek gerbang di sini (BP-10), menandai dibuka,
  /// mencetak stempel periode ke sampul (permanen), dan melipat perayaan stempel
  /// terpisah ke sampul (BP-13). Hanya membaca data keuangan.
  Future<BookLoad> open(String periodId);

  /// Membuka penyunting transaksi tanpa kategori pertama di periode itu
  /// ("Beri kategori" di catatan netral).
  Future<void> categorizeFirstUntagged(BuildContext context, String periodId);
}
