import 'package:saldough/core/presentation/widgets/app_icon.dart';

/// Ikon "clay" (ilustrasi SVG berwarna, `assets/icons_clay/`, ADR-043 dan
/// `docs/03-design/design-system-v2/icons.md`).
///
/// KT-DS5: ikon clay menggantikan ikon piksel di seluruh aplikasi. Seluruh
/// kategori, dompet, jenis transaksi, dan status Freelance sudah digambar
/// (52 aset). [forIcon] mengembalikan aset clay bila ada; `null` (mis. ikon
/// tindakan atau `balanceSpread`) berarti pemanggil memakai ikon yang ada.
abstract final class ClayIcons {
  ClayIcons._();

  /// Maskot tanuki.
  static const String mascot = 'assets/icons_clay/tanuki_mascot.svg';

  /// Maskot tanuki tidur (keadaan awal Beranda).
  static const String mascotSleeping = 'assets/icons_clay/tanuki_sleeping.svg';

  /// Koin lencana level.
  static const String tierCoin = 'assets/icons_clay/tier_coin.svg';

  /// Kamera "Scan Struk".
  static const String scan = 'assets/icons_clay/scan_camera.svg';

  /// Daun "Catat Transfer".
  static const String transfer = 'assets/icons_clay/leaf_send.svg';

  /// Batang "Laporan".
  static const String report = 'assets/icons_clay/report_bars.svg';

  /// Piala "Misi Hemat".
  static const String trophy = 'assets/icons_clay/trophy_mission.svg';

  /// Cangkir kopi.
  static const String coffee = 'assets/icons_clay/cup_coffee.svg';

  /// Kereta.
  static const String train = 'assets/icons_clay/train_transport.svg';

  /// Stilus, pekerjaan lepas.
  static const String stylus = 'assets/icons_clay/stylus_freelance.svg';

  /// Headphone, langganan dan hiburan.
  static const String headphones = 'assets/icons_clay/headphones_subscription.svg';

  /// Gedung bank, dompet bank.
  static const String bank = 'assets/icons_clay/bank_wallet.svg';

  /// Uang kertas, dompet tunai.
  static const String cash = 'assets/icons_clay/cash_wallet.svg';

  /// Ponsel, dompet digital.
  static const String ewallet = 'assets/icons_clay/ewallet_wallet.svg';

  /// Celengan, dompet tabungan.
  static const String piggy = 'assets/icons_clay/piggy_savings.svg';

  /// Kartu, dompet kartu.
  static const String card = 'assets/icons_clay/card_wallet.svg';

  /// Panah masuk, pemasukan.
  static const String incomeArrow = 'assets/icons_clay/income_arrow.svg';

  /// Panah keluar, pengeluaran.
  static const String expenseArrow = 'assets/icons_clay/expense_arrow.svg';

  /// Mangkuk, makanan.
  static const String bowl = 'assets/icons_clay/bowl_food.svg';

  /// Rumah, rumah tangga.
  static const String house = 'assets/icons_clay/house_household.svg';

  /// Struk, tagihan.
  static const String receipt = 'assets/icons_clay/receipt_bills.svg';

  /// Tiga titik, lainnya.
  static const String tray = 'assets/icons_clay/tray_other.svg';

  /// Toga, pendidikan.
  static const String cap = 'assets/icons_clay/cap_education.svg';

  /// Petir, listrik.
  static const String bolt = 'assets/icons_clay/bolt_electricity.svg';

  /// Perisai, dana darurat.
  static const String shield = 'assets/icons_clay/shield_emergency.svg';

  /// Pompa, bahan bakar.
  static const String pump = 'assets/icons_clay/pump_fuel.svg';

  /// Keranjang, belanja bulanan.
  static const String basket = 'assets/icons_clay/basket_groceries.svg';

  /// Hati berpalang, kesehatan.
  static const String heart = 'assets/icons_clay/heart_health.svg';

  /// Wi-Fi, internet.
  static const String wifi = 'assets/icons_clay/wifi_internet.svg';

  /// Grafik naik, investasi.
  static const String chart = 'assets/icons_clay/chart_investment.svg';

  /// Jejak kaki, hewan peliharaan.
  static const String paw = 'assets/icons_clay/paw_pets.svg';

  /// Kantong belanja, belanja.
  static const String bag = 'assets/icons_clay/bag_shopping.svg';

  /// Dua orang, keluarga.
  static const String family = 'assets/icons_clay/family_people.svg';

  /// Hati di tangan, donasi.
  static const String donation = 'assets/icons_clay/heart_donation.svg';

  /// Bintang, bonus.
  static const String star = 'assets/icons_clay/star_bonus.svg';

  /// Kotak kado, hadiah.
  static const String gift = 'assets/icons_clay/gift_box.svg';

  /// Papan catatan, log kerja.
  static const String clipboard = 'assets/icons_clay/clipboard_worklog.svg';

  /// Jam dan koin, tarif per jam.
  static const String clock = 'assets/icons_clay/clock_hourly.svg';

  /// Dokumen tagihan, invoice.
  static const String invoice = 'assets/icons_clay/doc_invoice.svg';

  /// Centang hijau, kerja selesai.
  static const String done = 'assets/icons_clay/check_completed.svg';

  /// Jam pasir, menunggu.
  static const String hourglass = 'assets/icons_clay/hourglass_pending.svg';

  /// Koin berpusar centang, sudah dibayar.
  static const String paid = 'assets/icons_clay/coin_paid.svg';

  /// Segitiga peringatan, lewat anggaran.
  static const String warning = 'assets/icons_clay/warning_overbudget.svg';

  /// Kotak kosong, keadaan kosong.
  static const String emptyTray = 'assets/icons_clay/tray_empty.svg';

