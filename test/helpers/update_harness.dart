import 'dart:async';

import 'package:dependencies/dependencies.dart';
import 'package:di/di.dart';
import 'package:failures/failures.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saldough/features/app_update/domain/entities/app_update_memory.dart';
import 'package:saldough/features/app_update/domain/entities/app_version.dart';
import 'package:saldough/features/app_update/domain/entities/release_note.dart';
import 'package:saldough/features/app_update/domain/entities/update_snapshot.dart';
import 'package:saldough/features/app_update/domain/repositories/app_update_memory_repository.dart';
import 'package:saldough/features/app_update/domain/repositories/release_notes_source.dart';
import 'package:saldough/features/app_update/domain/repositories/update_sources.dart';
import 'package:saldough/features/app_update/domain/usecases/read_update_snapshot.dart';
import 'package:saldough/features/app_update/presentation/bloc/app_update_bloc.dart';

class _MockInstalled extends Mock implements InstalledVersionSource {}

class _MockStore extends Mock implements StoreUpdateSource {}

class _MockPatch extends Mock implements PatchSource {}

class _MockMemory extends Mock implements AppUpdateMemoryRepository {}

/// Catatan palsu: entri dan status server bisa diatur; `refresh` dicatat.
final class FakeReleaseNotes implements ReleaseNotesSource {
  /// Entri yang dikenal.
  Map<ReleaseKey, ReleaseNote> entries = {};

  /// Server sudah terbaca.
  bool serverRead = true;

  /// Entri yang baru muncul sesudah `refresh` (mensimulasikan pengambilan).
  Map<ReleaseKey, ReleaseNote> onRefresh = {};

  /// Jeda `refresh` (mensimulasikan jaringan lambat).
  Duration refreshDelay = Duration.zero;

  /// Berapa kali `refresh` true dipanggil.
  int refreshCalls = 0;

  /// Sinyal perubahan langsung.
  final changesController = StreamController<void>.broadcast();

  @override
  Stream<void> get changes => changesController.stream;

  @override
  Future<Either<Failure, ReleaseNotesSnapshot>> load({required AppVersion running, bool refresh = true}) async {
    if (refresh) {
      refreshCalls++;
      if (refreshDelay > Duration.zero) await Future<void>.delayed(refreshDelay);
      entries = {...entries, ...onRefresh};
    }
    return right(ReleaseNotesSnapshot(entries: Map.of(entries), serverRead: serverRead));
  }
}

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
    // Sudah pernah melihat versi ini: tanpa lembar dan tanpa penyimpanan tambahan.
    when(memory.load).thenAnswer((_) async => right(AppUpdateMemory.empty.see(7, 0)));
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

  /// Catatan palsu.
  final notes = FakeReleaseNotes();

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
      notes: notes,
    ),
  );

  /// Menutup bloc yang dibuat.
  Future<void> dispose() async => created?.close();
}
