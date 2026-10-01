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
    this.categoryId,
    this.sourceIconId,
  });

  /// Dompet tujuan.
  final String walletId;

  /// Nominal dalam sen. Harus positif.
  final int amount;

  /// Kapan pemasukan ini terjadi.
  final DateTime date;

  /// Catatan bebas, boleh kosong.
  final String note;

  /// Kategori (ADR-026), boleh kosong.
  final String? categoryId;

  /// Ikon notifikasi asal (ADR-032 §3.10), dari draf kotak masuk.
  final String? sourceIconId;
}

/// Mencatat pengeluaran (FR-TXN-002).
final class ExpenseRecorded extends RecordEvent {
  /// Membuat [ExpenseRecorded].
  const ExpenseRecorded({
    required this.walletId,
    required this.amount,
    required this.date,
    required this.note,
    this.categoryId,
    this.budgetItemId,
    this.sourceIconId,
  });

  /// Dompet asal.
  final String walletId;

  /// Nominal dalam sen. Harus positif.
  final int amount;

  /// Kapan pengeluaran ini terjadi.
  final DateTime date;

  /// Catatan bebas, boleh kosong.
  final String note;

  /// Kategori (ADR-026), boleh kosong.
  final String? categoryId;

  /// Pos anggaran yang ditautkan (T-4.4), atau `null`.
  final String? budgetItemId;

  /// Ikon notifikasi asal (ADR-032 §3.10), dari draf kotak masuk.
  final String? sourceIconId;
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
    this.sourceIconId,
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

  /// Ikon notifikasi asal (ADR-032 §3.10), dari draf kotak masuk.
  final String? sourceIconId;
}

/// Menampilkan galat dari operasi di luar event (mis. "Tambah kategori",
/// `RecordBloc.createCategory`) lewat efek galat biasa.
final class RecordFailureOccurred extends RecordEvent {
  /// Membuat [RecordFailureOccurred].
  const RecordFailureOccurred(this.failure);

  /// Kegagalan yang ditampilkan.
  final Failure failure;
}

/// Event pencatatan [event] dengan ikon notifikasi asal [sourceIconId]
/// (draf dari kotak masuk, ADR-032 §3.10); event lain dikembalikan apa adanya.
RecordEvent withSourceIcon(RecordEvent event, String? sourceIconId) => switch (event) {
  _ when sourceIconId == null => event,
  IncomeRecorded() => IncomeRecorded(
    walletId: event.walletId,
    amount: event.amount,
    date: event.date,
    note: event.note,
    categoryId: event.categoryId,
    sourceIconId: sourceIconId,
  ),
  ExpenseRecorded() => ExpenseRecorded(
    walletId: event.walletId,
    amount: event.amount,
    date: event.date,
    note: event.note,
    categoryId: event.categoryId,
    budgetItemId: event.budgetItemId,
    sourceIconId: sourceIconId,
  ),
  TransferRecorded() => TransferRecorded(
    fromWalletId: event.fromWalletId,
    toWalletId: event.toWalletId,
    amount: event.amount,
    date: event.date,
    note: event.note,
    budgetItemId: event.budgetItemId,
    sourceIconId: sourceIconId,
  ),
  _ => event,
};
