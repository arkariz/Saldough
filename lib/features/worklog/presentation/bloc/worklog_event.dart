part of 'worklog_bloc.dart';

/// Event [WorklogBloc].
sealed class WorklogEvent {
  /// Membuat [WorklogEvent].
  const WorklogEvent();
}

/// Memuat daftar sumber pemasukan freelance.
final class WorklogOpened extends WorklogEvent {
  /// Membuat [WorklogOpened].
  const WorklogOpened();
}

/// Memilih sumber ber-`id` [sourceId] dan memuat buku-bukunya.
final class WorklogSourceSelected extends WorklogEvent {
  /// Membuat [WorklogSourceSelected].
  const WorklogSourceSelected(this.sourceId);

  /// Identitas sumber.
  final String sourceId;
}

/// Mencatat satu entri jam kerja (FR-TIME-001).
final class WorkLogEntryAdded extends WorklogEvent {
  /// Membuat [WorkLogEntryAdded].
  const WorkLogEntryAdded({required this.date, required this.hours, required this.startsNewBook});

  /// Tanggal kerja.
  final DateTime date;

  /// Jumlah jam.
  final int hours;

  /// True kalau entri ini memulai periode tagihan baru.
  final bool startsNewBook;
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
