import 'package:dependencies/dependencies.dart';

/// Tempat uang pemilik tercatat berada — rekening bank, tunai, dompet
/// digital, atau tabungan. Tidak terhubung ke lembaga keuangan mana pun:
/// `BCA Rp5.000.000` berarti "pemilik menyatakan tercatat ada Rp5.000.000 di
/// sana", bukan saldo yang dibaca dari API bank. Lihat DOMAIN_MODEL.md
/// bagian "Dompet".
final class Wallet extends Equatable {
  /// Membuat [Wallet].
  const Wallet({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.initialBalance,
    required this.currentBalance,
    this.isActive = true,
  });

  /// Identitas dompet.
  final String id;

  /// Nama yang dipilih pemilik, misalnya `"BCA"` atau `"GoPay"`. Data
  /// pengguna, bukan teks antarmuka — tidak pernah lewat slang.
  final String name;

  /// Kunci semantik ikon, bukan path aset. Lihat
  /// [ADR-015](../../../docs/02-architecture/adr/0015-adopsi-bahasa-visual-pixel-kas.md).
  final String iconKey;

  /// Saldo saat dompet dibuat, dalam sen. Boleh nol, boleh negatif.
  ///
  /// Pernyataan keadaan, bukan transaksi setoran — tidak pernah muncul di
  /// riwayat `Transaction`.
  final int initialBalance;

  /// Saldo tercatat saat ini, dalam sen. Satu-satunya nilai turunan yang
  /// **disimpan** di seluruh model domain Saldough — penyimpangan sadar
  /// demi kecepatan Beranda, dengan `recomputeWalletBalances()` sebagai
  /// penyeimbangnya. Lihat
  /// [ADR-012](../../../docs/02-architecture/adr/0012-tata-letak-penyimpanan-buku-besar.md).
  ///
  /// Boleh negatif — itu keadaan nyata, bukan kesalahan.
  final int currentBalance;

  /// Dompet tidak aktif tidak muncul di pemilih dompet, tapi transaksinya
  /// tetap ada dan tetap dihitung.
  final bool isActive;

  /// Salinan [Wallet] dengan field yang disebutkan diganti.
  Wallet copyWith({
    String? name,
    String? iconKey,
    int? initialBalance,
    int? currentBalance,
    bool? isActive,
  }) {
    return Wallet(
      id: id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      initialBalance: initialBalance ?? this.initialBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        iconKey,
        initialBalance,
        currentBalance,
        isActive,
      ];
}
