import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/record/domain/capture/interpreted_transaction.dart';
import 'package:saldough/features/record/domain/capture/notification/auto_record_policy.dart';
import 'package:saldough/features/record/domain/capture/notification/notification_capture_settings.dart';
import 'package:saldough/features/record/domain/capture/notification/transaction_from_draft.dart';
import 'package:saldough/features/record/domain/capture/record_draft.dart';
import 'package:saldough/shared/transaction/transaction.dart';

void main() {
  const complete = RecordDraft(kind: DraftKind.expense, amountSen: 2500000, walletId: 'bri', categoryId: 'food');
  const noCategory = RecordDraft(kind: DraftKind.expense, amountSen: 2500000, walletId: 'bri');
  const noWallet = RecordDraft(kind: DraftKind.expense, amountSen: 2500000, categoryId: 'food');
  const unsure = RecordDraft(
    kind: DraftKind.expense,
    amountSen: 2500000,
    walletId: 'bri',
    categoryId: 'food',
    issues: {DraftIssue.kindUnclear},
  );
  const transfer = RecordDraft(kind: DraftKind.transfer, amountSen: 100, walletId: 'bri', toWalletId: 'gopay');

  test('tingkat 1 tidak pernah', () {
    const policy = AutoRecordPolicy(AutoRecordLevel.reviewAll);
    expect([complete, noCategory, transfer].any(policy.allows), isFalse);
  });

  test('tingkat 2 butuh kategori (kecuali transfer) dan dompet', () {
    const policy = AutoRecordPolicy(AutoRecordLevel.whenComplete);
    expect(policy.allows(complete), isTrue);
    expect(policy.allows(transfer), isTrue);
    expect(policy.allows(noCategory), isFalse);
    expect(policy.allows(noWallet), isFalse);
    expect(policy.allows(unsure), isFalse);
  });

  test('tingkat 3: kategori boleh kosong, dompet dan keyakinan tetap wajib', () {
    const policy = AutoRecordPolicy(AutoRecordLevel.whenAmountAndWallet);
    expect(policy.allows(noCategory), isTrue);
    expect(policy.allows(noWallet), isFalse);
    expect(policy.allows(unsure), isFalse);
    expect(
      policy.allows(const RecordDraft(kind: DraftKind.transfer, amountSen: 100, walletId: 'bri')),
      isFalse,
    );
  });

  test('dugaan ganda: jenis, dompet, nominal, dan hari sama', () {
    final date = DateTime(2026, 10, 1, 14);
    final ledger = [
      ExpenseTransaction(id: 'a', date: DateTime(2026, 10, 1, 9), amount: 2500000, note: '', walletId: 'bri'),
    ];
    expect(AutoRecordPolicy.matchesLedger(complete, date, ledger), isTrue);
    expect(AutoRecordPolicy.matchesLedger(complete, DateTime(2026, 10, 2), ledger), isFalse);
    expect(
      AutoRecordPolicy.matchesLedger(
        const RecordDraft(kind: DraftKind.income, amountSen: 2500000, walletId: 'bri'),
        date,
        ledger,
      ),
      isFalse,
    );
  });

  test('draf lengkap → transaksi; tanggal bawaan waktu notifikasi', () {
    final at = DateTime(2026, 10, 1, 14, 32);
    final expense = transactionFromDraft(complete, id: 'x', fallbackDate: at);
    expect(expense, isA<ExpenseTransaction>());
    expect(expense!.date, at);
    expect((expense as ExpenseTransaction).categoryId, 'food');
    expect(transactionFromDraft(transfer, id: 'y', fallbackDate: at), isA<TransferTransaction>());
    expect(transactionFromDraft(noWallet, id: 'z', fallbackDate: at), isNull);
  });
}
