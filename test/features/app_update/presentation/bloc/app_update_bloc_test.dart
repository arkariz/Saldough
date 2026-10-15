import 'dart:async';

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saldough/features/app_update/domain/entities/app_update_memory.dart';
import 'package:saldough/features/app_update/domain/entities/release_note.dart';
import 'package:saldough/features/app_update/domain/entities/update_snapshot.dart';
import 'package:saldough/features/app_update/domain/repositories/app_update_memory_repository.dart';
import 'package:saldough/features/app_update/domain/repositories/update_sources.dart';
import 'package:saldough/features/app_update/domain/services/update_policy.dart';
import 'package:saldough/features/app_update/domain/usecases/read_update_snapshot.dart';
import 'package:saldough/features/app_update/presentation/bloc/app_update_bloc.dart';

import '../../../../helpers/update_harness.dart';

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
  late FakeReleaseNotes notes;
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
    notes = FakeReleaseNotes();
    stages = StreamController<StoreUpdateStage>.broadcast();
    now = DateTime(2026, 10, 15, 9);
    when(() => installed.read()).thenAnswer((_) async => right((name: '0.5.0', build: 6)));
    when(() => store.check()).thenAnswer((_) async => right(available));
    when(() => store.watch()).thenAnswer((_) => stages.stream);
    when(() => store.startDownload()).thenAnswer((_) async => right(true));
    when(() => store.completeInstall()).thenAnswer((_) async => right(unit));
    when(() => patch.read()).thenAnswer((_) async => right(PatchState.none));
    when(() => memory.load()).thenAnswer((_) async => right(AppUpdateMemory.empty.see(6, 0)));
    when(() => memory.save(any())).thenAnswer((_) async => right(unit));
    bloc = AppUpdateBloc(
      read: ReadUpdateSnapshot(installed: installed, store: store, patch: patch),
      store: store,
      memory: memory,
      notes: notes,
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

  group('catatan Apa yang baru dan chip versi (ADR-039 §3.3)', () {
    ReleaseNote note(int build, int patch, String version) => ReleaseNote(
      build: build,
      patch: patch,
      version: version,
      groups: [
        NoteGroup(
          category: NoteCategory.newFeature,
          notes: [LocalizedNote(id: '$version/$patch', en: '$version/$patch')],
        ),
      ],
    );

    void entries(List<ReleaseNote> list) => notes.entries = {for (final n in list) n.key: n};

    test('pemasangan pertama: tanpa lembar, versi terakhir dilihat disimpan', () async {
      when(() => memory.load()).thenAnswer((_) async => right(AppUpdateMemory.empty));
      entries([note(6, 0, '0.5.0')]);
      await check();
      expect(bloc.state.whatsNew, isEmpty);
      verify(
        () => memory.save(any(that: isA<AppUpdateMemory>().having((m) => m.lastSeenBuild, 'lastSeenBuild', 6))),
      ).called(1);
    });

    test('6 → 7: lembar versi 7 menunggu, dan tidak disimpan sampai dilihat', () async {
      when(() => memory.load()).thenAnswer((_) async => right(AppUpdateMemory.empty.see(5, 0)));
      entries([note(5, 0, '0.4.0'), note(6, 0, '0.5.0')]);
      await check();
      expect([for (final n in bloc.state.whatsNew) n.key], [(build: 6, patch: 0)]);
      verifyNever(() => memory.save(any()));

      bloc.add(const AppUpdateWhatsNewSeen());
      await settle();
      expect(bloc.state.whatsNew, isEmpty);
      verify(
        () => memory.save(any(that: isA<AppUpdateMemory>().having((m) => m.lastSeenBuild, 'lastSeenBuild', 6))),
      ).called(1);
    });

    test('catatan belum terambil: lembar ditunda dan versi terakhir dilihat tidak maju', () async {
      when(() => memory.load()).thenAnswer((_) async => right(AppUpdateMemory.empty.see(5, 0)));
      notes.serverRead = false;
      await check();
      expect(bloc.state.whatsNew, isEmpty);
      verifyNever(() => memory.save(any()));

      // Catatan tiba kemudian: lembar tampil sekali.
      notes
        ..serverRead = true
        ..entries = {(build: 6, patch: 0): note(6, 0, '0.5.0')};
      notes.changesController.add(null);
      await settle();
      await settle();
      expect(bloc.state.whatsNew, hasLength(1));
    });

    test('daftar catatan terpasang di Akun: terbaru di atas, tanpa entri yang belum terpasang', () async {
      entries([note(5, 0, '0.4.0'), note(6, 0, '0.5.0'), note(7, 0, '0.6.0')]);
      await check();
      expect([for (final n in bloc.state.installedNotes) n.build], [6, 5]);
    });

    test('chip: entri build yang ditawarkan Play ada, versinya tampil', () async {
      entries([note(7, 0, '0.6.0')]);
      when(() => store.check()).thenAnswer(
        (_) async => right(const StoreUpdateInfo(stage: StoreUpdateStage.available, availableBuild: 7)),
      );
      await check();
      expect(bloc.state.availableVersion, '0.6.0');
    });

    test('chip: entri belum ada tetapi tiba dalam batas tunggu, banner langsung bersama chip', () async {
      notes
        ..onRefresh = {(build: 7, patch: 0): note(7, 0, '0.6.0')}
        ..refreshDelay = const Duration(milliseconds: 20);
      bloc.add(const AppUpdateChecked());
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(bloc.state.availableVersion, '0.6.0');
      expect(bloc.state.announcement, UpdateAnnouncement.storeAvailable);
    });

    test('chip: terlambat melewati batas tunggu, banner tampil tanpa chip dan chip menyusul', () async {
      final slow = AppUpdateBloc(
        read: ReadUpdateSnapshot(installed: installed, store: store, patch: patch),
        store: store,
        memory: memory,
        notes: notes,
        now: () => now,
        waitForChip: const Duration(milliseconds: 10),
      );
      addTearDown(slow.close);
      notes
        ..onRefresh = {(build: 7, patch: 0): note(7, 0, '0.6.0')}
        ..refreshDelay = const Duration(milliseconds: 80);
      slow.add(const AppUpdateChecked());
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(
        slow.state.announcement,
        UpdateAnnouncement.storeAvailable,
        reason: 'banner tidak menunggu lebih dari batas',
      );
      expect(slow.state.availableVersion, isNull);

      await Future<void>.delayed(const Duration(milliseconds: 120));
      slow.add(const AppUpdateChecked(force: true));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(slow.state.availableVersion, '0.6.0');
    });

    test('chip: tanpa chip bila tidak ada versi baru dari Play', () async {
      when(() => store.check()).thenAnswer((_) async => right(const StoreUpdateInfo(stage: StoreUpdateStage.none)));
      entries([note(7, 0, '0.6.0')]);
      await check();
      expect(bloc.state.availableVersion, isNull);
    });
  });
}
