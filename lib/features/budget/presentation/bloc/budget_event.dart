part of 'budget_bloc.dart';

/// Event [BudgetBloc].
sealed class BudgetEvent {
  /// Membuat [BudgetEvent].
  const BudgetEvent();
}

/// Memuat anggaran, dompet, dan transaksi untuk pertama kali (atau lewat
/// "Coba lagi").
final class BudgetStarted extends BudgetEvent {
  /// Membuat [BudgetStarted].
  const BudgetStarted();
}

/// Memuat ulang TANPA `isLoading` — dikirim saat tab Anggaran dibuka dan
/// sesudah alur CATAT atau sunting/hapus transaksi, supaya progres berubah
/// seketika (FR-BUD-003).
final class BudgetRefreshed extends BudgetEvent {
  /// Membuat [BudgetRefreshed].
  const BudgetRefreshed();
}

/// Menambah anggaran baru (FR-BUD-001). `id` diberikan bloc.
final class BudgetAdded extends BudgetEvent {
  /// Membuat [BudgetAdded].
  const BudgetAdded({
    required this.name,
    required this.walletId,
    required this.period,
    required this.startDate,
    required this.plannedAmount,
    required this.items,
  });

  /// Nama anggaran.
  final String name;

  /// Dompet sumber.
  final String walletId;

  /// Periode.
  final BudgetPeriod period;

  /// Awal periode.
  final DateTime startDate;

  /// Nominal rencana, sen.
  final int plannedAmount;

  /// Pos-pos.
  final List<BudgetItem> items;
}

/// Menimpa anggaran yang sudah ada dengan [budget] (FR-BUD-001/002).
final class BudgetEdited extends BudgetEvent {
  /// Membuat [BudgetEdited].
  const BudgetEdited(this.budget);

  /// Anggaran hasil sunting, `id` sama dengan aslinya.
  final Budget budget;
}

/// Mengarsipkan atau mengaktifkan kembali [budget] (FR-BUD-001). Transaksi
/// yang tertaut tidak disentuh, saldo dompet tidak berubah.
final class BudgetArchiveToggled extends BudgetEvent {
  /// Membuat [BudgetArchiveToggled].
  const BudgetArchiveToggled(this.budget);

  /// Anggaran yang status arsipnya dibalik.
  final Budget budget;
}

/// Menghapus [budget] beserta posnya. Transaksi yang tertaut tetap ada.
final class BudgetDeleted extends BudgetEvent {
  /// Membuat [BudgetDeleted].
  const BudgetDeleted(this.budget);

  /// Anggaran yang dihapus.
  final Budget budget;
}

/// Mengganti penyaring status (FR-BUD-006).
final class BudgetStatusFilterChanged extends BudgetEvent {
  /// Membuat [BudgetStatusFilterChanged].
  const BudgetStatusFilterChanged(this.filter);

  /// Penyaring baru.
  final BudgetStatusFilter filter;
}

/// Mengganti penyaring dompet (FR-BUD-006). `null` = semua dompet.
final class BudgetWalletFilterChanged extends BudgetEvent {
  /// Membuat [BudgetWalletFilterChanged].
  const BudgetWalletFilterChanged(this.walletId);

  /// Dompet yang disaring, atau `null`.
  final String? walletId;
}
