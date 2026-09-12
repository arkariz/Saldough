import 'package:dependencies/dependencies.dart';

/// Satu hari kerja tercatat pada sebuah `BillingBook`.
final class WorkLogEntry extends Equatable {
  /// Membuat [WorkLogEntry].
  const WorkLogEntry({
    required this.id,
    required this.date,
    required this.hours,
    this.startsNewBook = false,
  });

  /// Identitas entri.
  final String id;

  /// Tanggal kerja.
  final DateTime date;

  /// Jumlah jam.
  final int hours;

  /// True kalau entri ini memulai periode tagihan baru (ADR lihat
  /// DOMAIN_MODEL.md bagian "Catatan jam dan buku jam").
  final bool startsNewBook;

  /// Salinan [WorkLogEntry] dengan [hours] diganti — dipakai menyunting
  /// entri pada buku yang masih terbuka (laporan pemilik: sebelumnya tidak
  /// ada cara memperbaiki jam yang salah ketik selain membiarkannya).
  WorkLogEntry copyWith({int? hours}) {
    return WorkLogEntry(id: id, date: date, hours: hours ?? this.hours, startsNewBook: startsNewBook);
  }

  @override
  List<Object?> get props => [id, date, hours, startsNewBook];
}
