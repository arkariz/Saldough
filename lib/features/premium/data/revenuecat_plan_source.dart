import 'dart:async';
import 'dart:developer' as developer;

import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/features/premium/data/entitlement_cache_store.dart';
import 'package:saldough/features/premium/data/plus_snapshot.dart';
import 'package:saldough/features/premium/data/purchases_gateway.dart';

/// Menyalin keadaan entitlement `plus` dari RevenueCat ke cache hak
/// (ADR-041 §3.3, §3.5), supaya `resolvePlan` tetap bekerja tanpa koneksi.
///
/// Aturan peta:
/// - aktif → `CachedPlus` (sumber `promotional` bila hak promosi, selain itu
///   `purchase`); aktif dengan masalah pembayaran = masa tenggang Play;
/// - tidak aktif dengan masalah pembayaran → langganan ditahan;
/// - tidak aktif tanpa masalah, atau tidak ada entitlement → cache dihapus
///   (hak benar-benar berakhir);
/// - gagal membaca (luring, SDK) → cache lama dibiarkan;
/// - bacaan **basi** (SDK menjawab dari simpanannya sendiri saat luring, jadi
///   `verifiedAt` tidak lebih baru dari verifikasi terakhir di cache) →
///   diabaikan. Tanpa ini jawaban lama yang dihitung tidak aktif terhadap jam
///   perangkat menghapus cache dan membuang tenggang luring 3 hari (T3,
///   T-24.19).
///
/// Tidak pernah melempar: gagal berarti hak yang diketahui tetap berlaku
/// sampai tenggang luringnya habis.
final class RevenueCatPlanSource {
  /// Membuat [RevenueCatPlanSource]; [onChanged] dipanggil sesudah cache ditulis.
  RevenueCatPlanSource({
    required this.gateway,
    required this.cache,
    required this.onChanged,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// Pintu ke SDK.
  final PurchasesGateway gateway;

  /// Tempat hak disalin.
  final EntitlementCacheStore cache;

  /// Memberi tahu `Entitlements` bahwa cache berubah.
  final Future<void> Function() onChanged;

  final DateTime Function() _now;
  StreamSubscription<PlusSnapshot?>? _updates;
  bool _started = false;

  /// Menyiapkan SDK dan mendengar pembaruannya. Aman dipanggil ulang.
  Future<void> start() async {
    if (_started) return;
    try {
      await gateway.configure();
      _updates = gateway.updates.listen((snapshot) => unawaited(apply(snapshot)));
      _started = true;
    } on Object catch (e) {
      developer.log('RevenueCat gagal disiapkan', error: e, name: 'Purchases');
    }
  }

  /// Mengikat ke akun [uid] (masuk). Keluar (`null`) **tidak** memanggil
  /// `logOut` RevenueCat: itu membuat pengenal anonim baru yang tidak memegang
  /// langganan, sehingga Plus yang sudah dibeli hilang hanya karena pengguna
  /// keluar akun. Pengenal tetap sampai akun lain masuk (`logIn` menggantinya)
  /// atau aplikasi dipasang ulang; keadaan hak dibaca ulang saja.
  ///
  /// [email] dan [displayName] ikut dikirim sebagai atribut pelanggan agar
  /// dikenali di dasbor RevenueCat (dicatat di `PLAY_DATA_SAFETY.md`).
  Future<void> setUser(String? uid, {String? email, String? displayName}) =>
      uid == null ? refresh() : _run(() => gateway.logIn(uid, email: email, displayName: displayName));

  /// Membaca ulang keadaan dari server.
  Future<void> refresh() => _run(gateway.fetch);

  /// Memulihkan pembelian dari akun Google Play.
  Future<void> restore() => _run(gateway.restore);

  Future<void> _run(Future<PlusSnapshot?> Function() read) async {
    if (!_started) return;
    final PlusSnapshot? snapshot;
    try {
      snapshot = await read();
    } on Object catch (e) {
      developer.log('RevenueCat gagal dibaca; hak lama dipakai', error: e, name: 'Purchases');
      return;
    }
    await apply(snapshot);
  }

  /// Menerapkan [snapshot] (mis. hasil pembelian) ke cache hak.
  Future<void> apply(PlusSnapshot? snapshot) async {
    if (await _isStale(snapshot)) return;
    if (snapshot == null || (!snapshot.isActive && !snapshot.onHold)) {
      await cache.clear();
    } else {
      await cache.save(
        CachedPlus(
          source: snapshot.isPromotional ? PlanSource.promotional : PlanSource.purchase,
          until: snapshot.expiration,
          inGrace: snapshot.inGrace,
          onHoldSince: snapshot.onHold ? snapshot.billingIssueSince : null,
          // Tanggal jawaban server, bukan jam perangkat: bacaan basi saat
          // luring tidak boleh tampak "diverifikasi sesudah `until`".
          lastVerifiedAt: snapshot.verifiedAt ?? _now(),
        ),
      );
    }
    await onChanged();
  }

  /// Bacaan basi: jawaban server-nya tidak lebih baru dari verifikasi terakhir
  /// yang tersimpan, berarti SDK mengulang simpanannya (luring), bukan
  /// membawa kabar baru. Tanpa tanggal jawaban atau tanpa cache, selalu baru.
  Future<bool> _isStale(PlusSnapshot? snapshot) async {
    final verifiedAt = snapshot?.verifiedAt;
    if (verifiedAt == null) return false;
    final cached = (await cache.load()).getOrElse((_) => null);
    return cached != null && !verifiedAt.isAfter(cached.lastVerifiedAt);
  }

  /// Melepas langganan; dipakai uji dan boot ulang.
  Future<void> dispose() async {
    await _updates?.cancel();
    _updates = null;
    _started = false;
  }
}
