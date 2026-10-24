import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/app/data_portability/app_backup_registry.dart';

/// Setiap `StorageKey` di `lib/` harus diklasifikasi terhadap cadangan
/// (ADR-040 §3.3): ikut (`included`) atau sengaja tidak (`excluded`). Fitur
/// baru yang menyimpan data tidak bisa lolos tanpa memutuskannya.
void main() {
  // `StorageKey(namespace: 'x', name: 'y')`; `name` boleh dinamis.
  final declaration = RegExp(r"StorageKey\(\s*namespace:\s*'([a-z_]+)'\s*(?:,\s*name:\s*('([^']*)'|[^)]+))?\s*\)");

  final literal = <String, String>{}; // kunci → berkas
  final dynamicNamespaces = <String, String>{}; // namespace → berkas

  setUpAll(() {
    for (final file in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      for (final m in declaration.allMatches(file.readAsStringSync())) {
        final namespace = m.group(1)!;
        final literalName = m.group(3);
        if (literalName != null) {
          literal['${namespace}_$literalName'] = file.path;
        } else {
          dynamicNamespaces[namespace] = file.path;
        }
      }
    }
  });

  final registry = appBackupRegistry;
  Set<String> includedKeys() => {for (final s in registry.included) s.key};

  test('pemindai menemukan kunci (bukan kosong karena regex rusak)', () {
    expect(literal.length, greaterThan(20));
    expect(literal.keys, containsAll(['wallet_all', 'transaction__index', 'settings_currency']));
  });

  test('setiap kunci di lib/ diklasifikasi: ikut atau sengaja tidak', () {
    final known = {...includedKeys(), ...registry.excluded.keys};
    final unclassified = literal.keys.where((k) => !known.contains(k)).toList()..sort();
    expect(
      unclassified,
      isEmpty,
      reason:
          'Kunci penyimpanan baru harus didaftarkan di app_backup_registry.dart: '
          '${[for (final k in unclassified) '$k (${literal[k]})'].join(', ')}',
    );
  });

  test('namespace dengan nama dinamis hanya partisi transaksi dan ikon sumber, keduanya ditangani', () {
    expect(dynamicNamespaces.keys.toSet(), {'transaction', 'source_icon'});
    expect(registry.transactionPartitionPrefix, 'transaction_');
    expect(registry.sourceIconPrefix, 'source_icon_');
  });

  test('tidak ada kunci yang ikut dan sengaja-tidak-ikut sekaligus', () {
    expect(includedKeys().intersection(registry.excluded.keys.toSet()), isEmpty);
  });

  test('tidak ada entri usang: setiap kunci di registri masih ada di lib/', () {
    final stale = [
      ...includedKeys().where((k) => !literal.containsKey(k)),
      ...registry.excluded.keys.where((k) => !literal.containsKey(k)),
    ]..sort();
    expect(stale, isEmpty, reason: 'Kunci di registri yang tidak ada lagi di kode');
  });

  test('kunci tetap tidak ikut menyamai kunci dinamis (partisi dan ikon ditangani terpisah)', () {
    for (final key in includedKeys()) {
      expect(registry.specOf(key).isIncluded, isTrue);
    }
    expect(registry.specOf('transaction_2026-10').isIncluded, isTrue);
    expect(registry.specOf('transaction_xyz').isIncluded, isFalse);
    expect(registry.specOf('source_icon_abc').isIncluded, isTrue);
    expect(registry.specOf('source_icon_').isIncluded, isFalse);
    expect(registry.specOf('wallet_baru').isIncluded, isFalse);
  });
}
