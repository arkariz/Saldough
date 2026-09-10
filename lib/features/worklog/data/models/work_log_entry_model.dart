import 'package:saldough/features/worklog/domain/entities/work_log_entry.dart';

/// Model serialisasi [WorkLogEntry].
final class WorkLogEntryModel {
  /// Membuat [WorkLogEntryModel].
  const WorkLogEntryModel({
    required this.id,
    required this.date,
    required this.hours,
    required this.startsNewBook,
  });

  /// Membaca [WorkLogEntryModel] dari JSON.
  factory WorkLogEntryModel.fromJson(Map<String, dynamic> json) => WorkLogEntryModel(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        hours: json['hours'] as int,
        startsNewBook: json['startsNewBook'] as bool,
      );

  /// Membuat model dari entitas domain.
  factory WorkLogEntryModel.fromEntity(WorkLogEntry entry) => WorkLogEntryModel(
        id: entry.id,
        date: entry.date,
        hours: entry.hours,
        startsNewBook: entry.startsNewBook,
      );

  /// Identitas entri.
  final String id;

  /// Tanggal kerja.
  final DateTime date;

  /// Jumlah jam.
  final int hours;

  /// True kalau entri ini memulai periode tagihan baru.
  final bool startsNewBook;

  /// Menulis [WorkLogEntryModel] ke JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'hours': hours,
        'startsNewBook': startsNewBook,
      };

  /// Mengubah model jadi entitas domain.
  WorkLogEntry toEntity() =>
      WorkLogEntry(id: id, date: date, hours: hours, startsNewBook: startsNewBook);
}
