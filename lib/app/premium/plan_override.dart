import 'dart:async';
import 'dart:developer' as developer;

import 'package:api_storage/api_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';

const _key = StorageKey(namespace: 'entitlement', name: 'debug_override');

/// Pengganti paket untuk uji dan pengembangan (ADR-041 §3.10).
///
/// **Hanya di build non-rilis.** Di rilis ([isRelease]) nilainya selalu
/// [PlanOverride.auto]: define, pilihan tersimpan, dan [select] tidak punya
/// efek. Seluruh pembacaan `PLAN_OVERRIDE` dan kunci penyimpanannya ada di
/// berkas ini (dijaga `import_boundaries_test.dart`); pipeline rilis tidak
/// pernah memberi define itu.
///
/// Nilai awal dari `--dart-define=PLAN_OVERRIDE=free|trial|plus`; pilihan dari
/// menu pengembang disimpan dan menang atas define pada pembukaan berikutnya.
/// Kunci disimpan tidak ikut cadangan (`entitlement_debug_override`).
final class PlanOverrideController extends ValueNotifier<PlanOverride> {
  /// Membuat [PlanOverrideController]; [isRelease] dan [define] untuk uji.
  PlanOverrideController({
    required this._storage,
    this.isRelease = kReleaseMode,
    String define = const String.fromEnvironment('PLAN_OVERRIDE'),
  }) : super(
         isRelease ? PlanOverride.auto : _parse(define) ?? PlanOverride.auto,
       );

  /// Build rilis: pengganti dimatikan.
  final bool isRelease;

  final KeyValueStorage _storage;

  static PlanOverride? _parse(Object? raw) =>
      raw is String ? PlanOverride.values.asNameMap()[raw] : null;

  StoredValue<PlanOverride> get _store => StoredValue<PlanOverride>.json(
    key: _key,
    fromJson: (json) =>
        _parse(json['value']) ??
        (throw const FormatException('Pilihan paket tidak valid')),
    toJson: (value) => {'schemaVersion': 1, 'value': value.name},
    storage: _storage,
  );

  /// Memuat pilihan tersimpan (menang atas define). Galat dibaca diabaikan.
  Future<void> load() async {
    if (isRelease) return;
    try {
      final saved = await _store.read();
      if (saved != null) value = saved;
    } on Object catch (e) {
      developer.log(
        'Pilihan paket uji gagal dibaca',
        error: e,
        name: 'PlanOverride',
      );
    }
  }

  /// Memilih [next] dan menyimpannya. Tanpa efek di build rilis.
  Future<void> select(PlanOverride next) async {
    if (isRelease) return;
    value = next;
    try {
      await _store.write(next);
    } on Object catch (e) {
      developer.log(
        'Pilihan paket uji gagal disimpan',
        error: e,
        name: 'PlanOverride',
      );
    }
  }
}
