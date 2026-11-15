import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:saldough/features/milestone/domain/entities/milestone_catalog.dart';

/// Kunci Remote Config saklar stempel (GAMIFICATION §10, ADR-046 §3.2).
abstract final class StampRemoteKeys {
  /// `false` mematikan semua stempel baru dari jauh (bawaan: `true`).
  static const enabled = 'stamps_enabled';

  /// Id yang dimatikan, dipisah koma (bawaan: kosong).
  static const disabledIds = 'stamps_disabled_ids';
}

/// Id tonggak yang **tidak boleh diraih sekarang**, dari nilai mentah Remote
/// Config. Murni dan tidak pernah melempar.
///
/// - [enabledRaw] `null` (kunci belum pernah diambil) atau bukan `false`/`0`:
///   menyala. `false` atau `0` mematikan **seluruh** katalog.
/// - [disabledRaw]: daftar id dipisah koma; id yang tidak dikenal diabaikan.
///
/// Yang sudah diraih tidak pernah dicabut (G-1): saklar hanya menahan stempel
/// baru, dan perayaannya ikut tertahan karena tidak ada yang baru.
Set<String> stampDisabledIds({String? enabledRaw, String disabledRaw = ''}) {
  final all = {for (final def in milestoneCatalog) def.id};
  final off = enabledRaw?.trim().toLowerCase();
  if (off == 'false' || off == '0') return all;
  return {
    for (final id in disabledRaw.split(','))
      if (all.contains(id.trim())) id.trim(),
  };
}

/// Membaca saklar stempel dari Remote Config yang sudah aktif. **Tidak
/// mengambil** sendiri: pengambilan dilakukan gateway lain yang berbagi
/// singleton yang sama (`app_update`, hak Plus). Tanpa Firebase atau kunci
/// belum pernah diambil, semua menyala.
Set<String> firebaseStampDisabledIds() {
  try {
    if (Firebase.apps.isEmpty) return const {};
    final rc = FirebaseRemoteConfig.instance;
    final enabled = rc.getValue(StampRemoteKeys.enabled);
    final disabled = rc.getValue(StampRemoteKeys.disabledIds);
    return stampDisabledIds(
      enabledRaw: enabled.source == ValueSource.valueStatic ? null : enabled.asString(),
      disabledRaw: disabled.source == ValueSource.valueStatic ? '' : disabled.asString(),
    );
  } on Object catch (e) {
    developer.log('Saklar stempel gagal dibaca; semua menyala', error: e, name: 'Milestone');
    return const {};
  }
}
