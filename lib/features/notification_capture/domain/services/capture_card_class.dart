import 'package:saldough/features/notification_capture/domain/entities/capture_inbox_entry.dart';
import 'package:saldough/shared/capture/capture.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Jenis kartu tangkapan di kotak masuk (ADR-044 §3.1, NOTIFICATION_CAPTURE_V2 §4).
///
/// Sementara dihitung dari data kartu; penentu bersama (T-26.2) akan
/// menghasilkan kelas yang sama bersama alasannya.
enum CaptureCardClass {
  /// Cocok dengan kemunculan rutin dan semua bidang terisi.
  planned,

  /// Dompet, jenis, nominal terbaca, dan kategori (atau transfer) terpetakan.
  recognized,

  /// Ada bidang yang tidak terpetakan atau ambigu: selalu membuka CATAT.
  needsInput,
}

/// Kelas kartu [entry]. [match] adalah kemunculan rutin yang cocok (tunggal,
/// tidak ditebak) dan [existing] catatan di buku besar yang tampak sama
/// (duplikat selalu perlu diputuskan pengguna).
///
/// "Tanpa tebakan": dompet, jenis, dan nominal terbaca tanpa `issues`; untuk
/// transfer kedua dompet terpetakan; kategori berasal dari draf (rencana,
/// aturan, atau ingatan).
CaptureCardClass cardClassOf(CaptureInboxEntry entry, {OccurrenceMatch? match, Transaction? existing}) =>
    cardClassOfDraft(entry.draft, match: match, duplicate: existing != null || entry.possibleDuplicate);

/// Kelas untuk [draft] yang belum jadi kartu (dipakai penentu). [duplicate]:
/// catatan yang sama sudah ada atau tangkapan serupa baru saja masuk.
/// [planUnclear]: pola terikat ke rutin tetapi kemunculannya tidak jelas, atau
/// beberapa kemunculan cocok; tidak ditebak, jadi perlu diputuskan pengguna.
CaptureCardClass cardClassOfDraft(
  RecordDraft draft, {
  OccurrenceMatch? match,
  bool duplicate = false,
  bool planUnclear = false,
}) {
  if (duplicate || planUnclear) return CaptureCardClass.needsInput;
  final complete =
      draft.amountSen != null &&
      draft.walletId != null &&
      (draft.kind != DraftKind.transfer || draft.toWalletId != null) &&
      draft.issues.isEmpty;
  if (!complete) return CaptureCardClass.needsInput;
  if (match != null) return CaptureCardClass.planned;
  if (draft.kind == DraftKind.transfer || draft.categoryId != null) return CaptureCardClass.recognized;
  return CaptureCardClass.needsInput;
}

/// Boleh dicatat satu ketuk dari kartu (ADR-044 §3.6, §3.8): kartu cocok
/// rencana atau dikenali, **hanya Plus** (keputusan pemilik 4 Nov 2026,
/// supaya Plus punya nilai lebih). Gratis tetap lewat CATAT terisi. Satu
/// ketuk untuk rutin bernominal tetap di segmen Rutin tidak terpengaruh: itu
/// layar lain dengan gerbangnya sendiri (ADR-041 §3.8).
bool oneTapAllowed({required CaptureCardClass cardClass, required bool isPlus}) =>
    isPlus && cardClass != CaptureCardClass.needsInput;
