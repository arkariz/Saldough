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

  test('presentation/ tidak mengimpor data/', () {
    expectNone(violations((file, _, to) => inLayer(file, 'presentation') && to != null && inLayer(to, 'data')));
  });
}
