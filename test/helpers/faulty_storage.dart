import 'package:api_storage/api_storage.dart';

/// Rencana galat bersama untuk beberapa [FaultyStorage]: operasi tulis atau
/// hapus ke-[failAt] (dihitung lintas semua penyimpanan) gagal.
///
/// [permanent] = `true` meniru proses yang mati: operasi itu dan seluruh
/// operasi sesudahnya gagal. `false` = hanya operasi itu yang gagal.
final class FaultPlan {
  /// Membuat [FaultPlan].
  FaultPlan({required this.failAt, this.permanent = true});

  /// Nomor operasi (mulai 0) yang digagalkan; `null` = tidak ada.
  final int? failAt;

  /// Apakah operasi sesudahnya ikut gagal.
  final bool permanent;

  /// Jumlah operasi tulis/hapus yang sudah dicoba.
  int ops = 0;

  /// Apakah galat sudah disuntikkan.
  bool triggered = false;

  /// Dipanggil sebelum tiap operasi tulis atau hapus.
  void tick() {
    final n = ops++;
    final at = failAt;
    if (at == null) return;
    if (n == at || (permanent && triggered && n > at)) {
      triggered = true;
      throw StateError('galat disuntikkan pada operasi $n');
    }
  }
}

/// `KeyValueStorage` pembungkus yang menggagalkan penulisan sesuai [FaultPlan].
/// Penulisan yang digagalkan tidak mengubah isi [inner], sama dengan satu
/// penulisan Hive yang tidak selesai.
final class FaultyStorage implements KeyValueStorage {
  /// Membuat [FaultyStorage].
  FaultyStorage(this.inner, this.plan);

  /// Penyimpanan di bawahnya.
  final KeyValueStorage inner;

  /// Rencana galat.
  final FaultPlan plan;

  @override
  Future<String?> read(String key) => inner.read(key);

  @override
  Future<bool> contains(String key) => inner.contains(key);

  @override
  Future<void> write(String key, String value) {
    plan.tick();
    return inner.write(key, value);
  }

  @override
  Future<void> remove(String key) {
    plan.tick();
    return inner.remove(key);
  }

  @override
  Future<void> clear() {
    plan.tick();
    return inner.clear();
  }
}
