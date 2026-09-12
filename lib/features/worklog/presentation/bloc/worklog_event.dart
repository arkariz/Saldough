part of 'worklog_bloc.dart';

/// Event [WorklogBloc].
sealed class WorklogEvent {
  /// Membuat [WorklogEvent].
  const WorklogEvent();
}

/// Memuat daftar sumber pemasukan freelance.
final class WorklogOpened extends WorklogEvent {
  /// Membuat [WorklogOpened].
  const WorklogOpened({this.initialSourceId});

  /// Sumber yang langsung dipilih, kalau layar ini dicapai dari tile sumber
  /// tertentu di `IncomeSourceListPage` (laporan pemilik: sebelumnya selalu
  /// lompat ke sumber freelance PERTAMA, walau pemilik menekan tombol milik
  /// sumber yang berbeda). `null` (atau id yang tidak ditemukan) jatuh balik
  /// ke sumber freelance pertama, perilaku lama.
  final String? initialSourceId;
}

/// Memilih sumber ber-`id` [sourceId] dan memuat buku-bukunya.
final class WorklogSourceSelected extends WorklogEvent {
  /// Membuat [WorklogSourceSelected].
  const WorklogSourceSelected(this.sourceId);

  /// Identitas sumber.
  final String sourceId;
}

/// Mencatat satu entri jam kerja (FR-TIME-001).
///
/// Selalu menyambung ke buku terbuka kalau ada, atau memulai buku baru kalau
/// tidak ada -- layar ini sengaja tidak lagi menawarkan pilihan "mulai buku
/// baru" secara manual saat masih ada buku terbuka (laporan pemilik: pilihan
/// itu sendiri yang membingungkan). Tutup buku dulu lewat [BillingBookClosed]
/// untuk benar-benar memulai yang baru.
final class WorkLogEntryAdded extends WorklogEvent {
  /// Membuat [WorkLogEntryAdded].
  const WorkLogEntryAdded({required this.date, required this.hours});

  /// Tanggal kerja.
  final DateTime date;

  /// Jumlah jam.
  final int hours;
}

/// Mengubah jumlah jam entri ber-`id` [entryId] pada buku TERBUKA ber-`id`
/// [bookId] (laporan pemilik: sebelumnya tidak ada cara membetulkan jam yang
/// salah ketik). Diabaikan kalau buku itu sudah tertutup -- buku tertutup
/// dibekukan, sama seperti siklus yang sudah ditutup (ADR-0008).
final class WorkLogEntryUpdated extends WorklogEvent {
  /// Membuat [WorkLogEntryUpdated].
  const WorkLogEntryUpdated({required this.bookId, required this.entryId, required this.hours});

  /// Identitas buku, harus masih terbuka.
  final String bookId;

  /// Identitas entri.
  final String entryId;

  /// Jumlah jam baru.
  final int hours;
}

/// Menghapus entri ber-`id` [entryId] dari buku TERBUKA ber-`id` [bookId].
/// Diabaikan kalau buku itu sudah tertutup.
final class WorkLogEntryRemoved extends WorklogEvent {
  /// Membuat [WorkLogEntryRemoved].
  const WorkLogEntryRemoved({required this.bookId, required this.entryId});

  /// Identitas buku, harus masih terbuka.
  final String bookId;

  /// Identitas entri.
  final String entryId;
}

/// Menutup buku ber-`id` [bookId], menghitung gaji bersih (FR-TIME-003).
final class BillingBookClosed extends WorklogEvent {
  /// Membuat [BillingBookClosed].
  const BillingBookClosed(this.bookId);

  /// Identitas buku.
  final String bookId;
}

/// Menyuntikkan gaji bersih buku ber-`id` [bookId] ke siklus [cycleId]
/// (T-3.9/FR-TIME-003).
final class NetPayInjected extends WorklogEvent {
  /// Membuat [NetPayInjected].
  const NetPayInjected({required this.bookId, required this.cycleId});

  /// Identitas buku, sudah harus ditutup.
  final String bookId;

  /// Identitas siklus tujuan, format `YYYY-MM`.
  final String cycleId;
}
