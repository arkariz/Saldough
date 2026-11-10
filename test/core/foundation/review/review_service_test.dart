import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/foundation/review/review_service.dart';
import 'package:saldough/core/foundation/review/review_thresholds.dart';

final class _FakeGateway implements ReviewGateway {
  bool available = true;
  Future<void> Function()? onRequest;
  int requests = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> requestReview() async {
    requests++;
    await onRequest?.call();
  }
}

void main() {
  remoteConfigTests();
  late DateTime clock;
  late _FakeGateway gateway;
  late ReviewService service;
  final events = <AnalyticsEvent>[];

  setUp(() {
    clock = DateTime(2026, 11, 10, 9);
    gateway = _FakeGateway();
    service = ReviewService(storage: InMemoryKeyValueStorage(), gateway: gateway, now: () => clock);
    events.clear();
    AppAnalytics.debugSink = events.add;
  });
  tearDown(() {
    AppAnalytics.debugSink = null;
    ReviewPrompt.install(null);
  });

  Future<void> record(int count) async {
    for (var i = 0; i < count; i++) {
      await service.noteRecorded();
    }
  }

  test('belum cukup transaksi atau hari: tidak meminta', () async {
    await record(10); // semua di satu hari
    expect(await service.maybePrompt(), isFalse);
    clock = clock.add(const Duration(days: 1));
    await record(1);
    expect(await service.maybePrompt(), isTrue);
    expect(gateway.requests, 1);
    expect(events.single.name, 'review_requested');
    expect(events.single.parameters['source'], 'auto');
  });

  test('9 transaksi di dua hari belum cukup', () async {
    await record(5);
    clock = clock.add(const Duration(days: 1));
    await record(4);
    expect(await service.maybePrompt(), isFalse);
  });

  test('jeda 90 hari antarpermintaan otomatis', () async {
    await record(6);
    clock = clock.add(const Duration(days: 1));
    await record(6);
    expect(await service.maybePrompt(), isTrue);
    expect(await service.maybePrompt(), isFalse);
    clock = clock.add(const Duration(days: 89));
    expect(await service.maybePrompt(), isFalse);
    clock = clock.add(const Duration(days: 1));
    expect(await service.maybePrompt(), isTrue);
    expect(gateway.requests, 2);
  });

  test('berhenti sesudah batas total permintaan otomatis (bawaan 2)', () async {
    await record(6);
    clock = clock.add(const Duration(days: 1));
    await record(6);
    expect(await service.maybePrompt(), isTrue);
    clock = clock.add(const Duration(days: 90));
    expect(await service.maybePrompt(), isTrue);
    clock = clock.add(const Duration(days: 365));
    expect(await service.maybePrompt(), isFalse);
    expect(gateway.requests, 2);
  });

  test('membuka baris Beri nilai menghentikan permintaan otomatis selamanya', () async {
    await record(6);
    clock = clock.add(const Duration(days: 1));
    await record(6);
    await service.requestFromUser(openStore: () async => true);
    clock = clock.add(const Duration(days: 365));
    expect(await service.maybePrompt(), isFalse);
    expect(events.where((e) => e.parameters['source'] == 'auto'), isEmpty);
  });

  test('lembar tidak tersedia: tidak meminta dan tidak memakai jatah jeda', () async {
    gateway.available = false;
    await record(6);
    clock = clock.add(const Duration(days: 1));
    await record(6);
    expect(await service.maybePrompt(), isFalse);
    gateway.available = true;
    expect(await service.maybePrompt(), isTrue);
  });

  test('ketukan pengguna: lembar tampil (lama) tidak membuka toko', () async {
    gateway.onRequest = () async => clock = clock.add(const Duration(seconds: 5));
    var opened = 0;
    final ok = await service.requestFromUser(openStore: () async => ++opened > 0);
    expect(ok, isTrue);
    expect(opened, 0);
    expect(events.single.parameters['source'], 'row');
  });

  test('ketukan pengguna: lembar segera selesai (jatah habis) jatuh ke toko', () async {
    var opened = 0;
    final ok = await service.requestFromUser(openStore: () async => ++opened > 0);
    expect(ok, isTrue);
    expect(opened, 1);
  });

  test('ketukan pengguna: lembar tidak tersedia langsung membuka toko, gagal dilaporkan', () async {
    gateway.available = false;
    expect(await service.requestFromUser(openStore: () async => false), isFalse);
    expect(gateway.requests, 0);
  });

  test('tanpa layanan terpasang: ketukan membuka toko, yang lain diam', () async {
    ReviewPrompt.install(null);
    ReviewPrompt.noteRecorded();
    expect(await ReviewPrompt.maybePrompt(), isFalse);
    expect(await ReviewPrompt.requestFromUser(openStore: () async => true), isTrue);
  });
}

void remoteConfigTests() {
  group('ReviewThresholds', () {
    test('tanpa nilai: bawaan 10 transaksi, 2 hari, 90 hari', () {
      final t = ReviewThresholds.fromValues(const {});
      expect((t.minRecorded, t.minDays, t.cooldownDays, t.maxAutoRequests), (10, 2, 90, 2));
    });

    test('nilai sah dipakai', () {
      final t = ReviewThresholds.fromValues(const {
        'review_min_recorded': '25',
        'review_min_days': ' 5 ',
        'review_cooldown_days': '30',
        'review_max_auto_requests': '0',
      });
      expect((t.minRecorded, t.minDays, t.cooldownDays, t.maxAutoRequests), (25, 5, 30, 0));
      expect(t.cooldown, const Duration(days: 30));
    });

    test('nol, negatif, bukan angka, atau di luar batas jatuh ke bawaan', () {
      final t = ReviewThresholds.fromValues(const {
        'review_min_recorded': '0',
        'review_min_days': '31',
        'review_cooldown_days': 'abc',
      });
      expect(t, ReviewThresholds.defaults);
    });
  });

  test('ReviewService memakai syarat dari config', () async {
    var clock = DateTime(2026, 11, 10, 9);
    final gateway = _FakeGateway();
    final service = ReviewService(
      storage: InMemoryKeyValueStorage(),
      gateway: gateway,
      now: () => clock,
      config: const StaticReviewConfig(ReviewThresholds(minRecorded: 3, minDays: 1, cooldownDays: 7, maxAutoRequests: 5)),
    );
    for (var i = 0; i < 3; i++) {
      await service.noteRecorded();
    }
    expect(await service.maybePrompt(), isTrue);
    clock = clock.add(const Duration(days: 6));
    expect(await service.maybePrompt(), isFalse);
    clock = clock.add(const Duration(days: 1));
    expect(await service.maybePrompt(), isTrue);
  });
}
