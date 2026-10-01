import 'package:saldough/features/record/domain/capture/interpreted_transaction.dart';
import 'package:saldough/features/record/domain/capture/record_draft.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Transaksi dari draf lengkap, untuk pencatatan otomatis (ADR-032 §3.5).
/// `null` bila draf belum lengkap (nominal atau dompet kosong). Tanggal:
/// tanggal draf, atau [fallbackDate] (waktu notifikasi).
Transaction? transactionFromDraft(RecordDraft draft, {required String id, required DateTime fallbackDate}) {
  final amount = draft.amountSen;
  final walletId = draft.walletId;
  if (amount == null || walletId == null) return null;
  final date = draft.date ?? fallbackDate;
  return switch (draft.kind) {
    DraftKind.expense => ExpenseTransaction(
      id: id,
      date: date,
      amount: amount,
      note: draft.note,
      walletId: walletId,
      categoryId: draft.categoryId,
    ),
    DraftKind.income => IncomeTransaction(
      id: id,
      date: date,
      amount: amount,
      note: draft.note,
      walletId: walletId,
      categoryId: draft.categoryId,
    ),
    DraftKind.transfer => switch (draft.toWalletId) {
      final to? => TransferTransaction(
        id: id,
        date: date,
        amount: amount,
        note: draft.note,
        fromWalletId: walletId,
        toWalletId: to,
      ),
      null => null,
    },
  };
}