  /// Lonceng, notifikasi.
  static const String bell = 'assets/icons_clay/bell_notification.svg';

  /// Jam weker, pengingat.
  static const String alarm = 'assets/icons_clay/alarm_reminder.svg';

  /// Kalender berputar, transaksi rutin.
  static const String calendar = 'assets/icons_clay/calendar_recurring.svg';

  /// Roket, pembaruan aplikasi.
  static const String rocket = 'assets/icons_clay/rocket_update.svg';

  /// Dompet, tab navigasi bawah.
  static const String walletNav = 'assets/icons_clay/wallet_nav.svg';

  /// Kalender bertanggal, kolom tanggal.
  static const String dateCalendar = 'assets/icons_clay/calendar_date.svg';

  /// Buku catatan berpensil, kolom catatan.
  static const String note = 'assets/icons_clay/note_pencil.svg';

  /// Panah berputar, Ulangi.
  static const String repeat = 'assets/icons_clay/repeat_loop.svg';

  /// Bola dunia, bahasa.
  static const String globe = 'assets/icons_clay/globe_language.svg';

  /// Palet cat, tema.
  static const String palette = 'assets/icons_clay/palette_theme.svg';

  /// Tumpukan koin, mata uang.
  static const String coins = 'assets/icons_clay/coins_currency.svg';

  /// Mata, sembunyikan nominal.
  static const String eye = 'assets/icons_clay/eye_privacy.svg';

  /// Label harga, kategori.
  static const String tag = 'assets/icons_clay/tag_category.svg';

  /// Lembar tabel berpanah, ekspor.
  static const String sheet = 'assets/icons_clay/sheet_export.svg';

  /// Awan berpanah, cadangan.
  static const String backupBox = 'assets/icons_clay/box_backup.svg';

  /// Jam berputar balik, pulihkan.
  static const String restoreClock = 'assets/icons_clay/restore_clock.svg';

  /// Gelembung obrolan, tanya Tanuki.
  static const String chat = 'assets/icons_clay/chat_bubble.svg';

  /// Seluruh aset, untuk uji dan pemeriksaan manifest.
  static const List<String> all = [
    mascot,
    mascotSleeping,
    tierCoin,
    scan,
    transfer,
    report,
    trophy,
    coffee,
    train,
    stylus,
    headphones,
    bank,
    cash,
    ewallet,
    piggy,
    card,
    incomeArrow,
    expenseArrow,
    bowl,
    house,
    receipt,
    tray,
    cap,
    bolt,
    shield,
    pump,
    basket,
    heart,
    wifi,
    chart,
    paw,
    bag,
    family,
    donation,
    star,
    gift,
    clipboard,
    clock,
    invoice,
    done,
    hourglass,
    paid,
    warning,
    emptyTray,
    bell,
    alarm,
    calendar,
    rocket,
    walletNav,
    dateCalendar,
    note,
    repeat,
    globe,
    palette,
    coins,
    eye,
    tag,
    sheet,
    backupBox,
    restoreClock,
    chat,
  ];

  /// Aset clay untuk [key], atau `null` bila belum digambar.
  static String? forIcon(IconKey key) => switch (key) {
    IconKey.categoryCoffee => coffee,
    IconKey.categoryTransport => train,
    IconKey.freelance => stylus,
    IconKey.categoryEntertainment => headphones,
    IconKey.transfer => transfer,
    IconKey.walletBank => bank,
    IconKey.walletCash => cash,
    IconKey.walletEwallet => ewallet,
    IconKey.walletSavings => piggy,
    IconKey.walletCard => card,
    IconKey.income => incomeArrow,
    IconKey.expense => expenseArrow,
    IconKey.categoryFood => bowl,
    IconKey.categoryHousehold => house,
    IconKey.categoryBills => receipt,
    IconKey.categoryOther => tray,
    IconKey.categoryEducation => cap,
    IconKey.categoryElectricity => bolt,
    IconKey.categoryEmergencyFund => shield,
    IconKey.categoryFuel => pump,
    IconKey.categoryGroceries => basket,
    IconKey.categoryHealth => heart,
    IconKey.categoryInternet => wifi,
    IconKey.categoryInvestment => chart,
    IconKey.categoryPets => paw,
    IconKey.categoryShopping => bag,
    IconKey.categoryFamily => family,
    IconKey.categoryDonation => donation,
    IconKey.categoryBonus => star,
    IconKey.categoryGift => gift,
    IconKey.worklog => clipboard,
    IconKey.hourlyRate => clock,
    IconKey.invoice => invoice,
    IconKey.workCompleted => done,
    IconKey.pending => hourglass,
    IconKey.paid => paid,
    IconKey.overBudget => warning,
    IconKey.empty => emptyTray,
    IconKey.translate => globe,
    IconKey.palette || IconKey.contrast => palette,
    IconKey.payments => coins,
    IconKey.visibilityOff => eye,
    IconKey.label => tag,
    IconKey.tableView => sheet,
    IconKey.backup => backupBox,
    IconKey.restoreBackup || IconKey.undo || IconKey.restorePurchases => restoreClock,
    IconKey.openInNew => bag,
    IconKey.notifications => bell,
    IconKey.schedule => alarm,
    IconKey.calendar => calendar,
    IconKey.systemUpdate => rocket,
    IconKey.plus => tierCoin,
    IconKey.photoCamera => scan,
    IconKey.notificationsActive => bell,
    IconKey.chatBubble => chat,
    IconKey.trendingUp => chart,
    IconKey.summarize => report,
    IconKey.checkCircle => done,
    IconKey.error => warning,
    _ => null,
  };
}
