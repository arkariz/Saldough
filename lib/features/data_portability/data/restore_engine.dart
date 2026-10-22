// Galat apa pun saat menyiapkan pemulihan berarti penyiapan dibatalkan dan
// data hidup tidak disentuh (ADR-040 §3.4 langkah 2).
// ignore_for_file: avoid_catches_without_on_clauses

import 'dart:convert';

import 'package:api_storage/api_storage.dart';
import 'package:saldough/features/data_portability/data/backup_scope.dart';
import 'package:saldough/features/data_portability/domain/backup_failure_codes.dart';
import 'package:saldough/features/data_portability/domain/backup_registry.dart';
import 'package:saldough/features/data_portability/domain/restore_models.dart';

/// Keadaan jurnal pemulihan. Hanya satu kunci (`journal`) yang menentukan di
/// sisi mana pemulihan dari gangguan jatuh.
enum RestoreState {
  /// Isi cadangan dan salinan pengaman sedang ditulis ke box kedua; data hidup
  /// belum disentuh. Dibatalkan bila terputus.
  staging,

  /// Semua sudah tersimpan di box kedua; penerapan ke data hidup berjalan atau
  /// harus diulang sampai selesai (idempoten).
  applying,

  /// Data hidup sudah berisi cadangan; tinggal finalisasi (hitung ulang saldo,
  /// bersih-bersih).
  applied,
}

/// Hasil pemeriksaan jurnal saat aplikasi dibuka.
enum RecoveryOutcome {
  /// Tidak ada pemulihan tertunda.
  none,

  /// Penyiapan terputus; dibuang, data lama utuh.
  rolledBack,

  /// Data cadangan sudah diterapkan; panggil [RestoreEngine.finalize].
  needsFinalize,
}

/// Cadangan pengaman yang masih bisa dikembalikan (R-5).
final class SafetyCopy {
  /// Membuat [SafetyCopy].
  const SafetyCopy({required this.createdAt, required this.expiresAt});

  /// Saat data itu disalin, sebelum pemulihan.
  final DateTime createdAt;

  /// Saat salinan dibuang otomatis (KT-E4: paling lama 30 hari).
  final DateTime expiresAt;
}

/// Penggantian data atomik lewat jurnal tulis-dulu dengan roll-forward
/// (ADR-040 §3.4).
///
/// [live] adalah box data (`saldough_kv`); [staging] box kedua
/// (`saldough_restore`). Port `KeyValueStorage` tidak punya transaksi, jadi
/// satu-satunya jaminan yang dipakai: satu penulisan satu kunci utuh atau
/// tidak sama sekali. Sebelum `applying` hanya data lama yang ada; sesudahnya
/// penerapan selalu diselesaikan maju. Tidak pernah ada data campuran.
///
/// Kunci di luar cakupan [registry] (bahasa, tur, dan lain-lain) tidak pernah
/// disentuh; `clear()` tidak dipakai (R-9).
final class RestoreEngine {
  /// Membuat [RestoreEngine].
  RestoreEngine({
    required this._live,
    required this._staging,
    required this._registry,
    this._now = DateTime.now,
  });

  final KeyValueStorage _live;
  final KeyValueStorage _staging;
  final BackupRegistry _registry;
  final DateTime Function() _now;

  /// Umur cadangan pengaman (KT-E4).
  static const safetyLifetime = Duration(days: 30);

  static const _journalKey = 'journal';
  static const _metaKey = 'meta';

  static String _incomingKey(String key) => 'i/$key';
  static String _safetyKey(String id, String key) => 's$id/$key';

  /// Cadangan pengaman yang masih berlaku, atau `null`.
  Future<SafetyCopy?> safetyCopy() async {
    if (await _staging.contains(_journalKey)) return null;
    final meta = await _readJson(_metaKey);
    if (meta == null) return null;
    final createdAt = DateTime.parse(meta['createdAt'] as String);
    final expiresAt = createdAt.add(safetyLifetime);
    if (!_now().isBefore(expiresAt)) return null;
    return SafetyCopy(createdAt: createdAt, expiresAt: expiresAt);
  }

  /// Dokumen di cadangan pengaman yang masih berlaku, atau `null`.
  Future<Map<String, String>?> safetyDocs() async {
    if (await safetyCopy() == null) return null;
    final meta = (await _readJson(_metaKey))!;
    final id = meta['id'] as String;
    final docs = <String, String>{};
    for (final k in meta['keys'] as List<dynamic>) {
      final value = await _staging.read(_safetyKey(id, k as String));
      if (value == null) return null;
      docs[k] = value;
    }
    return docs;
  }

