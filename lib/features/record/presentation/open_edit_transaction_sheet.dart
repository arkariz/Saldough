import 'package:flutter/material.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/record/presentation/bloc/record_bloc.dart';
import 'package:saldough/features/record/presentation/widgets/expense_form_sheet.dart';
import 'package:saldough/features/record/presentation/widgets/income_form_sheet.dart';
import 'package:saldough/features/record/presentation/widgets/transfer_form_sheet.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Membuka formulir CATAT yang SAMA dengan mode sunting untuk [transaction]
/// (FR-TXN-005) dan mengembalikan transaksi hasil sunting, atau `null` kalau
/// dibatalkan.
///
/// Ini BUKAN jalur pembuatan transaksi (CLAUDE.md aturan 8): tidak ada
/// transaksi baru yang lahir, hanya transaksi yang sudah ada ditimpa. Karena
/// itu formulirnya dipakai ulang (bukan formulir baru), dan hasilnya
/// mempertahankan `id` transaksi asal -- pembetulan selalu lewat sunting atau
/// hapus, tidak pernah lewat transaksi penyeimbang.
///
/// Nilai yang tidak ada di formulir dipertahankan dari [transaction]:
/// `budgetItemId` (tautan anggaran, Fase 4) dan, untuk transfer,
/// `categoryKey`. Objek dibangun BARU, bukan lewat `copyWith`, karena
/// `copyWith` (`?? this.x`) tidak bisa mengosongkan kategori yang dihapus
/// pengguna.
///
/// [wallets] adalah pilihan dompet di formulir -- pemanggil wajib menyertakan
/// dompet milik [transaction] sendiri walau sudah dinonaktifkan, supaya
/// pilihan awalnya tidak hilang. Formulir menerima salinan dompet dengan saldo
/// SEBELUM [transaction] ada (lihat [_withoutEffectOf]): `currentBalance`
/// sudah memuat transaksi yang sedang disunting, jadi tanpa pembalikan itu
/// pratinjau saldo formulir ("sebelum -> sesudah") mengurangkannya dua kali.
Future<Transaction?> openEditTransactionSheet(
  BuildContext context, {
  required Transaction transaction,
  required List<Wallet> wallets,
}) async {
  final baseWallets = _withoutEffectOf(transaction, wallets);
  final result = await showFullScreenSheet<Object>(
    context,
    builder: (_) => switch (transaction) {
      IncomeTransaction() => IncomeFormSheet(wallets: baseWallets, initial: transaction),
      ExpenseTransaction() => ExpenseFormSheet(wallets: baseWallets, initial: transaction),
      TransferTransaction() => TransferFormSheet(wallets: baseWallets, initial: transaction),
    },
  );

  return switch ((transaction, result)) {
    (
      IncomeTransaction(),
      IncomeRecorded(:final date, :final amount, :final note, :final walletId, :final categoryKey),
    ) =>
      IncomeTransaction(
        id: transaction.id,
        date: date,
        amount: amount,
        note: note,
        walletId: walletId,
        categoryKey: categoryKey,
      ),
    (
      ExpenseTransaction(:final budgetItemId),
      ExpenseRecorded(:final date, :final amount, :final note, :final walletId, :final categoryKey),
    ) =>
      ExpenseTransaction(
        id: transaction.id,
        date: date,
        amount: amount,
        note: note,
        walletId: walletId,
        categoryKey: categoryKey,
        budgetItemId: budgetItemId,
      ),
    (
      TransferTransaction(categoryKey: final originalCategory, :final budgetItemId),
      TransferRecorded(:final date, :final amount, :final note, :final fromWalletId, :final toWalletId),
    ) =>
      TransferTransaction(
        id: transaction.id,
        date: date,
        amount: amount,
        note: note,
        fromWalletId: fromWalletId,
        toWalletId: toWalletId,
        categoryKey: originalCategory,
        budgetItemId: budgetItemId,
      ),
    _ => null,
  };
}

/// Salinan [wallets] dengan `currentBalance` dibalik dari efek [transaction],
/// yakni saldo dompet seandainya transaksi itu tidak pernah dicatat.
List<Wallet> _withoutEffectOf(Transaction transaction, List<Wallet> wallets) => [
  for (final wallet in wallets)
    wallet.copyWith(currentBalance: wallet.currentBalance - _effectOn(transaction, wallet.id)),
];

/// Perubahan saldo dompet [walletId] yang disebabkan [transaction]: pemasukan
/// menambah, pengeluaran mengurangi, transfer mengurangi asal dan menambah
/// tujuan.
int _effectOn(Transaction transaction, String walletId) => switch (transaction) {
  IncomeTransaction(walletId: final id, :final amount) => id == walletId ? amount : 0,
  ExpenseTransaction(walletId: final id, :final amount) => id == walletId ? -amount : 0,
  TransferTransaction(:final fromWalletId, :final toWalletId, :final amount) =>
    (fromWalletId == walletId ? -amount : 0) + (toWalletId == walletId ? amount : 0),
};
