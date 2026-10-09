import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/transaction/transaction_presentation.dart';

/// Judul transaksi (QA PR #43 F2): tanpa catatan dan kategori, judulnya
/// jenis transaksi, bukan "Tanpa judul".
void main() {
  final date = DateTime(2026, 10, 9, 13, 42);

  for (final locale in [AppLocale.id, AppLocale.en]) {
    test('fallback jenis transaksi (${locale.languageCode})', () async {
      await LocaleSettings.setLocale(locale);
      addTearDown(() => LocaleSettings.setLocale(AppLocale.id));

      final transfer = TransferTransaction(
        id: 't',
        date: date,
        amount: 100,
        note: '',
        fromWalletId: 'a',
        toWalletId: 'b',
      );
      final expense = ExpenseTransaction(id: 'e', date: date, amount: 100, note: '', walletId: 'a');
      final income = IncomeTransaction(id: 'i', date: date, amount: 100, note: '', walletId: 'a');

      expect(transactionTitle(transfer), t.record.kindTransfer);
      expect(transactionTitle(expense), t.record.kindExpense);
      expect(transactionTitle(income), t.record.kindIncome);
      expect(
        transactionTitle(expense),
        locale == AppLocale.id ? 'Pengeluaran' : 'Expense',
      );
    });
  }
}
