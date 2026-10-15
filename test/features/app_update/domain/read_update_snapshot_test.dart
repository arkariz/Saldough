import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saldough/features/app_update/domain/entities/app_version.dart';
import 'package:saldough/features/app_update/domain/entities/update_snapshot.dart';
import 'package:saldough/features/app_update/domain/repositories/update_sources.dart';
import 'package:saldough/features/app_update/domain/usecases/read_update_snapshot.dart';

class _MockInstalled extends Mock implements InstalledVersionSource {}

class _MockStore extends Mock implements StoreUpdateSource {}

class _MockPatch extends Mock implements PatchSource {}

/// Sumber yang gagal menjadi "tidak diketahui", bukan galat ke UI (B-5).
void main() {
  late _MockInstalled installed;
  late _MockStore store;
  late _MockPatch patch;
  late ReadUpdateSnapshot read;

  const failure = SystemFailure(code: FailureCode.unknown, message: 'gagal');

  setUp(() {
    installed = _MockInstalled();
    store = _MockStore();
    patch = _MockPatch();
    read = ReadUpdateSnapshot(installed: installed, store: store, patch: patch);
    when(() => installed.read()).thenAnswer((_) async => right((name: '0.6.0', build: 7)));
    when(() => store.check()).thenAnswer((_) async => right(const StoreUpdateInfo(stage: StoreUpdateStage.none)));
    when(() => patch.read()).thenAnswer((_) async => right(const PatchState(current: 1, next: 2)));
  });

  Future<UpdateSnapshot> snapshot({bool checkStore = true}) async =>
      (await read(checkStore: checkStore)).getOrElse((_) => throw StateError('Left'));

  test('menggabungkan versi, Play, dan Shorebird; nomor tambalan masuk ke versi', () async {
    final s = await snapshot();
    expect(s.version, const AppVersion(name: '0.6.0', build: 7, patch: 1));
    expect(s.store.stage, StoreUpdateStage.none);
    expect(s.patch.ready, 2);
  });

  test('Play gagal: tidak diketahui, Shorebird tetap terbaca', () async {
    when(() => store.check()).thenAnswer((_) async => left(failure));
    final s = await snapshot();
    expect(s.store, StoreUpdateInfo.unknown);
    expect(s.patch.ready, 2);
  });

  test('Play gagal: alasannya dibawa sebagai diagnostik (tidak ke antarmuka)', () async {
    when(() => store.check()).thenAnswer((_) async => left(failure));
    final s = await snapshot();
    expect(s.store.stage, StoreUpdateStage.unknown);
    expect(s.store.diagnostic, contains('gagal dicek'));
    expect(s.store.diagnostic, contains('gagal'));
  });

  test('Shorebird gagal: tanpa tambalan', () async {
    when(() => patch.read()).thenAnswer((_) async => left(failure));
    final s = await snapshot();
    expect(s.patch, PatchState.none);
    expect(s.version.patch, 0);
  });

  test('checkStore false melewati Play', () async {
    final s = await snapshot(checkStore: false);
    expect(s.store, StoreUpdateInfo.unknown);
    verifyNever(() => store.check());
  });

  test('versi terpasang gagal dibaca: Left', () async {
    when(() => installed.read()).thenAnswer((_) async => left(failure));
    expect((await read()).isLeft(), isTrue);
  });
}
