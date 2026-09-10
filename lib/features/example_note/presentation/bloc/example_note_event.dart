part of 'example_note_bloc.dart';

/// Event [ExampleNoteBloc].
sealed class ExampleNoteEvent {
  /// Membuat [ExampleNoteEvent].
  const ExampleNoteEvent();
}

/// Memuat seluruh catatan tersimpan.
final class ExampleNoteStarted extends ExampleNoteEvent {
  /// Membuat [ExampleNoteStarted].
  const ExampleNoteStarted();
}

/// Menambah catatan baru berisi [text].
final class ExampleNoteAdded extends ExampleNoteEvent {
  /// Membuat [ExampleNoteAdded].
  const ExampleNoteAdded(this.text);

  /// Isi catatan yang ditambahkan.
  final String text;
}
