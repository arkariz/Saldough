import 'package:saldough/features/notification_capture/domain/repositories/merchant_memory_store.dart';
import 'package:saldough/features/notification_capture/domain/services/capture_resolver.dart';

/// Batas jumlah ingatan; yang tertua dibuang saat penuh.
const merchantMemoryLimit = 500;

/// Catatan dinormalkan: huruf kecil dan spasi dirapatkan, supaya "ES BUAH" dan
/// "es  buah" satu pedagang.
String normalizeMerchant(String note) => note.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

/// Kunci ingatan untuk [note] dari [packageName].
String merchantKey(String packageName, String note) => '$packageName|${normalizeMerchant(note)}';

/// [MerchantMemory] di atas [MerchantMemoryStore]: dimuat ulang tiap
/// [refresh] (sebelum resolver bekerja), ditulis lewat [remember] dan [forget].
final class StoreBackedMerchantMemory implements MerchantMemory {
  /// Membuat [StoreBackedMerchantMemory].
  StoreBackedMerchantMemory(this._store);

  final MerchantMemoryStore _store;
  Map<String, String> _memory = {};

  @override
  Future<void> refresh() async {
    _memory = (await _store.load()).getOrElse((_) => const {});
  }

  @override
  String? categoryFor({required String packageName, required String note}) {
    if (normalizeMerchant(note).isEmpty) return null;
    return _memory[merchantKey(packageName, note)];
  }

  /// Mengingat [categoryId] untuk [note] dari [packageName]. Mengembalikan
  /// kategori yang diingat sebelumnya (`null` bila belum ada), untuk Batalkan.
  Future<String?> remember({required String packageName, required String note, required String categoryId}) async {
    await refresh();
    final key = merchantKey(packageName, note);
    if (normalizeMerchant(note).isEmpty) return null;
    final previous = _memory[key];
    final next = Map<String, String>.of(_memory)
      ..remove(key)
      ..[key] = categoryId;
    while (next.length > merchantMemoryLimit) {
      next.remove(next.keys.first);
    }
    await _store.save(next);
    _memory = next;
    return previous;
  }

  /// Mengembalikan ingatan [note] ke [previous] (`null` = lupakan).
  Future<void> restore({required String packageName, required String note, required String? previous}) async {
    await refresh();
    final key = merchantKey(packageName, note);
    final next = Map<String, String>.of(_memory)..remove(key);
    if (previous != null) next[key] = previous;
    await _store.save(next);
    _memory = next;
  }
}
