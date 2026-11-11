import 'package:dependencies/dependencies.dart' show Unit;
import 'package:di/di.dart';
import 'package:saldough/app/dev_seed/seed_pack.dart';
import 'package:saldough/app/dev_seed/wallet_seed_pack.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Id tetap kategori buatan paket pengeluaran.
abstract final class SpendingSeedIds {
  SpendingSeedIds._();

  /// Tagihan Kos.
  static const catKos = 'seed_cat_kos';

  /// Tagihan Listrik.
  static const catListrik = 'seed_cat_listrik';

  /// Belanja Bulanan.
  static const catBelanja = 'seed_cat_belanja_bulanan';

  /// Jajan.
  static const catJajan = 'seed_cat_jajan';

  /// Rutin nabung ke Tabungan Rumah.
  static const ruleRumah = 'seed_rule_nabung_rumah';

  /// Rutin nabung ke dana Anak.
  static const ruleAnak = 'seed_rule_nabung_anak';

  /// Rutin nabung ke dana Ke Jepang.
  static const ruleJepang = 'seed_rule_nabung_jepang';

  /// Rutin nabung ke Saham.
  static const ruleSaham = 'seed_rule_nabung_saham';
}

/// Satu pengeluaran seed: tanggal (hari), nominal (rupiah), catatan, id kategori.
typedef SeedSpend = ({int day, int rupiah, String note, String category});

/// Cerita "istri resign tapi tetap cukup": tiga bulan pengeluaran rumah tangga
/// Rp5–7 juta per bulan dan rutin nabung Rp7 juta dipecah ke empat dompet.
///
/// - **Tiga bulan** = dua bulan kalender lalu + bulan berjalan (sampai hari
///   ini; transaksi bertanggal di depan tidak dibuat).
/// - **Pengeluaran** (analisis): Tagihan Kos, Tagihan Listrik, Belanja
///   Bulanan, Jajan, plus selingan (internet, bensin, apotek, hiburan,
///   keluarga, belanja). Semuanya dari dompet Utama.
/// - **Nabung bukan pengeluaran**: empat transfer Utama -> Tabungan Rumah,
///   Anak, Ke Jepang, Saham tiap tanggal 2, tertaut ke empat rutin bulanan,
///   jadi tidak masuk analisis pengeluaran. Rutin berlanjut ke bulan depan.
/// - **Gaji suami** tiap tanggal 1 supaya saldo Utama masuk akal; bukan
///   bagian dari permintaan analisis pengeluaran, ubah [salaryRupiah] bila
///   perlu.
///
/// Bergantung pada [WalletSeedPack] (diterapkan otomatis bila perlu). Id
/// tetap berawalan `seed_`, hanya menambah yang belum ada.
final class SpendingSeedPack implements SeedPack {
  /// Membuat [SpendingSeedPack].
  const SpendingSeedPack();

  /// Gaji suami per bulan (rupiah), masuk ke dompet Utama tanggal 1.
  static const salaryRupiah = 13750000;

  /// Setoran nabung bulanan (rupiah): total Rp7.000.000.
  static const savings = <({String ruleId, String toWalletId, String name, int rupiah})>[
    (ruleId: SpendingSeedIds.ruleRumah, toWalletId: SeedIds.walletTabunganRumah, name: 'Tabungan Rumah', rupiah: 3000000),
    (ruleId: SpendingSeedIds.ruleAnak, toWalletId: SeedIds.walletAnak, name: 'Anak', rupiah: 1500000),
    (ruleId: SpendingSeedIds.ruleJepang, toWalletId: SeedIds.walletKeJepang, name: 'Ke Jepang', rupiah: 1000000),
    (ruleId: SpendingSeedIds.ruleSaham, toWalletId: SeedIds.walletSaham, name: 'Saham', rupiah: 1500000),
  ];

  /// Tanggal setoran nabung tiap bulan.
  static const savingsDay = 2;

  static int _sen(int rupiah) => rupiah * 100;

