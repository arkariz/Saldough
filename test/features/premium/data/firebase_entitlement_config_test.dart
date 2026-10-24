import 'dart:async';
import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/features/premium/data/firebase_entitlement_config.dart';

class _MockRemoteConfig extends Mock implements FirebaseRemoteConfig {}

RemoteConfigValue _value(String raw) =>
    RemoteConfigValue(utf8.encode(raw), ValueSource.valueRemote);

/// Batas Plus dari Remote Config (ADR-041 §3.6, §3.13 butir 8).
void main() {
  late _MockRemoteConfig rc;
  late StreamController<RemoteConfigUpdate> updates;
  late Map<String, RemoteConfigValue> values;
  late FirebaseEntitlementConfig config;

  setUpAll(
    () => registerFallbackValue(
      RemoteConfigSettings(
        fetchTimeout: Duration.zero,
        minimumFetchInterval: Duration.zero,
      ),
    ),
  );

  setUp(() {
    rc = _MockRemoteConfig();
    updates = StreamController<RemoteConfigUpdate>.broadcast();
    values = {};
    when(() => rc.setConfigSettings(any())).thenAnswer((_) async {});
    when(() => rc.fetchAndActivate()).thenAnswer((_) async => true);
    when(() => rc.activate()).thenAnswer((_) async => true);
    when(() => rc.getAll()).thenAnswer((_) => values);
    when(() => rc.onConfigUpdated).thenAnswer((_) => updates.stream);
    config = FirebaseEntitlementConfig(remoteConfig: rc);
  });

  tearDown(() async {
    await config.dispose();
    await updates.close();
  });

  test('sebelum diambil: bawaan, pra-peluncuran', () {
    expect(config.current, EntitlementLimits.defaults);
    expect(config.current.plusLaunchAt, isNull);
  });

  test(
    'setelan ambil sama dengan catatan rilis: interval 30 menit, batas 10 detik',
    () async {
      await config.refresh();
      final settings =
          verify(() => rc.setConfigSettings(captureAny())).captured.single
              as RemoteConfigSettings;
      expect(settings.minimumFetchInterval, const Duration(minutes: 30));
      expect(settings.fetchTimeout, const Duration(seconds: 10));
    },
  );

  test(
    'hanya kunci hak yang dibaca; catatan rilis diabaikan; perubahan dipancarkan',
    () async {
      values = {
        'free_smart_interpretations': _value('40'),
        'plus_launch_at': _value('2026-12-01'),
        'whats_new_15_0': _value('{"version":"0.9.0"}'),
      };
      final emitted = config.changes.first;
      await config.refresh();
      expect(config.current.freeSmartInterpretations, 40);
      expect(config.current.plusLaunchAt, DateTime(2026, 12));
      expect(await emitted, config.current);
    },
  );

  test('nilai tidak sah memakai bawaan', () async {
    values = {'free_projects': _value('-3'), 'trial_min_days': _value('x')};
    await config.refresh();
    expect(config.current.freeProjects, 2);
    expect(config.current.trialMinDays, 14);
  });

  test(
    'ambil gagal (luring): tetap nilai aktif terakhir, tidak melempar',
    () async {
      values = {'free_projects': _value('5')};
      await config.refresh();
      when(() => rc.fetchAndActivate()).thenThrow(Exception('luring'));
      values = {'free_projects': _value('5')};
      await config.refresh();
      expect(config.current.freeProjects, 5);
    },
  );

  test(
    'getAll melempar (Firebase belum siap): bawaan, tidak melempar',
    () async {
      when(
        () => rc.setConfigSettings(any()),
      ).thenThrow(Exception('belum diinisialisasi'));
      when(() => rc.getAll()).thenThrow(Exception('belum diinisialisasi'));
      await config.refresh();
      expect(config.current, EntitlementLimits.defaults);
    },
  );

  test('pembaruan langsung dari konsol diaktifkan dan dipancarkan', () async {
    await config.refresh();
    values = {'taste_ask': _value('5')};
    final emitted = config.changes.first;
    updates.add(RemoteConfigUpdate({'taste_ask'}));
    expect((await emitted).tasteAsk, 5);
    verify(() => rc.activate()).called(1);
  });

  test('nilai yang sama tidak dipancarkan ulang', () async {
    var count = 0;
    final sub = config.changes.listen((_) => count++);
    await config.refresh();
    await config.refresh();
    await Future<void>.delayed(Duration.zero);
    expect(count, 0);
    await sub.cancel();
  });
}
