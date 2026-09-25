import 'package:dependencies/dependencies.dart';

/// Satu catatan kerja freelance: proyek, tanggal, jam, dan tarifnya.
/// Lihat DOMAIN_MODEL.md bagian "Worklog".
///
/// ⚠ Entri worklog **tidak pernah** menyentuh saldo dompet mana pun. Kerja
/// selesai bukan uang diterima (aturan 6 CLAUDE.md).
///
/// [hourlyRate] disalin dari proyek saat entri dicatat (ADR-019). Status,
/// tanggal pembayaran, dan dompet tujuan TIDAK disimpan di sini — semuanya
/// diturunkan lewat [paymentId].
final class WorklogEntry extends Equatable {
  /// Membuat [WorklogEntry].
  const WorklogEntry({
    required this.id,
    required this.projectId,
    required this.date,
    required this.hours,
    required this.hourlyRate,
    this.note,
    this.paymentId,
  }) : assert(hours > 0, 'Jam kerja harus positif.');

  /// Identitas entri.
  final String id;

  /// Proyek yang dikerjakan.
  final String projectId;

  /// Tanggal kerja.
  final DateTime date;

  /// Jumlah jam.
  final int hours;

  /// Tarif per jam yang dipakai entri ini, dalam sen.
  final int hourlyRate;

  /// Catatan bebas tentang apa yang dikerjakan.
  final String? note;

  /// Pembayaran yang menagihkan entri ini; `null` = belum ditagihkan.
  final String? paymentId;

  /// Nominal yang diperoleh, dalam sen: `hours × hourlyRate`.
  int get earnedAmount => hours * hourlyRate;

  /// Apakah entri ini sudah masuk sebuah pembayaran. Entri yang sudah
  /// ditagihkan tidak bisa disunting atau dihapus (FR-FRL-002).
  bool get isBilled => paymentId != null;

  /// Salinan [WorklogEntry] dengan field yang disebutkan diganti. [note] dan
  /// [paymentId] memakai fungsi supaya bisa dikosongkan.
  WorklogEntry copyWith({
    String? projectId,
    DateTime? date,
    int? hours,
    int? hourlyRate,
    String? Function()? note,
    String? Function()? paymentId,
  }) {
    return WorklogEntry(
      id: id,
      projectId: projectId ?? this.projectId,
      date: date ?? this.date,
      hours: hours ?? this.hours,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      note: note != null ? note() : this.note,
      paymentId: paymentId != null ? paymentId() : this.paymentId,
    );
  }

  @override
  List<Object?> get props => [id, projectId, date, hours, hourlyRate, note, paymentId];
}