  static const String _kos = SpendingSeedIds.catKos;
  static const String _listrik = SpendingSeedIds.catListrik;
  static const String _belanja = SpendingSeedIds.catBelanja;
  static const String _jajan = SpendingSeedIds.catJajan;

  /// Pengeluaran per bulan, indeks 0 = paling lama. Bulan kedua dan ketiga
  /// sengaja berbeda angka dan selingannya supaya tampak seperti kehidupan
  /// nyata.
  static const List<List<SeedSpend>> months = [
    [
      (day: 1, rupiah: 2350000, note: 'Bayar kos bulanan', category: _kos),
      (day: 5, rupiah: 412350, note: 'Token listrik', category: _listrik),
      (day: 3, rupiah: 1584200, note: 'Belanja bulanan Superindo', category: _belanja),
      (day: 17, rupiah: 276400, note: 'Belanja bulanan susulan: popok dan susu', category: _belanja),
      (day: 8, rupiah: 385000, note: 'Wifi Indihome', category: 'builtin.internet'),
      (day: 11, rupiah: 128000, note: 'Bensin', category: 'builtin.transport'),
      (day: 14, rupiah: 93700, note: 'Apotek: vitamin anak', category: 'builtin.health'),
      (day: 20, rupiah: 65000, note: 'Nonton bareng', category: 'builtin.entertainment'),
      (day: 22, rupiah: 200000, note: 'Arisan keluarga', category: 'builtin.family'),
      (day: 2, rupiah: 23500, note: 'Kopi pagi', category: _jajan),
      (day: 4, rupiah: 48000, note: 'Bakso depan komplek', category: _jajan),
      (day: 6, rupiah: 17500, note: 'Es teh dan gorengan', category: _jajan),
      (day: 9, rupiah: 86000, note: 'Martabak manis', category: _jajan),
      (day: 12, rupiah: 32500, note: 'Jajan anak: es krim', category: _jajan),
      (day: 15, rupiah: 64000, note: 'Ayam geprek', category: _jajan),
      (day: 18, rupiah: 27500, note: 'Kopi susu', category: _jajan),
      (day: 21, rupiah: 92500, note: 'Sate taichan', category: _jajan),
      (day: 24, rupiah: 41000, note: 'Roti bakar', category: _jajan),
      (day: 26, rupiah: 56500, note: 'Boba', category: _jajan),
      (day: 28, rupiah: 53500, note: 'Seblak', category: _jajan),
    ],
    [
      (day: 1, rupiah: 2350000, note: 'Bayar kos bulanan', category: _kos),
      (day: 6, rupiah: 438900, note: 'Token listrik', category: _listrik),
      (day: 2, rupiah: 1647350, note: 'Belanja bulanan Superindo', category: _belanja),
      (day: 19, rupiah: 312800, note: 'Belanja bulanan susulan: sayur dan buah', category: _belanja),
      (day: 8, rupiah: 385000, note: 'Wifi Indihome', category: 'builtin.internet'),
      (day: 12, rupiah: 142500, note: 'Bensin', category: 'builtin.transport'),
      (day: 15, rupiah: 265000, note: 'Dokter anak', category: 'builtin.health'),
      (day: 18, rupiah: 54000, note: 'Langganan streaming', category: 'builtin.entertainment'),
      (day: 23, rupiah: 189000, note: 'Baju anak', category: 'builtin.shopping'),
      (day: 3, rupiah: 35000, note: 'Kopi pagi', category: _jajan),
      (day: 5, rupiah: 72500, note: 'Mie ayam', category: _jajan),
      (day: 7, rupiah: 18500, note: 'Gorengan', category: _jajan),
      (day: 10, rupiah: 94000, note: 'Pizza kecil buat anak', category: _jajan),
      (day: 13, rupiah: 29000, note: 'Es kopi', category: _jajan),
      (day: 16, rupiah: 68500, note: 'Nasi goreng', category: _jajan),
      (day: 19, rupiah: 45500, note: 'Donat', category: _jajan),
      (day: 22, rupiah: 81000, note: 'Dimsum', category: _jajan),
      (day: 25, rupiah: 38000, note: 'Kopi susu', category: _jajan),
      (day: 27, rupiah: 59500, note: 'Bakmi', category: _jajan),
      (day: 28, rupiah: 27500, note: 'Cilok', category: _jajan),
    ],
    [
      (day: 1, rupiah: 2350000, note: 'Bayar kos bulanan', category: _kos),
      (day: 5, rupiah: 385700, note: 'Token listrik', category: _listrik),
      (day: 3, rupiah: 1598600, note: 'Belanja bulanan Superindo', category: _belanja),
      (day: 8, rupiah: 385000, note: 'Wifi Indihome', category: 'builtin.internet'),
      (day: 9, rupiah: 119000, note: 'Bensin', category: 'builtin.transport'),
      (day: 15, rupiah: 275000, note: 'Dokter anak', category: 'builtin.health'),
      (day: 18, rupiah: 54000, note: 'Langganan streaming', category: 'builtin.entertainment'),
      (day: 21, rupiah: 200000, note: 'Arisan keluarga', category: 'builtin.family'),
      (day: 24, rupiah: 214500, note: 'Baju anak', category: 'builtin.shopping'),
      (day: 2, rupiah: 26000, note: 'Kopi pagi', category: _jajan),
      (day: 4, rupiah: 54500, note: 'Soto ayam', category: _jajan),
      (day: 6, rupiah: 19000, note: 'Es teh dan gorengan', category: _jajan),
      (day: 9, rupiah: 78000, note: 'Martabak telur', category: _jajan),
      (day: 10, rupiah: 33500, note: 'Jajan anak: es krim', category: _jajan),
      (day: 14, rupiah: 61000, note: 'Nasi padang', category: _jajan),
      (day: 17, rupiah: 24500, note: 'Kopi susu', category: _jajan),
      (day: 20, rupiah: 88000, note: 'Sushi bawa pulang', category: _jajan),
      (day: 23, rupiah: 36500, note: 'Roti bakar', category: _jajan),
      (day: 26, rupiah: 47000, note: 'Boba', category: _jajan),
      (day: 28, rupiah: 29500, note: 'Cilok', category: _jajan),
    ],
  ];

