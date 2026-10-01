import 'package:saldough/features/record/domain/capture/interpreted_transaction.dart';
import 'package:saldough/features/record/domain/capture/notification/notification_capture_settings.dart';
import 'package:saldough/features/record/domain/capture/record_draft.dart';
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