  /// Menyiapkan penggantian data dengan [incoming] lalu menetapkan jurnal
  /// `applying`. Tidak menyentuh data hidup. Gagal → dibatalkan dan
  /// [BackupException] `space`.
  Future<void> stage({
    required Map<String, String> incoming,
    required RestoreKind kind,
    DateTime? backupCreatedAt,
  }) async {
    if (await _staging.contains(_journalKey)) {
      throw StateError('Masih ada pemulihan tertunda');
    }
    final oldDocs = await BackupScope.collect(_live, _registry);
    final previous = await _readJson(_metaKey);
    var id = _now().microsecondsSinceEpoch.toString();
    // Id salinan pengaman tidak boleh sama dengan yang sebelumnya: finalisasi
    // menghapus salinan lama dan akan ikut menghapus yang baru.
    if (id == previous?['id']) id = '${id}b';
    final journal = _Journal(
      state: RestoreState.staging,
      kind: kind,
      id: id,
      createdAt: _now(),
      oldKeys: oldDocs.keys.toList(),
      incomingKeys: incoming.keys.toList(),
      keepsSafety: kind != RestoreKind.onboarding,
      previousId: previous?['id'] as String?,
      previousKeys: [for (final k in previous?['keys'] as List<dynamic>? ?? const []) k as String],
      backupCreatedAt: backupCreatedAt,
    );
    try {
      await _writeJournal(journal);
      for (final e in incoming.entries) {
        await _staging.write(_incomingKey(e.key), e.value);
      }
      if (journal.keepsSafety) {
        for (final e in oldDocs.entries) {
          await _staging.write(_safetyKey(journal.id, e.key), e.value);
        }
      }
      await _writeJournal(journal.copyWith(state: RestoreState.applying));
    } catch (e) {
      await _discard(journal);
      throw BackupException(BackupFailureCodes.space, 'penyiapan gagal: $e');
    }
  }

  /// Seperti [stage] tetapi isinya diambil dari cadangan pengaman (R-5).
  /// Mengembalikan `false` bila tidak ada cadangan pengaman yang berlaku.
  Future<bool> stageUndo() async {
    if (await safetyCopy() == null) return false;
    final meta = (await _readJson(_metaKey))!;
    final id = meta['id'] as String;
    final incoming = <String, String>{};
    for (final k in meta['keys'] as List<dynamic>) {
      final value = await _staging.read(_safetyKey(id, k as String));
      if (value == null) return false;
      incoming[k] = value;
    }
    await stage(incoming: incoming, kind: RestoreKind.undo);
    return true;
  }

  /// Memeriksa jurnal; dipanggil di setiap bootstrap, sebelum repositori
  /// dibuat. Pemulihan biasa dan pemulihan dari gangguan memakai jalur ini.
  Future<RecoveryOutcome> recover() async {
    final journal = await _readJournal();
    if (journal == null) {
      await _purgeExpired();
      return RecoveryOutcome.none;
    }
    switch (journal.state) {
      case RestoreState.staging:
        await _discard(journal);
        return RecoveryOutcome.rolledBack;
      case RestoreState.applying:
        await _apply(journal);
        await _writeJournal(journal.copyWith(state: RestoreState.applied));
        return RecoveryOutcome.needsFinalize;
      case RestoreState.applied:
        return RecoveryOutcome.needsFinalize;
    }
  }

  /// Menyelesaikan pemulihan sesudah [recover] melapor `needsFinalize`:
  /// menjalankan [recompute] (hitung ulang saldo dompet, R-6), lalu
  /// membersihkan box kedua dan memperbarui cadangan pengaman. Idempoten:
  /// terputus di tengah → diulang saat bootstrap berikutnya.
  Future<RestoreReport> finalize(Future<void> Function() recompute) async {
    final journal = await _readJournal();
    if (journal == null || journal.state != RestoreState.applied) {
      throw StateError('Tidak ada pemulihan yang menunggu finalisasi');
    }
    await recompute();
    for (final key in journal.incomingKeys) {
      await _staging.remove(_incomingKey(key));
    }
    if (journal.previousId != null) {
      for (final key in journal.previousKeys) {
        await _staging.remove(_safetyKey(journal.previousId!, key));
      }
    }
    if (journal.keepsSafety) {
      await _writeJson(_metaKey, {
        'id': journal.id,
        'createdAt': journal.createdAt.toIso8601String(),
        'keys': journal.oldKeys,
      });
    } else if (journal.previousId != null) {
      await _staging.remove(_metaKey);
    }
    await _staging.remove(_journalKey);
    return RestoreReport(
      kind: journal.kind,
      backupCreatedAt: journal.backupCreatedAt,
      restoredKeys: journal.incomingKeys,
    );
  }