  /// Kategori buatan paket ini, dalam urutan tampil.
  static const List<({String id, String name, String iconKey})> categories = [
    (id: SpendingSeedIds.catKos, name: 'Tagihan Kos', iconKey: 'categoryBills'),
    (id: SpendingSeedIds.catListrik, name: 'Tagihan Listrik', iconKey: 'categoryBills'),
    (id: SpendingSeedIds.catBelanja, name: 'Belanja Bulanan', iconKey: 'categoryGroceries'),
    (id: SpendingSeedIds.catJajan, name: 'Jajan', iconKey: 'categoryFood'),
  ];

  @override
  String get id => 'spending_3_months';

  @override
  String get label => 'Pengeluaran 3 bulan + rutin nabung Rp7 jt';

  @override
  String get description =>
      'Tagihan kos, listrik, belanja bulanan, jajan, dan selingan (Rp5-7 jt per bulan), '
      'gaji suami, serta rutin nabung Rp7 jt ke Tabungan Rumah, Anak, Ke Jepang, dan Saham. '
      'Otomatis menerapkan paket Dompet bila belum ada.';

  @override
  Future<SeedResult> apply(GetIt container) => applyAt(container, DateTime.now());

  /// Seperti [apply] dengan "hari ini" [today] (untuk uji).
  Future<SeedResult> applyAt(GetIt container, DateTime today) async {
    T ok<T>(dynamic either) => (either as dynamic).fold((Object f) => throw StateError('$f'), (T r) => r) as T;

    await const WalletSeedPack().apply(container);
    final categoryRepo = container<CategoryRepository>();
    final txRepo = container<TransactionRepository>();
    final ruleRepo = container<RecurringRuleRepository>();
    var added = 0;
    var skipped = 0;

    // Kategori.
    final existingCategories = {for (final c in ok<List<Category>>(await categoryRepo.listCategories())) c.id};
    for (final (index, c) in categories.indexed) {
      if (existingCategories.contains(c.id)) {
        skipped++;
        continue;
      }
      ok<Unit>(
        await categoryRepo.saveCategory(
          Category(id: c.id, kind: CategoryKind.expense, name: c.name, iconKey: c.iconKey, sortOrder: 100 + index),
        ),
      );
      added++;
    }

    // Rutin nabung: patokan tanggal 2 di bulan pertama.
    final firstMonth = DateTime(today.year, today.month - (months.length - 1));
    final anchor = DateTime(firstMonth.year, firstMonth.month, savingsDay);
    final existingRules = {for (final r in ok<List<RecurringRule>>(await ruleRepo.listRules())) r.id};
    for (final s in savings) {
      if (existingRules.contains(s.ruleId)) {
        skipped++;
        continue;
      }
      ok<Unit>(
        await ruleRepo.saveRule(
          RecurringRule(
            id: s.ruleId,
            kind: RecurringKind.transfer,
            amount: _sen(s.rupiah),
            walletId: SeedIds.walletUtama,
            toWalletId: s.toWalletId,
            note: 'Nabung: ${s.name}',
            schedule: RecurringSchedule(frequency: RecurringFrequency.monthly, anchorDate: anchor),
            paymentMode: RecurringPaymentMode.manual,
          ),
        ),
      );
      added++;
    }

    // Transaksi per bulan, hanya yang tanggalnya belum lewat hari ini.
    final todayDate = DateTime(today.year, today.month, today.day);
    for (var m = 0; m < months.length; m++) {
      final month = DateTime(firstMonth.year, firstMonth.month + m);
      final key = '${month.year}${month.month.toString().padLeft(2, '0')}';
      final existing = {for (final t in ok<List<Transaction>>(await txRepo.listTransactionsInMonth(month))) t.id};
      final planned = <Transaction>[
        IncomeTransaction(
          id: 'seed_tx_${key}_gaji',
          date: DateTime(month.year, month.month),
          amount: _sen(salaryRupiah),
          note: 'Gaji suami',
          walletId: SeedIds.walletUtama,
          categoryId: 'builtin.salary',
        ),
        for (final (i, s) in months[m].indexed)
          ExpenseTransaction(
            id: 'seed_tx_${key}_${s.category.replaceAll('.', '_')}_${s.day}_$i',
            date: DateTime(month.year, month.month, s.day),
            amount: _sen(s.rupiah),
            note: s.note,
            walletId: SeedIds.walletUtama,
            categoryId: s.category,
          ),
        for (final s in savings)
          TransferTransaction(
            id: 'seed_tx_${key}_${s.ruleId}',
            date: DateTime(month.year, month.month, savingsDay),
            amount: _sen(s.rupiah),
            note: 'Nabung: ${s.name}',
            fromWalletId: SeedIds.walletUtama,
            toWalletId: s.toWalletId,
            recurrence: RecurrenceLink(ruleId: s.ruleId, occurrenceDate: DateTime(month.year, month.month, savingsDay)),
          ),
      ];
      for (final t in planned) {
        if (t.date.isAfter(todayDate)) continue;
        if (existing.contains(t.id)) {
          skipped++;
          continue;
        }
        ok<Unit>(await txRepo.saveTransaction(t));
        added++;
      }
    }

    if (added > 0) {
      final walletIds = [for (final w in WalletSeedPack.wallets) w.id];
      ok<Unit>(
        await RecomputeWalletBalances(
          walletRepository: container<WalletRepository>(),
          transactionRepository: txRepo,
        ).forWallets(walletIds),
      );
      container<LedgerChanges>().notifyChanged(source: this);
      container<RecurringChanges>().notifyChanged(source: this);
    }
    return SeedResult(added: added, skipped: skipped);
  }
}
