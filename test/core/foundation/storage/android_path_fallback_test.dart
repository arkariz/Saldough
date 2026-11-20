import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:saldough/core/foundation/storage/android_path_fallback.dart';

const _status = 'Name:\tsaldough\nUmask:\t0077\nUid:\t10234\t10234\t10234\t10234\nGid:\t10234\t10234\n';

class _FakeInner extends PathProviderPlatform {
  _FakeInner({this.fail = false});
  final bool fail;

  Future<String?> _answer(String value) async {
    if (fail) throw StateError('ClassNotFoundException Landroid/content/Context;');
    return value;
  }

  @override
  Future<String?> getApplicationDocumentsPath() => _answer('/asli/documents');
  @override
  Future<String?> getTemporaryPath() => _answer('/asli/temp');
  @override
  Future<String?> getApplicationSupportPath() => _answer('/asli/support');
  @override
  Future<String?> getApplicationCachePath() => _answer('/asli/cache');
  @override
  Future<String?> getDownloadsPath() async => '/asli/downloads';
}

AndroidDataDirResolver _resolver({
  String status = _status,
  Set<String> existing = const {'/data/user/0/com.arkarizdev.tanukonomy'},
  List<String>? created,
  Error? readError,
}) => AndroidDataDirResolver(
  readStatus: () async {
    if (readError != null) throw readError;
    return status;
  },
  exists: existing.contains,
  create: (path) => created?.add(path),
);

void main() {
  group('AndroidDataDirResolver', () {
    test('parseUid membaca baris Uid', () {
      expect(AndroidDataDirResolver.parseUid(_status), 10234);
      expect(AndroidDataDirResolver.parseUid('Name:\tx\n'), isNull);
    });

    test('user utama: uid / 100000 = 0; folder cadangan dibuat bila belum ada', () async {
      final created = <String>[];
      final path = await _resolver(created: created).resolve('app_flutter');
      expect(path, '/data/user/0/com.arkarizdev.tanukonomy/app_flutter');
      expect(created, [path]);
    });

    test('profil kerja/user lain: uid 1010234 -> user 10', () async {
      final path = await _resolver(
        status: 'Uid:\t1010234\t1010234\n',
        existing: {'/data/user/10/com.arkarizdev.tanukonomy', '/data/user/10/com.arkarizdev.tanukonomy/cache'},
      ).resolve('cache');
      expect(path, '/data/user/10/com.arkarizdev.tanukonomy/cache');
    });

    test('folder data paket tidak ada -> null (jalur tak terbukti, tidak ditebak)', () async {
      expect(await _resolver(existing: const {}).resolve('app_flutter'), isNull);
    });

    test('UID tak terbaca atau galat baca -> null', () async {
      expect(await _resolver(status: 'tanpa uid').resolve('app_flutter'), isNull);
      expect(await _resolver(readError: StateError('x')).resolve('app_flutter'), isNull);
    });
  });

  group('FallbackPathProvider', () {
    test('implementasi asli sehat: dipakai apa adanya, cadangan tidak disentuh', () async {
      final used = <String>[];
      final provider = FallbackPathProvider(inner: _FakeInner(), resolver: _resolver(), onFallback: (e, k) => used.add(k));
      expect(await provider.getApplicationDocumentsPath(), '/asli/documents');
      expect(await provider.getTemporaryPath(), '/asli/temp');
      expect(used, isEmpty);
    });

    test('implementasi asli gagal: jalur cadangan per jenis dan onFallback dipanggil', () async {
      final used = <String>[];
      final provider = FallbackPathProvider(
        inner: _FakeInner(fail: true),
        resolver: _resolver(),
        onFallback: (e, k) => used.add(k),
      );
      const base = '/data/user/0/com.arkarizdev.tanukonomy';
      expect(await provider.getApplicationDocumentsPath(), '$base/app_flutter');
      expect(await provider.getTemporaryPath(), '$base/cache');
      expect(await provider.getApplicationCachePath(), '$base/cache');
      expect(await provider.getApplicationSupportPath(), '$base/files');
      expect(used, ['documents', 'temporary', 'cache', 'support']);
    });

    test('gagal dan cadangan tak terbukti: galat asli dilempar ulang', () async {
      final provider = FallbackPathProvider(inner: _FakeInner(fail: true), resolver: _resolver(existing: const {}));
      await expectLater(provider.getApplicationDocumentsPath(), throwsStateError);
    });

    test('metode lain diteruskan ke implementasi asli', () async {
      final provider = FallbackPathProvider(inner: _FakeInner(fail: true), resolver: _resolver());
      expect(await provider.getDownloadsPath(), '/asli/downloads');
    });
  });
}
