import 'dart:async';

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saldough/features/app_update/domain/entities/app_update_memory.dart';
import 'package:saldough/features/app_update/domain/entities/update_snapshot.dart';
import 'package:saldough/features/app_update/domain/repositories/app_update_memory_repository.dart';
import 'package:saldough/features/app_update/domain/repositories/update_sources.dart';
import 'package:saldough/features/app_update/domain/services/update_policy.dart';
import 'package:saldough/features/app_update/domain/usecases/read_update_snapshot.dart';
import 'package:saldough/features/app_update/presentation/bloc/app_update_bloc.dart';

class _MockInstalled extends Mock implements InstalledVersionSource {}

class _MockStore extends Mock implements StoreUpdateSource {}

class _MockPatch extends Mock implements PatchSource {}

class _MockMemory extends Mock implements AppUpdateMemoryRepository {}

/// Bloc pengumuman pembaruan: aturan B-3..B-8 dan B-13 lewat sumber palsu.
void main() {
  late _MockInstalled installed;
  late _MockStore store;
  late _MockPatch patch;
  late _MockMemory memory;
  late StreamController<StoreUpdateStage> stages;
  late DateTime now;
  late AppUpdateBloc bloc;

  const failure = SystemFailure(code: FailureCode.unknown, message: 'gagal');
  const available = StoreUpdateInfo(stage: StoreUpdateStage.available, availableBuild: 7);

  setUpAll(() => registerFallbackValue(AppUpdateMemory.empty));

  setUp(() {
    installed = _MockInstalled();
    store = _MockStore();
    patch = _MockPatch();
    memory = _MockMemory();
    stages = StreamController<StoreUpdateStage>.broadcast();
    now = DateTime(2026, 10, 15, 9);
    when(() => installed.read()).thenAnswer((_) async => right((name: '0.5.0', build: 6)));
    when(() => store.check()).thenAnswer((_) async => right(available));
    when(() => store.watch()).thenAnswer((_) => stages.stream);
    when(() => store.startDownload()).thenAnswer((_) async => right(true));
    when(() => store.completeInstall()).thenAnswer((_) async => right(unit));
    when(() => patch.read()).thenAnswer((_) async => right(PatchState.none));
    when(() => memory.load()).thenAnswer((_) async => right(AppUpdateMemory.empty));
    when(() => memory.save(any())).thenAnswer((_) async => right(unit));
    bloc = AppUpdateBloc(
      read: ReadUpdateSnapshot(installed: installed, store: store, patch: patch),
      store: store,
      memory: memory,
      now: () => now,
    );
  });

  tearDown(() async {
    await bloc.close();
    await stages.close();
  });

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  Future<void> check({bool force = false}) async {
    bloc.add(AppUpdateChecked(force: force));
    await settle();
    await settle();
  }

  test('versi baru tersedia: banner "tersedia"', () async {
    await check();
    expect(bloc.state.announcement, UpdateAnnouncement.storeAvailable);
    expect(bloc.state.status, VersionStatus.available);
  });

  test('B-5: Play dan Shorebird gagal, tetap diam tanpa efek galat', () async {
    when(() => store.check()).thenAnswer((_) async => left(failure));
    when(() => patch.read()).thenAnswer((_) async => left(failure));
    await check();
    expect(bloc.state.announcement, UpdateAnnouncement.none);
    expect(bloc.state.effect, isNull);
  });

  test('B-5: versi terpasang gagal dibaca, diam', () async {
    when(() => installed.read()).thenAnswer((_) async => left(failure));
    await check();
    expect(bloc.state.announcement, UpdateAnnouncement.none);
    expect(bloc.state.status, VersionStatus.unknown);
  });

  test('ingatan gagal dibaca dianggap kosong, pengumuman tetap jalan', () async {
    when(() => memory.load()).thenAnswer((_) async => left(failure));
    await check();
    expect(bloc.state.announcement, UpdateAnnouncement.storeAvailable);
  });

  test('B-13: pengecekan Play dibatasi 6 jam kecuali force; keadaan Play dipertahankan', () async {
    await check();
    now = now.add(const Duration(hours: 1));
    await check();
    verify(() => store.check()).called(1);
    expect(bloc.state.announcement, UpdateAnnouncement.storeAvailable);

    now = now.add(const Duration(hours: 5));
    await check();
    verify(() => store.check()).called(1);

    await check(force: true);
    verify(() => store.check()).called(1);
  });

  test('B-6: Nanti menunda build itu dan menyimpannya; 7 hari kemudian tampil lagi', () async {
    await check();
    bloc.add(const AppUpdateDeferred());
    await settle();
    expect(bloc.state.announcement, UpdateAnnouncement.none);
    expect(bloc.state.status, VersionStatus.available, reason: 'Akun tetap menyebutnya');
    verify(
      () => memory.save(any(that: isA<AppUpdateMemory>().having((m) => m.deferredBuild, 'deferredBuild', 7))),
    ).called(1);

    now = now.add(const Duration(days: 7));
    await check(force: true);
    expect(bloc.state.announcement, UpdateAnnouncement.storeAvailable);
  });

  test('Perbarui memulai unduhan; aliran Play menggeser banner ke mengunduh lalu sudah diunduh', () async {
    await check();
    bloc.add(const AppUpdateDownloadRequested());
    await settle();
    verify(() => store.startDownload()).called(1);

    stages.add(StoreUpdateStage.downloading);
    await settle();
    expect(bloc.state.announcement, UpdateAnnouncement.storeDownloading);

    stages.add(StoreUpdateStage.downloaded);
    await settle();
    expect(bloc.state.announcement, UpdateAnnouncement.storeDownloaded);
  });

  test('pengguna menolak dialog Play: tetap tersedia, tanpa galat', () async {
    when(() => store.startDownload()).thenAnswer((_) async => right(false));
    await check();
    bloc.add(const AppUpdateDownloadRequested());
    await settle();
    expect(bloc.state.announcement, UpdateAnnouncement.storeAvailable);
    expect(bloc.state.busy, isFalse);
    expect(bloc.state.effect, isNull);
  });

  test('unduhan gagal (aliran Play): kembali ke tersedia', () async {
    await check();
    stages
      ..add(StoreUpdateStage.downloading)
      ..add(StoreUpdateStage.available);
    await settle();
    expect(bloc.state.announcement, UpdateAnnouncement.storeAvailable);
  });

  test('B-7: Pasang sekarang hanya jalan bila sudah diunduh, dan hanya dari event', () async {
    await check();
    bloc.add(const AppUpdateInstallRequested());
    await settle();
    verifyNever(() => store.completeInstall());

    stages.add(StoreUpdateStage.downloaded);
    await settle();
    verifyNever(() => store.completeInstall());

    bloc.add(const AppUpdateInstallRequested());
    await settle();
    verify(() => store.completeInstall()).called(1);
  });

  group('pembaruan kecil', () {
    setUp(
      () =>
          when(() => store.check()).thenAnswer((_) async => right(const StoreUpdateInfo(stage: StoreUpdateStage.none))),
    );

    test('siap: banner; Oke menyimpan dan tidak tampil lagi (B-8)', () async {
      when(() => patch.read()).thenAnswer((_) async => right(const PatchState(next: 1)));
      await check();
      expect(bloc.state.announcement, UpdateAnnouncement.patchReady);

      bloc.add(const AppUpdatePatchAcknowledged());
      await settle();
      expect(bloc.state.announcement, UpdateAnnouncement.none);
      verify(
        () => memory.save(any(that: isA<AppUpdateMemory>().having((m) => m.announcedPatches, 'announced', {6: 1}))),
      ).called(1);

      await check(force: true);
      expect(bloc.state.announcement, UpdateAnnouncement.none);
    });

    test('B-4: versi baru ada, hanya versi baru yang diumumkan', () async {
      when(() => store.check()).thenAnswer((_) async => right(available));
      when(() => patch.read()).thenAnswer((_) async => right(const PatchState(current: 1, next: 2)));
      await check();
      expect(bloc.state.announcement, UpdateAnnouncement.storeAvailable);
    });

    test('rollback: tidak ada banner dan tidak ada galat', () async {
      when(() => patch.read()).thenAnswer((_) async => right(const PatchState(current: 2, next: 1)));
      await check();
      expect(bloc.state.announcement, UpdateAnnouncement.none);
    });
  });
}
