import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Batas zona dan lapisan yang dijaga mesin (ADR-0009, ADR-030 §3.8).
///
/// Membaca direktif `import` setiap berkas `lib/` (tanpa `.g.dart`) dan
/// melaporkan seluruh pelanggaran sekaligus, satu baris per impor, supaya
/// pesan gagalnya langsung menunjuk berkas dan impornya.
void main() {
  final files = <String, List<String>>{};
  final importPattern = RegExp(r"^\s*import\s+'([^']+)'", multiLine: true);
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart') || entity.path.endsWith('.g.dart')) continue;
    final path = entity.path.replaceAll(r'\', '/');
    files[path] = [for (final match in importPattern.allMatches(entity.readAsStringSync())) match.group(1)!];
  }

  /// `lib/...` untuk impor `package:saldough/...`, `null` untuk paket lain.
  String? target(String uri) => uri.startsWith('package:saldough/') ? 'lib/${uri.substring(17)}' : null;

  String zoneOf(String path) => path.split('/')[1];
  String? moduleOf(String path) {
    final parts = path.split('/');
    return parts.length > 3 && (parts[1] == 'shared' || parts[1] == 'features') ? parts[2] : null;
  }

  bool inLayer(String path, String layer) => path.contains('/$layer/');

  List<String> violations(bool Function(String file, String uri, String? to) isViolation) => [
    for (final MapEntry(key: file, value: uris) in files.entries)
      for (final uri in uris)
        if (isViolation(file, uri, target(uri))) '$file -> $uri',
  ];

  void expectNone(List<String> found) => expect(found, isEmpty, reason: found.join('\n'));

  test('berkas lib/ ditemukan', () => expect(files.length, greaterThan(100)));

  test('impor selalu package:saldough/..., tidak pernah relatif', () {
    expectNone(violations((_, uri, _) => !uri.startsWith('package:') && !uri.startsWith('dart:')));
  });

  test('core/ tidak mengimpor app/, shared/, maupun features/', () {
    expectNone(
      violations(
        (file, _, to) => zoneOf(file) == 'core' && to != null && const {'app', 'shared', 'features'}.contains(zoneOf(to)),
      ),
    );
  });

  test('shared/ dan features/ tidak mengimpor app/ (akar komposisi, hanya main.dart)', () {
    expectNone(
      violations((file, _, to) => const {'shared', 'features'}.contains(zoneOf(file)) && to != null && zoneOf(to) == 'app'),
    );
  });

  test('shared/ tidak mengimpor features/', () {
    expectNone(violations((file, _, to) => zoneOf(file) == 'shared' && to != null && zoneOf(to) == 'features'));
  });

  test('fitur lain hanya lewat *_route_keys.dart (atau adapter ke port domain konsumen)', () {
    expectNone(
      violations((file, _, to) {
        if (zoneOf(file) != 'features' || to == null || zoneOf(to) != 'features') return false;
        if (moduleOf(file) == moduleOf(to)) return false;
        if (to.contains('/presentation/navigation/') && to.endsWith('_route_keys.dart')) return false;
        // Pola port ADR-0009: penyedia mengimplementasikan port milik konsumen.
        if (file.contains('/data/adapters/') && inLayer(to, 'domain')) return false;
        return true;
      }),
    );
  });

  test('modul shared/ diimpor dari luar hanya lewat barrel-nya', () {
    expectNone(
      violations((file, _, to) {
        if (to == null || zoneOf(to) != 'shared') return false;
        if (zoneOf(file) == 'shared' && moduleOf(file) == moduleOf(to)) return false;
        return to.split('/').length != 4; // lib/shared/<modul>/<barrel>.dart
      }),
    );
  });

  test('domain/ tanpa Flutter, infrastruktur, data/, presentation/, maupun barrel presentasi', () {
    const infrastructure = ['package:flutter/', 'package:hive', 'package:firebase', 'package:speech_to_text', 'package:go_router'];
    expectNone(
      violations((file, uri, to) {
        if (!inLayer(file, 'domain')) return false;
        if (infrastructure.any(uri.startsWith)) return true;
        if (to == null) return false;
        return inLayer(to, 'data') || inLayer(to, 'presentation') || inLayer(to, 'di') || to.endsWith('_presentation.dart');
      }),
    );
  });

  test('core/foundation/entitlement/ murni: tanpa Flutter, SDK pembelian, maupun Firebase (ADR-041 §3.1)', () {
    const forbidden = ['package:flutter/', 'package:purchases_flutter', 'package:firebase'];
    expectNone(
      violations(
        (file, uri, _) => file.startsWith('lib/core/foundation/entitlement/') && forbidden.any(uri.startsWith),
      ),
    );
  });

  test('pengganti paket uji hanya di plan_override.dart; tidak ada di workflow rilis maupun Fastfile (ADR-041 §3.10)', () {
    const home = 'lib/app/premium/plan_override.dart';
    const registry = 'lib/app/data_portability/app_backup_registry.dart';
    final marker = RegExp('PLAN_OVERRIDE|debug_override');
    final stray = [
      for (final file in files.keys)
        if (file != home && file != registry && File(file).readAsStringSync().contains(marker)) file,
    ];
    expect(stray, isEmpty, reason: 'PLAN_OVERRIDE dan kunci debug hanya di $home:\n${stray.join('\n')}');

    final pipeline = [
      'android/fastlane/Fastfile',
      for (final entity in Directory('.github/workflows').listSync().whereType<File>()) entity.path,
    ];
    final leaked = [
      for (final path in pipeline)
        if (File(path).readAsStringSync().contains('PLAN_OVERRIDE')) path,
    ];
    expect(leaked, isEmpty, reason: 'pipeline rilis tidak boleh memberi PLAN_OVERRIDE:\n${leaked.join('\n')}');
  });

  test('SDK pembelian (purchases_flutter) hanya di features/premium/data/ (ADR-041 §3.1)', () {
    expectNone(
      violations(
        (file, uri, _) =>
            uri.startsWith('package:purchases_flutter') && !file.startsWith('lib/features/premium/data/'),
      ),
    );
  });

  test('presentation/ tidak mengimpor data/', () {
    expectNone(violations((file, _, to) => inLayer(file, 'presentation') && to != null && inLayer(to, 'data')));
  });
}
