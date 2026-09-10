import 'package:api_storage/api_storage.dart';
import 'package:di/di.dart';
import 'package:saldough/features/example_note/data/repositories/example_note_repository_impl.dart';
import 'package:saldough/features/example_note/domain/repositories/example_note_repository.dart';
import 'package:saldough/features/example_note/presentation/bloc/example_note_bloc.dart';

/// Lingkup dependensi fitur `example_note`. Lihat ARCHITECTURE_OVERVIEW.md
/// bagian "Injeksi dependensi" — kontainer baru tidak mewarisi apa pun,
/// sehingga dependensi induk (di sini: [KeyValueStorage]) harus dibawa
/// eksplisit lewat [bridge].
final class ExampleNoteScope extends IsolatedScope {
  /// Membuat [ExampleNoteScope] dengan kontainer induk [parentContainer].
  ExampleNoteScope({required super.parentContainer});

  @override
  void bridge(GetIt c) {
    c.registerSingleton<KeyValueStorage>(parent<KeyValueStorage>());
  }

  @override
  void register(GetIt c) {
    c.registerLazySingleton<ExampleNoteRepository>(
      () => ExampleNoteRepositoryImpl(storage: c<KeyValueStorage>()),
    );
    c.registerLazySingleton<ExampleNoteBloc>(
      () => ExampleNoteBloc(repository: c<ExampleNoteRepository>())..add(const ExampleNoteStarted()),
      dispose: (bloc) => bloc.close(),
    );
  }
}
