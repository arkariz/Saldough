part of 'wallet_bloc.dart';

/// Event [WalletBloc].
sealed class WalletEvent {
  /// Membuat [WalletEvent].
  const WalletEvent();
}

/// Memuat dompet untuk pertama kali (atau lewat "Coba lagi").
final class WalletStarted extends WalletEvent {
  /// Membuat [WalletStarted].
  const WalletStarted();
}

/// Memuat ulang dompet TANPA `isLoading` -- dikirim saat tab Dompet dibuka
/// dan sesudah alur CATAT selesai, ketika saldo dompet bisa sudah berubah
/// karena transaksi baru, sunting, atau hapus di tempat lain.
final class WalletRefreshed extends WalletEvent {
  /// Membuat [WalletRefreshed].
  const WalletRefreshed();
}

/// Menambah dompet baru (FR-WAL-001). [initialBalance] dalam sen; saldo
/// tercatat awalnya sama dengan itu.
final class WalletAdded extends WalletEvent {
  /// Membuat [WalletAdded].
  const WalletAdded({required this.name, required this.iconKey, required this.initialBalance});

  /// Nama dompet.
  final String name;

  /// Kunci ikon (`Wallet.iconKey`).
  final String iconKey;

  /// Saldo awal, sen.
  final int initialBalance;
}

/// Menyunting [original]: nama, ikon, status aktif, dan -- kalau
/// [currentBalance] tidak `null` -- saldo saat ini (FR-WAL-001/002).
///
/// Mengganti saldo saat ini menggeser saldo awal supaya saldo tercatat persis
/// sama dengan angka itu (saldo awal = angka - netto seluruh transaksi dompet);
/// tidak ada transaksi yang dibuat. Menyunting nama/ikon/status TIDAK menyentuh
/// saldo.
final class WalletEdited extends WalletEvent {
  /// Membuat [WalletEdited].
  const WalletEdited({
    required this.original,
    required this.name,
    required this.iconKey,
    required this.isActive,
    this.currentBalance,
  });

  /// Dompet sebelum disunting.
  final Wallet original;

  /// Nama baru.
  final String name;

  /// Kunci ikon baru.
  final String iconKey;

  /// Status aktif baru.
  final bool isActive;

  /// Saldo saat ini yang dikehendaki (sen), atau `null` kalau tidak diubah.
  final int? currentBalance;
}

/// Menyusun ulang dompet mengikuti [orderedIds] (B-34). Urutan ini dipakai
/// semua daftar dan pemilih dompet.
final class WalletsReordered extends WalletEvent {
  /// Membuat [WalletsReordered].
  const WalletsReordered(this.orderedIds);

  /// Id dompet dalam urutan baru.
  final List<String> orderedIds;
}

/// Menghapus [wallet] -- HANYA kalau ia belum punya transaksi sama sekali
/// (FR-WAL-001). Kalau sudah punya, penghapusan ditolak dengan pesan.
final class WalletDeleted extends WalletEvent {
  /// Membuat [WalletDeleted].
  const WalletDeleted(this.wallet);

  /// Dompet yang mau dihapus.
  final Wallet wallet;
}
