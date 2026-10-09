import 'package:saldough/features/notification_capture/domain/entities/capture_inbox_entry.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_capture_settings.dart';
import 'package:saldough/shared/capture/capture.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Boleh-tidaknya draf notifikasi dicatat tanpa ditinjau (ADR-032 §3.4).
final class AutoRecordPolicy {
  /// Membuat [AutoRecordPolicy] untuk [level].
  const AutoRecordPolicy(this.level);

  /// Tingkat otomatis pilihan pengguna.
  final AutoRecordLevel level;

  /// `true` bila [draft] lolos tingkat [level]. Dugaan ganda dan kelayakan
  /// pola dicek terpisah oleh pemroses.
  bool allows(RecordDraft draft) {
    if (level == AutoRecordLevel.reviewAll || !draft.isConfident) return false;
    final walletsFilled = draft.walletId != null && (draft.kind != DraftKind.transfer || draft.toWalletId != null);
    if (!walletsFilled) return false;
    return switch (level) {
      AutoRecordLevel.reviewAll => false,
      AutoRecordLevel.whenComplete => draft.kind == DraftKind.transfer || draft.categoryId != null,
      AutoRecordLevel.whenAmountAndWallet => true,
    };
  }

  /// Alasan [draft] ditinjau alih-alih dicatat otomatis (QA PR #43 F16), atau
  /// `null` bila [allows] dan pola layak. [autoEligible] `false` = dari pola
  /// yang belum terverifikasi.
  CaptureReviewReason? reviewReason(RecordDraft draft, {required bool autoEligible}) {
    if (level == AutoRecordLevel.reviewAll) return CaptureReviewReason.autoRecordOff;
    final issues = draft.issues;
    if (draft.amountSen == null ||
        issues.any(
          (i) => const {
            DraftIssue.amountMissing,
            DraftIssue.amountMultiple,
            DraftIssue.amountWithoutUnit,
            DraftIssue.amountAmbiguous,
          }.contains(i),
        )) {
      return CaptureReviewReason.amountUnclear;
    }
    if (issues.contains(DraftIssue.currencyUnsupported)) return CaptureReviewReason.otherCurrency;
    if (issues.contains(DraftIssue.kindUnclear) ||
        issues.contains(DraftIssue.transferSourceMissing) ||
        issues.contains(DraftIssue.transferTargetMissing)) {
      return CaptureReviewReason.kindUnclear;
    }
    if (issues.contains(DraftIssue.walletUnknown)) return CaptureReviewReason.walletUnknown;
    if (issues.contains(DraftIssue.categoryUnknown)) return CaptureReviewReason.categoryUnclear;
    if (issues.contains(DraftIssue.dateUnclear)) return CaptureReviewReason.dateUnclear;
    if (draft.walletId == null) return CaptureReviewReason.walletUnknown;
    if (draft.kind == DraftKind.transfer && draft.toWalletId == null) return CaptureReviewReason.kindUnclear;
    if (!autoEligible) return CaptureReviewReason.newPattern;
    if (!allows(draft)) return CaptureReviewReason.categoryUnclear;
    return null;
  }

  /// `true` bila [draft] mungkin sudah tercatat: transaksi berjenis, dompet,
  /// dan nominal sama di hari yang sama di [ledger].
  static bool matchesLedger(RecordDraft draft, DateTime date, List<Transaction> ledger) {
    final amount = draft.amountSen;
    if (amount == null) return false;
    bool sameDay(DateTime d) => d.year == date.year && d.month == date.month && d.day == date.day;
    return ledger.any((t) {
      if (t.amount != amount || !sameDay(t.date)) return false;
      return switch ((draft.kind, t)) {
        (DraftKind.expense, ExpenseTransaction(:final walletId)) => walletId == draft.walletId,
        (DraftKind.income, IncomeTransaction(:final walletId)) => walletId == draft.walletId,
        (DraftKind.transfer, TransferTransaction(:final fromWalletId, :final toWalletId)) =>
          fromWalletId == draft.walletId && toWalletId == draft.toWalletId,
        _ => false,
      };
    });
  }
}