  Future<void> _apply(_Journal journal) async {
    final incoming = journal.incomingKeys.toSet();
    for (final key in journal.oldKeys) {
      if (!incoming.contains(key)) await _live.remove(key);
    }
    for (final key in journal.incomingKeys) {
      final value = await _staging.read(_incomingKey(key));
      if (value == null) throw StateError('Isi cadangan hilang dari box pemulihan: $key');
      await _live.write(key, value);
    }
  }

  Future<void> _discard(_Journal journal) async {
    try {
      for (final key in journal.incomingKeys) {
        await _staging.remove(_incomingKey(key));
      }
      if (journal.keepsSafety) {
        for (final key in journal.oldKeys) {
          await _staging.remove(_safetyKey(journal.id, key));
        }
      }
      await _staging.remove(_journalKey);
    } catch (_) {
      // Sisa kunci tidak berbahaya; dibersihkan oleh pemulihan berikutnya.
    }
  }

  Future<void> _purgeExpired() async {
    final meta = await _readJson(_metaKey);
    if (meta == null) return;
    final createdAt = DateTime.parse(meta['createdAt'] as String);
    if (_now().isBefore(createdAt.add(safetyLifetime))) return;
    final id = meta['id'] as String;
    for (final key in meta['keys'] as List<dynamic>) {
      await _staging.remove(_safetyKey(id, key as String));
    }
    await _staging.remove(_metaKey);
  }

  Future<_Journal?> _readJournal() async {
    final json = await _readJson(_journalKey);
    return json == null ? null : _Journal.fromJson(json);
  }

  Future<void> _writeJournal(_Journal journal) => _writeJson(_journalKey, journal.toJson());

  Future<Map<String, dynamic>?> _readJson(String key) async {
    final raw = await _staging.read(key);
    return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> _writeJson(String key, Map<String, dynamic> json) => _staging.write(key, jsonEncode(json));
}

final class _Journal {
  const _Journal({
    required this.state,
    required this.kind,
    required this.id,
    required this.createdAt,
    required this.oldKeys,
    required this.incomingKeys,
    required this.keepsSafety,
    required this.previousId,
    required this.previousKeys,
    required this.backupCreatedAt,
  });

  factory _Journal.fromJson(Map<String, dynamic> json) => _Journal(
    state: RestoreState.values.byName(json['state'] as String),
    kind: RestoreKind.values.byName(json['kind'] as String),
    id: json['id'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    oldKeys: [for (final k in json['oldKeys'] as List<dynamic>) k as String],
    incomingKeys: [for (final k in json['incomingKeys'] as List<dynamic>) k as String],
    keepsSafety: json['keepsSafety'] as bool,
    previousId: json['previousId'] as String?,
    previousKeys: [for (final k in json['previousKeys'] as List<dynamic>) k as String],
    backupCreatedAt: json['backupCreatedAt'] == null ? null : DateTime.parse(json['backupCreatedAt'] as String),
  );

  final RestoreState state;
  final RestoreKind kind;
  final String id;
  final DateTime createdAt;

  /// Kunci data hidup di cakupan saat penyiapan (basis daftar yang dihapus).
  final List<String> oldKeys;
  final List<String> incomingKeys;
  final bool keepsSafety;
  final String? previousId;
  final List<String> previousKeys;
  final DateTime? backupCreatedAt;

  _Journal copyWith({RestoreState? state}) => _Journal(
    state: state ?? this.state,
    kind: kind,
    id: id,
    createdAt: createdAt,
    oldKeys: oldKeys,
    incomingKeys: incomingKeys,
    keepsSafety: keepsSafety,
    previousId: previousId,
    previousKeys: previousKeys,
    backupCreatedAt: backupCreatedAt,
  );

  Map<String, dynamic> toJson() => {
    'state': state.name,
    'kind': kind.name,
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'oldKeys': oldKeys,
    'incomingKeys': incomingKeys,
    'keepsSafety': keepsSafety,
    'previousId': previousId,
    'previousKeys': previousKeys,
    'backupCreatedAt': backupCreatedAt?.toIso8601String(),
  };
}
