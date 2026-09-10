import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/features/example_note/data/models/example_note_model.dart';
import 'package:saldough/features/example_note/domain/entities/example_note.dart';
import 'package:saldough/features/example_note/domain/repositories/example_note_repository.dart';

const _notesKey = StorageKey(namespace: 'example_note', name: 'all');

/// Implementasi [ExampleNoteRepository] di atas [KeyValueStorage].
final class ExampleNoteRepositoryImpl with RepositoryGuard implements ExampleNoteRepository {
  /// Membuat [ExampleNoteRepositoryImpl] di atas [_storage].
  const ExampleNoteRepositoryImpl({required this._storage});

  final KeyValueStorage _storage;

  StoredValue<List<ExampleNoteModel>> get _store => StoredValue<List<ExampleNoteModel>>.json(
        key: _notesKey,
        fromJson: (json) => (json['items'] as List<dynamic>)
            .map((e) => ExampleNoteModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        toJson: (models) => {
          'schemaVersion': ExampleNoteModel.schemaVersion,
          'items': models.map((m) => m.toJson()).toList(),
        },
        storage: _storage,
      );

  @override
  Future<Either<Failure, List<ExampleNote>>> listNotes() => guard(() async {
        final models = await _store.read();
        return (models ?? const []).map((m) => m.toEntity()).toList();
      });

  @override
  Future<Either<Failure, ExampleNote>> addNote(String text) => guard(() async {
        final models = await _store.read() ?? <ExampleNoteModel>[];
        final note = ExampleNote(id: DateTime.now().microsecondsSinceEpoch.toString(), text: text);
        await _store.write([...models, ExampleNoteModel.fromEntity(note)]);
        return note;
      });
}
