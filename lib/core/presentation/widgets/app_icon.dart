import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Kunci semantik untuk setiap ikon yang dipakai aplikasi.
///
/// `enum` supaya kunci yang belum dipetakan di [AppIcon] gagal saat
/// kompilasi, bukan saat dijalankan. Berkas ini satu-satunya tempat
/// `Icons.*` boleh muncul — lihat ADR-0009 dan ADR-015.
enum IconKey {
  // Navigasi

  /// Tab Beranda.
  home,

  /// Tab Anggaran.
  budget,

  /// Tombol aksi CATAT.
  record,

  /// Tab Transaksi.
  transactions,

  /// Tab Dompet.
  wallets,

  // Jenis dompet

  /// Dompet jenis rekening bank.
  walletBank,

  /// Dompet jenis uang tunai.
  walletCash,

  /// Dompet jenis e-wallet/QR.
  walletEwallet,

  /// Dompet jenis tabungan.
  walletSavings,

  /// Dompet jenis kartu debit/kredit.
  walletCard,

  // Jenis transaksi

  /// `IncomeTransaction`.
  income,

  /// `ExpenseTransaction`.
  expense,

  /// `TransferTransaction`.
  transfer,

  // Kategori

  /// Kategori makanan.
  categoryFood,

  /// Kategori transportasi.
  categoryTransport,

  /// Kategori rumah tangga.
  categoryHousehold,

  /// Kategori tagihan.
  categoryBills,

  /// Kategori hiburan.
  categoryEntertainment,

  /// Kategori lainnya, di luar kategori bernama lainnya.
  categoryOther,

  // Freelance

  /// Proyek freelance.
  freelance,

  /// Entri worklog.
  worklog,

  // Status dan umpan balik

  /// `PaymentStatus.pending` — pembayaran freelance belum diterima.
  pending,

  /// `PaymentStatus.paid` — pembayaran freelance sudah diterima.
  paid,

  /// Pos anggaran yang lewat rencananya.
  overBudget,

  /// Ilustrasi keadaan kosong (belum ada dompet/transaksi/anggaran).
  empty,

  // Aksi

  /// Menambah entitas baru.
  add,

  /// Menyunting entitas.
  edit,

  /// Menghapus entitas.
  delete,

  /// Memilih tanggal.
  calendar,

  /// Menandai selesai/terpilih.
  check,

  /// Navigasi mundur (mis. bulan sebelumnya).
  chevronLeft,

  /// Navigasi maju (mis. bulan berikutnya).
  chevronRight,

  /// Kolom pencarian.
  search,

  /// Penanda dropdown kecil pada tombol penyaring.
  dropdown,

  /// Penanda data tersimpan lokal/privat.
  locked,
}

/// Aset SVG pixel-art dari `docs/stitch_pixel_finance_tracker/icon_*/`,
/// dikonversi ke `assets/icons/` per ADR-015. Kunci yang tidak terdaftar di
/// sini belum ada padanan asetnya dan jatuh ke [_materialFallback].
const Map<IconKey, String> _assetPaths = {
  IconKey.home: 'assets/icons/home.svg',
  IconKey.budget: 'assets/icons/budget.svg',
  IconKey.record: 'assets/icons/record.svg',
  IconKey.transactions: 'assets/icons/transactions.svg',
  IconKey.wallets: 'assets/icons/wallets.svg',
  IconKey.walletBank: 'assets/icons/wallet_bank.svg',
  IconKey.walletCash: 'assets/icons/wallet_cash.svg',
  IconKey.walletEwallet: 'assets/icons/wallet_ewallet.svg',
  IconKey.walletSavings: 'assets/icons/wallet_savings.svg',
  IconKey.walletCard: 'assets/icons/wallet_card.svg',
  IconKey.income: 'assets/icons/income.svg',
  IconKey.expense: 'assets/icons/expense.svg',
  IconKey.transfer: 'assets/icons/transfer.svg',
  IconKey.categoryTransport: 'assets/icons/category_transport.svg',
  IconKey.categoryEntertainment: 'assets/icons/category_entertainment.svg',
  // Sementara memakai ikon "restoran" sampai daftar kategori final
  // diputuskan pemilik — lihat catatan kategori di ADR-015.
  IconKey.categoryFood: 'assets/icons/category_food.svg',
  IconKey.freelance: 'assets/icons/freelance.svg',
  IconKey.worklog: 'assets/icons/worklog.svg',
  IconKey.pending: 'assets/icons/pending.svg',
  IconKey.paid: 'assets/icons/paid.svg',
  IconKey.overBudget: 'assets/icons/over_budget.svg',
  IconKey.check: 'assets/icons/check.svg',
  IconKey.calendar: 'assets/icons/calendar.svg',
};

/// Isian Material sementara untuk kunci yang belum ada padanan asetnya di
/// paket desain pemilik (ADR-015 §7 "Aset cadangan"), atau yang aset
/// sumbernya bukan SVG siap pakai (`empty`, ilustrasi sprite besar yang
/// belum dipotong — lihat ADR-015 §"empty bukan ikon kecil").
const Map<IconKey, IconData> _materialFallback = {
  IconKey.categoryHousehold: Icons.house_outlined,
  IconKey.categoryBills: Icons.receipt_long_outlined,
  IconKey.categoryOther: Icons.more_horiz,
  IconKey.empty: Icons.inbox_outlined,
  IconKey.add: Icons.add,
  IconKey.edit: Icons.edit_outlined,
  IconKey.delete: Icons.delete_outline,
  IconKey.chevronLeft: Icons.chevron_left,
  IconKey.chevronRight: Icons.chevron_right,
  IconKey.search: Icons.search,
  IconKey.dropdown: Icons.arrow_drop_down,
  IconKey.locked: Icons.lock_outline,
};

/// Lapisan pemisah antara halaman dan aset ikon (ADR-013, dipertahankan
/// ADR-015). Halaman merujuk [IconKey], tidak pernah nama berkas aset atau
/// `Icons.*` secara langsung — penggantian set ikon jadi satu berkas ini.
///
/// Ikon pixel-art dari [_assetPaths] dirender apa adanya (warnanya sudah
/// dipatok di dalam SVG, bukan monokrom untuk ditintai). [color] hanya
/// berlaku untuk kunci yang masih memakai isian [_materialFallback].
class AppIcon extends StatelessWidget {
  /// Membuat [AppIcon] untuk [iconKey], dirender pada [size] logical pixel.
  const AppIcon(this.iconKey, {this.size = 24, this.color, super.key});

  /// Kunci semantik ikon yang dirender.
  final IconKey iconKey;

  /// Sisi persegi ikon dalam logical pixel. Bawaan 24, mengikuti ukuran
  /// ikon Material standar.
  final double size;

  /// Warna isian. Hanya berlaku untuk isian [_materialFallback] Material;
  /// SVG pixel-art membawa warnanya sendiri.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final assetPath = _assetPaths[iconKey];
    if (assetPath != null) {
      return SvgPicture.asset(assetPath, width: size, height: size);
    }

    final fallback = _materialFallback[iconKey];
    assert(fallback != null, 'IconKey.$iconKey belum dipetakan di AppIcon.');
    return Icon(fallback, size: size, color: color);
  }
}
