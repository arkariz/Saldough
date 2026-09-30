import 'package:saldough/shared/transaction/domain/transaction.dart';

/// Model serialisasi [Transaction], terpisah dari entitas domain (tanpa
/// `freezed`, mengikuti konvensi monorepo — lihat ARCHITECTURE_OVERVIEW.md).
///
/// [Transaction] adalah tipe tertutup dengan tiga bentuk field yang
/// berbeda; model ini meratakannya jadi satu bentuk JSON beranotasi [type],
/// dengan field yang tidak relevan untuk jenis itu dibiarkan `null`.
final class TransactionModel {
  /// Membuat [TransactionModel].
  const TransactionModel({
    required this.id,
    required this.type,
    required this.date,
    required this.amount,
    required this.note,
    this.categoryId,
    this.legacyCategoryKey,
    this.walletId,
    this.budgetItemId,
    this.fromWalletId,
    this.toWalletId,
    this.freelancePaymentId,
  });

  /// Membaca [TransactionModel] dari JSON.
  factory TransactionModel.fromJson(Map<String, dynamic> json) => TransactionModel(
        id: json['id'] as String,
        type: json['type'] as String,
        date: DateTime.parse(json['date'] as String),
        amount: json['amount'] as int,
        note: json['note'] as String,
        categoryId: json['categoryId'] as String?,
        legacyCategoryKey: json['categoryKey'] as String?,
        walletId: json['walletId'] as String?,
        budgetItemId: json['budgetItemId'] as String?,
        fromWalletId: json['fromWalletId'] as String?,
        toWalletId: json['toWalletId'] as String?,
        freelancePaymentId: json['freelancePaymentId'] as String?,
      );

  /// Membuat [TransactionModel] dari entitas domain [Transaction].
  factory TransactionModel.fromEntity(Transaction transaction) => switch (transaction) {
        IncomeTransaction() => TransactionModel(
            id: transaction.id,
            type: _typeIncome,
            date: transaction.date,
            amount: transaction.amount,
            note: transaction.note,
            categoryId: transaction.categoryId,
            walletId: transaction.walletId,
            freelancePaymentId: transaction.freelancePaymentId,
          ),
        ExpenseTransaction() => TransactionModel(
            id: transaction.id,
            type: _typeExpense,
            date: transaction.date,
            amount: transaction.amount,
            note: transaction.note,
            categoryId: transaction.categoryId,
            walletId: transaction.walletId,
            budgetItemId: transaction.budgetItemId,
          ),
        TransferTransaction() => TransactionModel(
            id: transaction.id,
            type: _typeTransfer,
            date: transaction.date,
            amount: transaction.amount,
            note: transaction.note,
            fromWalletId: transaction.fromWalletId,
            toWalletId: transaction.toWalletId,
            budgetItemId: transaction.budgetItemId,
          ),
      };

  static const _typeIncome = 'income';
  static const _typeExpense = 'expense';
  static const _typeTransfer = 'transfer';

  /// Versi skema dokumen ini. Naikkan kalau bentuk field berubah.
  ///
  /// Versi 2 (ADR-026): `categoryKey` teks bebas diganti `categoryId`.
  static const schemaVersion = 2;

  /// Identitas transaksi.
  final String id;

  /// Jenis transaksi: `'income'`, `'expense'`, atau `'transfer'`.
  final String type;

  /// Kapan peristiwanya terjadi.
  final DateTime date;

  /// Nominal dalam sen.
  final int amount;

  /// Catatan bebas.
  final String note;

  /// Kategori — dipakai `income` dan `expense` (ADR-026).
  final String? categoryId;

  /// Label kategori teks bebas skema 1, hanya dibaca untuk migrasi
  /// (`MigrateLegacyCategories`) dan tidak pernah sampai ke entitas domain.
  /// Tetap ditulis ulang selama belum dimigrasi, supaya menyunting transaksi
  /// sebelum migrasi berhasil tidak menghapus labelnya.
  final String? legacyCategoryKey;

  /// Dompet yang tersentuh — dipakai `income` dan `expense`.
  final String? walletId;

