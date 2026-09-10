import 'package:saldough/features/example_note/domain/entities/example_note.dart';

/// Model serialisasi [ExampleNote].
final class ExampleNoteModel {
  /// Membuat [ExampleNoteModel].
  const ExampleNoteModel({required this.id, required this.text});

  /// Membaca [ExampleNoteModel] dari JSON.
  factory ExampleNoteModel.fromJson(Map<String, dynamic> json) => ExampleNoteModel(
        id: json['id'] as String,
        text: json['text'] as String,
      );

  /// Membuat model dari entitas domain.
  factory ExampleNoteModel.fromEntity(ExampleNote note) =>
      ExampleNoteModel(id: note.id, text: note.text);

  /// Versi skema dokumen ini.
  static const schemaVersion = 1;

  /// Identitas catatan.
  final String id;

  /// Isi catatan.
  final String text;

  /// Menulis [ExampleNoteModel] ke JSON.
  Map<String, dynamic> toJson() => {'id': id, 'text': text};

  /// Mengubah model jadi entitas domain.
  ExampleNote toEntity() => ExampleNote(id: id, text: text);
}
