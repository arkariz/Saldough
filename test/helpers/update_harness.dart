import 'package:dependencies/dependencies.dart';
import 'package:di/di.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saldough/features/app_update/domain/entities/app_update_memory.dart';
import 'package:saldough/features/app_update/domain/entities/update_snapshot.dart';
import 'package:saldough/features/app_update/domain/repositories/app_update_memory_repository.dart';
import 'package:saldough/features/app_update/domain/repositories/update_sources.dart';
import 'package:saldough/features/app_update/domain/usecases/read_update_snapshot.dart';
import 'package:saldough/features/app_update/presentation/bloc/app_update_bloc.dart';

class _MockInstalled extends Mock implements InstalledVersionSource {}

class _MockStore extends Mock implements StoreUpdateSource {}

class _MockPatch extends Mock implements PatchSource {}

class _MockMemory extends Mock implements AppUpdateMemoryRepository {}

Stream<StoreUpdateStage> _noStages(Invocation _) => const Stream<StoreUpdateStage>.empty();

/// Sumber pembaruan palsu dan [AppUpdateBloc] sungguhan di atasnya untuk uji
/// widget (ADR-039). Bloc dibuat malas supaya hidup di zona uji widget:
/// daftarkan [register] ke container, jangan membangun bloc di `setUp`.
final class UpdateHarness {
  /// Membuat harness dengan keadaan awal: versi `0.6.0+7`, Play dan Shorebird
  /// tanpa pembaruan.
  UpdateHarness() {
    when(installed.read).thenAnswer((_) async => right((name: '0.6.0', build: 7)));
    when(store.watch).thenAnswer(_noStages);
    when(store.startDownload).thenAnswer((_) async => right(true));
    when(store.completeInstall).thenAnswer((_) async => right(unit));
    when(memory.load).thenAnswer((_) async => right(AppUpdateMemory.empty));
    when(() => memory.save(any())).thenAnswer((_) async => right(unit));
    set();
  }

  /// Versi terpasang palsu.
  final installed = _MockInstalled();

  /// Play palsu.
  final store = _MockStore();

  /// Shorebird palsu.
  final patch = _MockPatch();

  /// Ingatan palsu.
  final memory = _MockMemory();

  /// Bloc yang sudah dibuat, untuk ditutup di `tearDown`.
  AppUpdateBloc? created;

  /// Mengatur keadaan Play dan Shorebird.
  void set({StoreUpdateInfo? play, PatchState patchState = PatchState.none}) {
    when(store.check).thenAnswer((_) async => right(play ?? const StoreUpdateInfo(stage: StoreUpdateStage.none)));
    when(patch.read).thenAnswer((_) async => right(patchState));
  }

  /// Mendaftarkan bloc malas ke [container].
  void register(GetIt container) => container.registerLazySingleton<AppUpdateBloc>(
    () => created = AppUpdateBloc(
      read: ReadUpdateSnapshot(installed: installed, store: store, patch: patch),
      store: store,
      memory: memory,
    ),
  );

  /// Menutup bloc yang dibuat.
  Future<void> dispose() async => created?.close();
}
