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
CaptureCardClass cardClassOf(CaptureInboxEntry entry, {OccurrenceMatch? match, Transaction? existing}) {
  final draft = entry.draft;
  if (existing != null || entry.possibleDuplicate) return CaptureCardClass.needsInput;
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

/// Boleh dicatat satu ketuk dari kartu (ADR-044 §3.6, §3.8).
///
/// Kemunculan rutin bernominal tetap yang cocok persis tetap **Gratis**:
/// aksi yang sama sudah satu ketuk di segmen Rutin tanpa cabang hak (ADR-041
/// §3.8), jadi kartu ini tidak boleh punya gerbang berbeda. Selebihnya
/// (rutin kira-kira, kartu dikenali) Plus.
bool oneTapAllowed({required CaptureCardClass cardClass, required OccurrenceMatch? match, required bool isPlus}) =>
    switch (cardClass) {
      CaptureCardClass.needsInput => false,
      CaptureCardClass.planned => isPlus || (match?.exact ?? false),
      CaptureCardClass.recognized => isPlus,
    };
