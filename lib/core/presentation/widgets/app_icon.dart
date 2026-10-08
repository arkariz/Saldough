import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:saldough/core/theme/theme.dart';

/// Kunci semantik untuk setiap ikon yang dipakai aplikasi.
///
/// `enum` supaya kunci yang belum dipetakan di [AppIcon] gagal saat
/// kompilasi, bukan saat dijalankan. Berkas ini satu-satunya tempat
/// `Symbols.*`/`Icons.*` boleh muncul (ADR-0009, ADR-034).
///
/// Dua set dengan pembagian tegas (design system bagian Ikon): ikon piksel
/// Tanukonomy untuk *benda* (kategori, dompet, jenis transaksi, freelance,
/// status pembayaran) dan Material Symbols Rounded untuk *tindakan dan
/// navigasi*.
enum IconKey {
  // Navigasi

  /// Tab Beranda.
  home,

  /// Tab Rencana (anggaran dan rutin).
  budget,

  /// Tombol aksi CATAT.
  record,

  /// Tab Riwayat.
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

  /// Kategori kopi/minuman.
  categoryCoffee,

  /// Kategori pendidikan.
  categoryEducation,

  /// Kategori listrik.
  categoryElectricity,

  /// Kategori dana darurat.
  categoryEmergencyFund,

  /// Kategori bahan bakar.
  categoryFuel,

  /// Kategori belanja bahan makanan.
  categoryGroceries,

  /// Kategori kesehatan.
  categoryHealth,

  /// Kategori internet.
  categoryInternet,

  /// Kategori investasi.
  categoryInvestment,

  /// Kategori hewan peliharaan.
  categoryPets,

  /// Kategori belanja/berbelanja.
  categoryShopping,

  /// Kategori keluarga (belum ada ikon piksel, B-22).
  categoryFamily,

  /// Kategori donasi (belum ada ikon piksel, B-22).
  categoryDonation,

  /// Kategori bonus (belum ada ikon piksel, B-22).
  categoryBonus,

  /// Kategori hadiah (belum ada ikon piksel, B-22).
  categoryGift,

  // Freelance

  /// Proyek freelance.
  freelance,

  /// Entri worklog.
  worklog,

  /// Tarif per jam proyek freelance.
  hourlyRate,

  /// Tagihan/pembayaran freelance yang dikelompokkan dari worklog.
  invoice,

  /// Kerja selesai (jam yang sudah dikerjakan).
  workCompleted,

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

  /// Tombol penyaring (corong).
  filter,

  /// Penanda dropdown kecil pada tombol penyaring.
  dropdown,

  /// Penanda data tersimpan lokal/privat.
  locked,

  /// Menutup lembar atau layar.
  close,

  /// Info dan tur layar (ADR-021 §3.5).
  info,

  /// Akun opsional (ADR-023): masuk, keluar, hapus akun.
  account,

  /// Catat Cerdas suara (ADR-027): rekam ucapan di CATAT.
  microphone,

  /// Berhenti merekam (lembar suara, ADR-027).
  stop,

  /// Tombol menu pengembang (hanya build debug, ADR-0004).
  debugMenu,

  /// Muat ulang/segarkan.
  refresh,

  /// Buka/tutup bagian yang bisa dilipat.
  expandMore,

  /// Tutup bagian yang terbuka.
  expandLess,

  /// Menu tindakan lainnya.
  moreVert,

  /// Kembali ke layar sebelumnya.
  back,

  /// Hapus satu digit di papan angka.
  backspace,
}

/// Ikon piksel Tanukonomy (`assets/icons/`, SVG 32×32) untuk benda.
/// Ditampilkan 32px atau 64px saja (design system bagian Ikon); di tile
/// lewat `AppIconTile`.
const Map<IconKey, String> _pixelAssets = {
  IconKey.walletBank: 'assets/icons/wallet_bank.svg',
  IconKey.walletCash: 'assets/icons/wallet_cash.svg',
  IconKey.walletEwallet: 'assets/icons/wallet_ewallet.svg',
  IconKey.walletSavings: 'assets/icons/wallet_savings.svg',
  IconKey.walletCard: 'assets/icons/wallet_card.svg',
  IconKey.income: 'assets/icons/income.svg',
  IconKey.expense: 'assets/icons/expense.svg',
  IconKey.transfer: 'assets/icons/transfer.svg',
  IconKey.categoryFood: 'assets/icons/category_food.svg',
  IconKey.categoryCoffee: 'assets/icons/category_coffee.svg',
  IconKey.categoryGroceries: 'assets/icons/category_groceries.svg',
  IconKey.categoryTransport: 'assets/icons/category_transport.svg',
  IconKey.categoryFuel: 'assets/icons/category_fuel.svg',
  IconKey.categoryElectricity: 'assets/icons/category_electricity.svg',
  // Tagihan memakai ikon listrik (design system bagian Ikon).
  IconKey.categoryBills: 'assets/icons/category_electricity.svg',
  IconKey.categoryInternet: 'assets/icons/category_internet.svg',
  IconKey.categoryHealth: 'assets/icons/category_health.svg',
  IconKey.categoryEntertainment: 'assets/icons/category_entertainment.svg',
  IconKey.categoryShopping: 'assets/icons/category_shopping.svg',
  IconKey.categoryEducation: 'assets/icons/category_education.svg',
  IconKey.categoryEmergencyFund: 'assets/icons/category_emergency_fund.svg',
  IconKey.categoryInvestment: 'assets/icons/category_investment.svg',
  IconKey.categoryPets: 'assets/icons/category_pets.svg',
  // Kunci lama kategori rumah tangga: keranjang belanja harian.
  IconKey.categoryHousehold: 'assets/icons/category_groceries.svg',
  IconKey.freelance: 'assets/icons/freelance.svg',
  IconKey.worklog: 'assets/icons/worklog.svg',
  IconKey.hourlyRate: 'assets/icons/hourly_rate.svg',
  IconKey.invoice: 'assets/icons/invoice.svg',
  IconKey.workCompleted: 'assets/icons/work_completed.svg',
  IconKey.pending: 'assets/icons/pending.svg',
  IconKey.paid: 'assets/icons/paid.svg',
  IconKey.overBudget: 'assets/icons/over_budget.svg',
  IconKey.empty: 'assets/icons/empty.svg',
};

