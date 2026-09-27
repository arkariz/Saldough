import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/record/domain/record_defaults.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Isian bawaan CATAT dari riwayat (UX-2, UX-3).
void main() {
  final day = DateTime(2026, 9, 10);
  ExpenseTransaction expense(String wallet, [String? category]) =>
      ExpenseTransaction(id: 'e', date: day, amount: 1, note: '', walletId: wallet, categoryKey: category);
  IncomeTransaction income(String wallet, [String? category]) =>
      IncomeTransaction(id: 'i', date: day, amount: 1, note: '', walletId: wallet, categoryKey: category);
  TransferTransaction transfer(String from, String to) =>
      TransferTransaction(id: 't', date: day, amount: 1, note: '', fromWalletId: from, toWalletId: to);

  group('initialWalletFor (UX-2)', () {
    test('pintasan kontekstual selalu menang', () {
      expect(initialWalletFor(shortcut: 'gopay', activeWalletIds: ['bca'], lastUsed: 'bca'), 'gopay');
    });

    test('satu dompet aktif: dompet itu, walau belum ada riwayat', () {
      expect(initialWalletFor(shortcut: null, activeWalletIds: ['bca']), 'bca');
    });

    test('beberapa dompet: dompet terakhir yang masih aktif, selain itu kosong', () {
      expect(initialWalletFor(shortcut: null, activeWalletIds: ['bca', 'gopay'], lastUsed: 'gopay'), 'gopay');
      expect(initialWalletFor(shortcut: null, activeWalletIds: ['bca', 'gopay'], lastUsed: 'lama'), isNull);
      expect(initialWalletFor(shortcut: null, activeWalletIds: ['bca', 'gopay']), isNull);
    });
  });

  group('RecordDefaults.from', () {
    test('dompet terakhir per jenis, dari transaksi terbaru', () {
      final defaults = RecordDefaults.from(
        [expense('gopay'), income('bca'), expense('bca'), transfer('bca', 'jago'), transfer('gopay', 'bca')],
        activeWalletIds: const {'bca', 'gopay', 'jago'},
      );
      expect(defaults.expenseWalletId, 'gopay');
      expect(defaults.incomeWalletId, 'bca');
      expect(defaults.transferFromWalletId, 'bca');
      expect(defaults.transferToWalletId, 'jago');
    });

    test('transfer yang menyentuh dompet nonaktif dilewati utuh', () {
      final defaults = RecordDefaults.from(
        [transfer('bca', 'lama'), transfer('gopay', 'bca')],
        activeWalletIds: const {'bca', 'gopay'},
      );
      expect(defaults.transferFromWalletId, 'gopay');
      expect(defaults.transferToWalletId, 'bca');
    });

    test('kategori paling sering di atas, beda huruf besar-kecil digabung dengan ejaan terbaru', () {
      final defaults = RecordDefaults.from(
        [
          expense('bca', 'Listrik PLN'),
          expense('bca', 'kopi'),
          expense('bca', 'Kopi'),
          expense('bca', 'listrik pln'),
          expense('bca', 'Kopi'),
          expense('bca', '  '),
          income('bca', 'Gaji'),
        ],
        activeWalletIds: const {'bca'},
      );
      expect(defaults.expenseCategories, ['kopi', 'Listrik PLN']);
      expect(defaults.incomeCategories, ['Gaji']);
    });
  });

  group('mergeCategorySuggestions (UX-3)', () {
    test('riwayat lebih dulu, bawaan menyusul tanpa duplikat beda huruf', () {
      expect(mergeCategorySuggestions(['makan', 'Listrik PLN'], ['Makan', 'Belanja']), [
        'makan',
        'Listrik PLN',
        'Belanja',
      ]);
    });
  });
}
