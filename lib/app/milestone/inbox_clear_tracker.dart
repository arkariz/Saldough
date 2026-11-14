import 'dart:async';

import 'package:api_storage/api_storage.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_store.dart';
import 'package:saldough/features/notification_capture/domain/services/capture_inbox_changes.dart';

const _clearedKey = StorageKey(namespace: 'milestone', name: 'signal_inbox_cleared');

/// Benar bila kotak masuk turun dari ≥1 menunggu ke nol (kedua hitungan
/// diketahui). Titik awal yang belum diketahui ([previous] `null`) tidak
/// dihitung, supaya kotak kosong sejak awal bukan "bersih".
bool inboxDroppedToZero({required int? previous, required int current}) =>
    previous != null && previous >= 1 && current == 0;

/// Mengamati perubahan kotak masuk dan mengingat sekali selamanya bahwa
/// pengguna pernah menuntaskannya (stempel `inbox_clear`, hanya Android).
///
/// Perubahan kotak masuk hanya diumumkan [CaptureInboxChanges] oleh tindakan
/// (Catat, Bukan transaksi, Buang) dan pemrosesan notifikasi; kedaluwarsa
/// tujuh hari tidak mengumumkan, jadi tidak dihitung. Penanda milik perangkat
/// dan tidak ikut cadangan (ia hanya pemicu; stempelnya yang ikut).
final class InboxClearTracker {
  /// Membuat [InboxClearTracker].
  InboxClearTracker({required this._storage, required this._store, required this._changes});

  final KeyValueStorage _storage;
  final NotificationCaptureStore _store;
  final CaptureInboxChanges _changes;

  StreamSubscription<void>? _subscription;
  int? _lastCount;

  /// Mulai mengamati. Aman dipanggil berulang.
  Future<void> start() async {
    if (_subscription != null) return;
    _lastCount = await _count();
    _subscription = _changes.stream.listen((_) => unawaited(_onChanged()));
  }

  /// Berhenti mengamati.
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  /// Pengguna pernah menuntaskan kotak masuk.
  Future<bool> isCleared() async {
    try {
      return await _storage.read(_clearedKey.value) != null;
    } on Object {
      return false;
    }
  }

  Future<int?> _count() async => (await _store.loadInbox()).fold((_) => null, (entries) => entries.length);

  Future<void> _onChanged() async {
    final current = await _count();
    if (current == null) return;
    final dropped = inboxDroppedToZero(previous: _lastCount, current: current);
    _lastCount = current;
    if (!dropped) return;
    try {
      await _storage.write(_clearedKey.value, '{"schemaVersion":1}');
    } on Object {
      // Penanda gagal ditulis: kotak masuk berikutnya yang bersih mengulang.
    }
  }
}
