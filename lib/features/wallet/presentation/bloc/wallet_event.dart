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
/// [initialBalance] tidak `null` -- saldo awal (FR-WAL-001/002).
///
/// Mengganti saldo awal menghitung ulang saldo tercatat dari seluruh
/// transaksi dompet itu; menyunting nama/ikon/status TIDAK menyentuh saldo.
final class WalletEdited extends WalletEvent {
  /// Membuat [WalletEdited].
  const WalletEdited({
    required this.original,
    required this.name,
    required this.iconKey,
    required this.isActive,
    this.initialBalance,
  });

  /// Dompet sebelum disunting.
  final Wallet original;

  /// Nama baru.
  final String name;

  /// Kunci ikon baru.
  final String iconKey;

  /// Status aktif baru.
  final bool isActive;

  /// Saldo awal baru (sen), atau `null` kalau tidak diubah.
  final int? initialBalance;
}

/// Menghapus [wallet] -- HANYA kalau ia belum punya transaksi sama sekali
/// (FR-WAL-001). Kalau sudah punya, penghapusan ditolak dengan pesan.
final class WalletDeleted extends WalletEvent {
  /// Membuat [WalletDeleted].
  const WalletDeleted(this.wallet);

  /// Dompet yang mau dihapus.
  final Wallet wallet;
}
