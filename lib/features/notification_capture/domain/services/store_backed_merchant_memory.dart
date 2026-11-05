import 'package:saldough/features/notification_capture/domain/repositories/merchant_memory_store.dart';
import 'package:saldough/features/notification_capture/domain/services/capture_resolver.dart';

/// Batas jumlah ingatan; yang tertua dibuang saat penuh.
const merchantMemoryLimit = 500;

/// Catatan dinormalkan: huruf kecil dan spasi dirapatkan, supaya "ES BUAH" dan
/// "es  buah" satu pedagang.
String normalizeMerchant(String note) => note.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

/// Kunci ingatan untuk [note] dari [packageName].
String merchantKey(String packageName, String note) => '$packageName|${normalizeMerchant(note)}';

/// Kunci ingatan pos anggaran (E2/B-86) untuk [note] dari [packageName].
/// Awalan `pos|` tidak bisa bertabrakan dengan kunci kategori karena nama
/// paket tidak memuat `|`. Yang disimpan adalah NAMA pos, bukan id: pos
/// anggaran baru lahir tiap periode dan idnya tidak berlanjut.
String merchantBudgetKey(String packageName, String note) => 'pos|${merchantKey(packageName, note)}';

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
  Future<String?> remember({required String packageName, required String note, required String categoryId}) =>
      _put(merchantKey(packageName, note), note, categoryId);

  /// Mengembalikan ingatan [note] ke [previous] (`null` = lupakan).
  Future<void> restore({required String packageName, required String note, required String? previous}) =>
      _restore(merchantKey(packageName, note), previous);

  /// Nama pos anggaran yang diingat untuk [note] dari [packageName] (E2), atau `null`.
  String? budgetNameFor({required String packageName, required String note}) {
    if (normalizeMerchant(note).isEmpty) return null;
    return _memory[merchantBudgetKey(packageName, note)];
  }

  /// Mengingat nama pos [budgetName]; mengembalikan yang lama untuk Batalkan.
  Future<String?> rememberBudget({required String packageName, required String note, required String budgetName}) =>
      _put(merchantBudgetKey(packageName, note), note, budgetName);

  /// Mengembalikan ingatan pos [note] ke [previous] (`null` = lupakan).
  Future<void> restoreBudget({required String packageName, required String note, required String? previous}) =>
      _restore(merchantBudgetKey(packageName, note), previous);

  Future<String?> _put(String key, String note, String value) async {
    await refresh();
    if (normalizeMerchant(note).isEmpty) return null;
    final previous = _memory[key];
    final next = Map<String, String>.of(_memory)
      ..remove(key)
      ..[key] = value;
    while (next.length > merchantMemoryLimit) {
      next.remove(next.keys.first);
    }
    await _store.save(next);
    _memory = next;
    return previous;
  }

  Future<void> _restore(String key, String? previous) async {
    await refresh();
    final next = Map<String, String>.of(_memory)..remove(key);
    if (previous != null) next[key] = previous;
    await _store.save(next);
    _memory = next;
  }
}
