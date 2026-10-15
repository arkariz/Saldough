import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/features/app_update/data/release_notes_repository_impl.dart';
import 'package:saldough/features/app_update/data/remote_config_gateway.dart';
import 'package:saldough/features/app_update/domain/entities/app_version.dart';
import 'package:saldough/features/app_update/domain/repositories/release_notes_source.dart';

class _FakeGateway implements RemoteConfigGateway {
  Map<String, String> values = {};
  bool fetched = false;
  Object? fetchError;
  int fetchCalls = 0;
  final controller = StreamController<void>.broadcast();

  @override
  Future<bool> fetchAndActivate() async {
    fetchCalls++;
    if (fetchError != null) throw Exception(fetchError);
    fetched = true;
    return true;
  }

  @override
  Map<String, String> noteValues() => values;

  @override
  bool get hasFetched => fetched;

  @override
  Stream<void> get updates => controller.stream;
}

String _json(String version) => '{"version":"$version","groups":[{"category":"new","notes":[{"id":"A","en":"A"}]}]}';

/// Rantai nilai aktif → salinan lokal → kosong (ADR-039 §3.3 butir 4).
void main() {
  late _FakeGateway gateway;
  late InMemoryKeyValueStorage storage;
  late ReleaseNotesRepositoryImpl repository;
  const running = AppVersion(name: '0.6.0', build: 7);

  setUp(() {
    gateway = _FakeGateway();
    storage = InMemoryKeyValueStorage();
    repository = ReleaseNotesRepositoryImpl(gateway: gateway, storage: storage);
  });

  Future<ReleaseNotesSnapshot> load({AppVersion version = running, bool refresh = true}) async =>
      (await repository.load(running: version, refresh: refresh)).getOrElse((_) => throw StateError('Left'));

  test('mengambil dari server lalu membaca nilai aktif; serverRead true', () async {
    gateway.values = {'whats_new_7_0': _json('0.6.0')};
    final snapshot = await load();
    expect(snapshot.entries.keys, [(build: 7, patch: 0)]);
    expect(snapshot.entries.values.single.version, '0.6.0');
    expect(snapshot.serverRead, isTrue);
    expect(gateway.fetchCalls, 1);
  });

  test('refresh false tidak menyentuh jaringan', () async {
    gateway.values = {'whats_new_7_0': _json('0.6.0')};
    await load(refresh: false);
    expect(gateway.fetchCalls, 0);
  });

  test('luring: pengambilan gagal tidak menjadi galat; serverRead false', () async {
    gateway.fetchError = 'offline';
    final snapshot = await load();
    expect(snapshot.entries, isEmpty);
    expect(snapshot.serverRead, isFalse);
  });

  test('salinan lokal bertahan sesudah entri hilang dari server dan saat luring', () async {
    gateway.values = {'whats_new_7_0': _json('0.6.0')};
    await load();
    gateway
      ..values = {}
      ..fetchError = 'offline';
    final snapshot = await load();
    expect(snapshot.entries.keys, [(build: 7, patch: 0)]);
  });

  test('nilai server menimpa salinan lama', () async {
    gateway.values = {'whats_new_7_0': _json('0.6.0')};
    await load();
    gateway.values = {'whats_new_7_0': _json('0.6.1')};
    expect((await load()).entries.values.single.version, '0.6.1');
  });

  test('hanya entri sampai versi berjalan yang disalin; entri lebih baru tidak tersimpan (yatim)', () async {
    gateway.values = {'whats_new_7_0': _json('0.6.0'), 'whats_new_8_0': _json('0.7.0')};
    final first = await load();
    expect(first.entries.keys.toSet(), {
      (build: 7, patch: 0),
      (build: 8, patch: 0),
    }, reason: 'snapshot memuat semuanya (chip)');

    gateway
      ..values = {}
      ..fetchError = 'offline';
    final second = await load();
    expect(second.entries.keys, [(build: 7, patch: 0)], reason: 'build 8 tidak pernah disalin');
  });

  test('entri rusak dan parameter lain diabaikan', () async {
    gateway.values = {
      'whats_new_7_0': _json('0.6.0'),
      'whats_new_7_1': 'bukan json',
      'whats_new_x': _json('0.6.0'),
      'whats_new_6_0_id': _json('0.5.0'),
    };
    expect((await load()).entries.keys, [(build: 7, patch: 0)]);
  });

  test('salinan rusak diabaikan dan ditimpa', () async {
    await storage.write('app_update_notes', '{bukan json');
    gateway.values = {'whats_new_7_0': _json('0.6.0')};
    expect((await load()).entries.keys, [(build: 7, patch: 0)]);
  });

  test('changes meneruskan sinyal gateway', () async {
    final signals = <void>[];
    final sub = repository.changes.listen(signals.add);
    gateway.controller.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(signals, hasLength(1));
    await sub.cancel();
  });
}
