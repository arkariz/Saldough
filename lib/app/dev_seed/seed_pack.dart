import 'package:di/di.dart';

/// Hasil menerapkan satu [SeedPack].
final class SeedResult {
  /// Membuat [SeedResult].
  const SeedResult({required this.added, required this.skipped});

  /// Jumlah data yang baru dibuat.
  final int added;

  /// Jumlah data yang sudah ada dan dibiarkan apa adanya.
  final int skipped;

  @override
  String toString() => '$added ditambah, $skipped sudah ada';
}

/// Satu paket data uji yang bisa diterapkan dari menu pengembang.
///
/// Aturan semua paket supaya data seed bisa ditumpuk tanpa merusak apa pun:
/// 1. **Id tetap** berawalan `seed_`, jadi menerapkan ulang tidak menggandakan.
/// 2. **Tambah-bila-belum-ada**: data dengan id yang sama tidak pernah
///    ditimpa, jadi saldo yang sudah bergeser karena transaksi tetap aman.
/// 3. **Tidak pernah menghapus** atau menyentuh data milik pengguna.
/// 4. Paket yang bergantung pada paket lain (transaksi butuh dompet) memakai
///    id dari [SeedIds], bukan mencari dompet lewat nama.
abstract interface class SeedPack {
  /// Kunci unik paket.
  String get id;

  /// Nama yang tampil di menu.
  String get label;

  /// Satu kalimat isi paket.
  String get description;

  /// Menerapkan paket memakai [container] akar.
  Future<SeedResult> apply(GetIt container);
}

/// Id tetap data seed, dipakai bersama antarpaket.
abstract final class SeedIds {
  SeedIds._();

  /// Dompet Utama.
  static const walletUtama = 'seed_wallet_utama';

  /// Dompet jatah mingguan.
  static const walletMingguan = 'seed_wallet_mingguan';

  /// Dompet jatah bulanan.
  static const walletBulanan = 'seed_wallet_bulanan';

  /// Tabungan rumah.
  static const walletTabunganRumah = 'seed_wallet_tabungan_rumah';

  /// Dana ke Jepang.
  static const walletKeJepang = 'seed_wallet_ke_jepang';

  /// Dana anak.
  static const walletAnak = 'seed_wallet_anak';

  /// Saham.
  static const walletSaham = 'seed_wallet_saham';
}
