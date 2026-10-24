import 'package:dependencies/dependencies.dart';
import 'package:saldough/core/foundation/entitlement/plan_state.dart';

/// Pengganti paket untuk uji dan pengembangan (ADR-041 §3.10). Hanya pernah
/// bernilai selain [auto] di build non-rilis; pembacanya ada di akar komposisi.
enum PlanOverride {
  /// Tanpa pengganti.
  auto,

  /// Paksa Gratis meski hak ada.
  free,

  /// Uji coba yang berakhir besok.
  trial,

  /// Plus tanpa batas waktu.
  plus,
}

/// Hak RevenueCat terakhir yang diketahui (ADR-041 §3.3), disimpan supaya
/// Plus tetap berlaku tanpa koneksi.
final class CachedPlus extends Equatable {
  /// Membuat [CachedPlus].
  const CachedPlus({
    required this.source,
    required this.lastVerifiedAt,
    this.until,
    this.inGrace = false,
    this.onHoldSince,
  });

  /// `purchase` atau `promotional`.
  final PlanSource source;

  /// Akhir periode berbayar; `null` = tanpa tanggal berakhir.
  final DateTime? until;

  /// Play melaporkan masa tenggang pembayaran.
  final bool inGrace;

  /// Langganan ditahan sejak tanggal ini, atau `null`.
  final DateTime? onHoldSince;

  /// Terakhir kali RevenueCat berhasil dibaca.
  final DateTime lastVerifiedAt;

  @override
  List<Object?> get props => [
    source,
    until,
    inGrace,
    onHoldSince,
    lastVerifiedAt,
  ];
}

/// Rekaman uji coba satu akun di perangkat ini (ADR-041 §3.4).
final class TrialRecord extends Equatable {
  /// Membuat [TrialRecord].
  const TrialRecord({
    required this.uid,
    required this.start,
    required this.endsOn,
  });

  /// Akun pemilik uji coba.
  final String uid;

  /// Hari mulai.
  final DateTime start;

  /// Hari terakhir (inklusif).
  final DateTime endsOn;

  @override
  List<Object?> get props => [uid, start, endsOn];
}

/// Tenggang luring sesudah hak berakhir tanpa bisa diverifikasi (§3.3).
const offlineGrace = Duration(days: 3);

/// Keadaan paket dari seluruh sumbernya (ADR-041 §3.2, §3.3, §3.13). Murni:
/// tidak pernah melempar, tidak membaca jam sendiri.
///
/// Urutan: [override] (non-rilis) → hak RevenueCat yang masih berlaku
/// (termasuk tenggang luring) → pra-peluncuran ([launchAt] kosong atau belum
/// tiba: masuk akun = Plus, tanpa akun = Gratis) → uji coba akun yang sedang
/// masuk → ditahan → Gratis.
PlanState resolvePlan({
  required DateTime now,
  required DateTime? launchAt,
  required String? signedInUid,
  TrialRecord? trial,
  CachedPlus? cached,
  PlanOverride override = PlanOverride.auto,
}) {
  final today = DateTime(now.year, now.month, now.day);
  switch (override) {
    case PlanOverride.plus:
      return const PlusPlan(source: PlanSource.override);
    case PlanOverride.free:
      return const FreePlan();
    case PlanOverride.trial:
      return TrialPlan(
        endsOn: DateTime(today.year, today.month, today.day + 1),
      );
    case PlanOverride.auto:
      break;
  }

  if (cached != null &&
      cached.onHoldSince == null &&
      _cacheValid(cached, now)) {
    return PlusPlan(
      source: cached.source,
      until: cached.until,
      inGrace: cached.inGrace,
    );
  }

  final prelaunch = launchAt == null || now.isBefore(launchAt);
  if (prelaunch) {
    return signedInUid == null
        ? const FreePlan()
        : const PlusPlan(source: PlanSource.prelaunch);
  }

  if (signedInUid != null &&
      trial != null &&
      trial.uid == signedInUid &&
      !today.isAfter(trial.endsOn)) {
    return TrialPlan(endsOn: trial.endsOn);
  }

  final onHold = cached?.onHoldSince;
  if (onHold != null) return OnHoldPlan(since: onHold);
  return const FreePlan();
}

/// Hak cache berlaku sampai `until`; bila RevenueCat belum bisa dibaca lagi
/// sejak `until` lewat, diperpanjang [offlineGrace]. Bila sudah dibaca sesudah
/// `until` dan tidak diperbarui, hak memang berakhir.
bool _cacheValid(CachedPlus cached, DateTime now) {
  final until = cached.until;
  if (until == null) return true;
  if (!now.isAfter(until)) return true;
  if (cached.lastVerifiedAt.isAfter(until)) return false;
  return !now.isAfter(until.add(offlineGrace));
}