/// Material Symbols Rounded (bobot 400) untuk tindakan, navigasi, dan
/// kategori yang belum punya ikon piksel (B-22). Nama simbol mengikuti
/// prototipe.
const Map<IconKey, IconData> _symbols = {
  IconKey.home: Symbols.home_rounded,
  IconKey.budget: Symbols.donut_small_rounded,
  IconKey.record: Symbols.add_rounded,
  IconKey.transactions: Symbols.receipt_long_rounded,
  IconKey.wallets: Symbols.account_balance_wallet_rounded,
  IconKey.categoryOther: Symbols.more_horiz_rounded,
  IconKey.categoryFamily: Symbols.family_restroom_rounded,
  IconKey.categoryDonation: Symbols.volunteer_activism_rounded,
  IconKey.categoryBonus: Symbols.stars_rounded,
  IconKey.categoryGift: Symbols.redeem_rounded,
  IconKey.add: Symbols.add_rounded,
  IconKey.edit: Symbols.edit_rounded,
  IconKey.delete: Symbols.delete_rounded,
  IconKey.calendar: Symbols.calendar_today_rounded,
  IconKey.check: Symbols.check_rounded,
  IconKey.chevronLeft: Symbols.chevron_left_rounded,
  IconKey.chevronRight: Symbols.chevron_right_rounded,
  IconKey.search: Symbols.search_rounded,
  IconKey.filter: Symbols.tune_rounded,
  IconKey.dropdown: Symbols.expand_more_rounded,
  IconKey.locked: Symbols.lock_rounded,
  IconKey.close: Symbols.close_rounded,
  IconKey.info: Symbols.info_rounded,
  IconKey.account: Symbols.account_circle_rounded,
  IconKey.microphone: Symbols.mic_rounded,
  IconKey.stop: Symbols.stop_rounded,
  IconKey.debugMenu: Symbols.bug_report_rounded,
  IconKey.refresh: Symbols.refresh_rounded,
  IconKey.expandMore: Symbols.expand_more_rounded,
  IconKey.expandLess: Symbols.expand_less_rounded,
  IconKey.moreVert: Symbols.more_vert_rounded,
  IconKey.back: Symbols.arrow_back_rounded,
  IconKey.backspace: Symbols.backspace_rounded,
};

/// Apakah [key] digambar sebagai ikon piksel (bukan Material Symbols).
bool isPixelIcon(IconKey key) => _pixelAssets.containsKey(key);

/// Lapisan pemisah antara halaman dan aset ikon (ADR-013, dipertahankan
/// ADR-034). Halaman merujuk [IconKey], tidak pernah nama berkas aset,
/// `Symbols.*`, atau `Icons.*` secara langsung.
///
/// Ikon piksel dirender apa adanya (warnanya dipatok di SVG); [color] dan
/// [fill] hanya berlaku untuk Material Symbols. Untuk kategori dan dompet di
/// baris, pakai `AppIconTile`.
class AppIcon extends StatelessWidget {
  /// Membuat [AppIcon] untuk [iconKey], dirender pada [size] logical pixel.
  const AppIcon(this.iconKey, {this.size = AppSize.icon, this.color, this.fill = false, super.key});

  /// Kunci semantik ikon yang dirender.
  final IconKey iconKey;

  /// Sisi persegi ikon dalam logical pixel. Bawaan `size-icon` (24).
  final double size;

  /// Warna Material Symbols; ikon piksel membawa warnanya sendiri.
  final Color? color;

  /// Varian berisi Material Symbols (tab aktif).
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final assetPath = _pixelAssets[iconKey];
    if (assetPath != null) {
      return SvgPicture.asset(assetPath, width: size, height: size);
    }

    final symbol = _symbols[iconKey];
    assert(symbol != null, 'IconKey.$iconKey belum dipetakan di AppIcon.');
    return Icon(symbol, size: size, color: color, fill: fill ? 1 : 0, weight: 400, opticalSize: size.clamp(20, 48));
  }
}

/// Ikon pixel-art untuk dompet ber-`Wallet.iconKey` [key]. `Wallet.iconKey`
/// menyimpan nama [IconKey] (`walletBank`, `walletCash`, `walletEwallet`,
/// `walletSavings`, `walletCard`); nilai lain -- termasuk yang tidak dikenal
/// -- jatuh ke [IconKey.wallets] alih-alih melempar, karena kunci ini data
/// tersimpan yang bisa berasal dari versi aplikasi lain.
IconKey walletIconKey(String key) {
  const walletKeys = {
    IconKey.walletBank,
    IconKey.walletCash,
    IconKey.walletEwallet,
    IconKey.walletSavings,
    IconKey.walletCard,
  };
  for (final candidate in walletKeys) {
    if (candidate.name == key) return candidate;
  }
  return IconKey.wallets;
}