  /// Pos anggaran tertaut — dipakai `expense` dan `transfer`.
  final String? budgetItemId;

  /// Dompet asal — dipakai `transfer` saja.
  final String? fromWalletId;

  /// Dompet tujuan — dipakai `transfer` saja.
  final String? toWalletId;

  /// Pembayaran freelance pemilik transaksi — dipakai `income` saja
  /// (ADR-019). Kunci ini baru ditulis kalau terisi, jadi dokumen lama tidak
  /// berubah bentuk.
  final String? freelancePaymentId;

  /// Salinan dengan kategori [categoryId] dan label lama dibuang — hasil
  /// migrasi ADR-026 §3.4.
  TransactionModel withMigratedCategory(String? categoryId) => TransactionModel(
        id: id,
        type: type,
        date: date,
        amount: amount,
        note: note,
        categoryId: type == _typeTransfer ? null : (this.categoryId ?? categoryId),
        walletId: walletId,
        budgetItemId: budgetItemId,
        fromWalletId: fromWalletId,
        toWalletId: toWalletId,
        freelancePaymentId: freelancePaymentId,
      );

  /// Salinan yang membawa [legacyCategoryKey] milik [previous] — dipakai saat
  /// menimpa dokumen skema 1 yang belum dimigrasi, supaya labelnya tidak
  /// hilang karena entitas domain tidak mengenalnya.
  TransactionModel keepingLegacyCategoryOf(TransactionModel previous) =>
      categoryId != null || previous.legacyCategoryKey == null || isTransfer
          ? this
          : TransactionModel(
              id: id,
              type: type,
              date: date,
              amount: amount,
              note: note,
              legacyCategoryKey: previous.legacyCategoryKey,
              walletId: walletId,
              budgetItemId: budgetItemId,
              fromWalletId: fromWalletId,
              toWalletId: toWalletId,
              freelancePaymentId: freelancePaymentId,
            );

  /// `true` untuk transfer (tidak berkategori).
  bool get isTransfer => type == _typeTransfer;

  /// `true` untuk pemasukan.
  bool get isIncome => type == _typeIncome;

  /// Menulis [TransactionModel] ke JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'date': date.toIso8601String(),
        'amount': amount,
        'note': note,
        if (categoryId != null) 'categoryId': categoryId,
        if (legacyCategoryKey != null) 'categoryKey': legacyCategoryKey,
        'walletId': walletId,
        'budgetItemId': budgetItemId,
        'fromWalletId': fromWalletId,
        'toWalletId': toWalletId,
        if (freelancePaymentId != null) 'freelancePaymentId': freelancePaymentId,
      };

  /// Mengubah model jadi entitas domain [Transaction].
  ///
  /// Melempar [FormatException] kalau [type] tidak dikenal, atau kalau
  /// field wajib untuk jenis itu ternyata `null` — keduanya menandakan
  /// dokumen tersimpan rusak, bukan keadaan yang bisa ditolerir diam-diam.
  Transaction toEntity() => switch (type) {
        _typeIncome => IncomeTransaction(
            id: id,
            date: date,
            amount: amount,
            note: note,
            categoryId: categoryId,
            walletId: walletId ?? (throw FormatException('TransactionModel income tanpa walletId: $id')),
            freelancePaymentId: freelancePaymentId,
          ),
        _typeExpense => ExpenseTransaction(
            id: id,
            date: date,
            amount: amount,
            note: note,
            categoryId: categoryId,
            walletId: walletId ?? (throw FormatException('TransactionModel expense tanpa walletId: $id')),
            budgetItemId: budgetItemId,
          ),
        _typeTransfer => TransferTransaction(
            id: id,
            date: date,
            amount: amount,
            note: note,
            fromWalletId: fromWalletId ?? (throw FormatException('TransactionModel transfer tanpa fromWalletId: $id')),
            toWalletId: toWalletId ?? (throw FormatException('TransactionModel transfer tanpa toWalletId: $id')),
            budgetItemId: budgetItemId,
          ),
        _ => throw FormatException('Jenis transaksi tidak dikenal: $type ($id)'),
      };
}
