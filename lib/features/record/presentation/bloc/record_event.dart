part of 'record_bloc.dart';

/// Event [RecordBloc].
sealed class RecordEvent {
  /// Membuat [RecordEvent].
  const RecordEvent();
}

/// Memuat daftar dompet aktif (dan pos anggaran) untuk pemilih tiap formulir.
final class RecordWalletsLoaded extends RecordEvent {
  /// Membuat [RecordWalletsLoaded].
  const RecordWalletsLoaded();
}

/// Mencatat pemasukan (FR-TXN-001).
final class IncomeRecorded extends RecordEvent {
  /// Membuat [IncomeRecorded].
  const IncomeRecorded({
    required this.walletId,
    required this.amount,
    required this.date,
    required this.note,
    this.categoryKey,
  });

  /// Dompet tujuan.
  final String walletId;

  /// Nominal dalam sen. Harus positif.
  final int amount;

  /// Kapan pemasukan ini terjadi.
  final DateTime date;

  /// Catatan bebas, boleh kosong.
  final String note;

  /// Label pengelompokan bebas, boleh kosong.
  final String? categoryKey;
}

/// Mencatat pengeluaran (FR-TXN-002).
final class ExpenseRecorded extends RecordEvent {
  /// Membuat [ExpenseRecorded].
  const ExpenseRecorded({
    required this.walletId,
    required this.amount,
    required this.date,
    required this.note,
    this.categoryKey,
    this.budgetItemId,
  });

  /// Dompet asal.
  final String walletId;

  /// Nominal dalam sen. Harus positif.
  final int amount;

  /// Kapan pengeluaran ini terjadi.
  final DateTime date;

  /// Catatan bebas, boleh kosong.
  final String note;

  /// Label pengelompokan bebas, boleh kosong.
  final String? categoryKey;

  /// Pos anggaran yang ditautkan (T-4.4), atau `null`.
  final String? budgetItemId;
}

/// Mencatat transfer antar dompet (FR-TXN-003).
final class TransferRecorded extends RecordEvent {
  /// Membuat [TransferRecorded].
  const TransferRecorded({
    required this.fromWalletId,
    required this.toWalletId,
    required this.amount,
    required this.date,
    required this.note,
    this.budgetItemId,
  });

  /// Dompet asal.
  final String fromWalletId;

  /// Dompet tujuan. Harus berbeda dari [fromWalletId] — ditegakkan di
  /// formulir (tombol Catat dinonaktifkan) sebelum event ini terkirim.
  final String toWalletId;

  /// Nominal dalam sen. Harus positif.
  final int amount;

  /// Kapan transfer ini terjadi.
  final DateTime date;

  /// Catatan bebas, boleh kosong.
  final String note;

  /// Pos anggaran yang ditautkan (T-4.4), atau `null`. Hanya pos milik
  /// anggaran dompet ASAL yang sah — lihat `budgetItemChoicesFor`.
  final String? budgetItemId;
}
