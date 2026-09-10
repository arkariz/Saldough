import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/example_note/domain/entities/example_note.dart';

/// Kontrak akses data [ExampleNote]. Lihat catatan di [ExampleNote] — fitur
/// bukti pola, bukan produk.
abstract interface class ExampleNoteRepository {
  /// Daftar seluruh catatan.
  Future<Either<Failure, List<ExampleNote>>> listNotes();

  /// Menambah satu catatan berisi [text].
  Future<Either<Failure, ExampleNote>> addNote(String text);
}
