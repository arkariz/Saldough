import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/analysis/domain/period_summary.dart';
import 'package:saldough/features/analysis/domain/summarize_period.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Ringkasan periode Analisis (T-19.1, FINANCIAL_ANALYSIS B-1..B-10, B-14) dengan
/// contoh §10 persis dalam sen, kecocokan Beranda (B-3) dan Rencana (B-15).
void main() {
  // Rupiah → sen (aturan 1: uang `int` sen).
  int rp(int rupiah) => rupiah * 100;

  Category cat(String id, String name, {CategoryKind kind = CategoryKind.expense, bool archived = false}) =>
      Category(id: id, kind: kind, name: name, isArchived: archived);

  final belanja = cat('belanja', 'Belanja');
  final cicilan = cat('cicilan', 'Cicilan');
  final tempat = cat('tempat', 'Tempat tinggal');
  final makan = cat('makan', 'Makan');
  final sedekah = cat('sedekah', 'Sedekah');
  final tagihan = cat('tagihan', 'Tagihan');
  final langganan = cat('langganan', 'Langganan');
  final transportasi = cat('transportasi', 'Transportasi');
  final gaji = cat('gaji', 'Gaji', kind: CategoryKind.income);
  final all = {for (final c in [belanja, cicilan, tempat, makan, sedekah, tagihan, langganan, transportasi, gaji]) c.id: c};
  Category? categoryOf(String id) => all[id];

  final from = DateTime(2026, 9);
  final until = DateTime(2026, 10);

  var nextId = 0;
  ExpenseTransaction expense(
    int rupiah, {
    String? category,
    DateTime? date,
    String wallet = 'bca',
    String? budgetItem,
    RecurrenceLink? recurrence,
  }) => ExpenseTransaction(
    id: 'e${nextId++}',
    date: date ?? DateTime(2026, 9, 12, 9),
    amount: rp(rupiah),
    note: '',
    walletId: wallet,
    categoryId: category,
    budgetItemId: budgetItem,
    recurrence: recurrence,
  );
  IncomeTransaction income(int sen, {String? category, String? freelance, DateTime? date, String wallet = 'bca'}) =>
      IncomeTransaction(
        id: 'i${nextId++}',
        date: date ?? DateTime(2026, 9, 25, 9),
        amount: sen,
        note: '',
        walletId: wallet,
        categoryId: category,
        freelancePaymentId: freelance,
      );
  TransferTransaction transfer(int rupiah, {String fromWallet = 'bca', String toWallet = 'tabungan', String? budgetItem}) =>
      TransferTransaction(
        id: 't${nextId++}',
        date: DateTime(2026, 9, 28, 9, 30),
        amount: rp(rupiah),
        note: '',
        fromWalletId: fromWallet,
        toWalletId: toWallet,
        budgetItemId: budgetItem,
      );

  /// September 2026, contoh §10 (semua dompet).
  List<Transaction> september() => [
    expense(3068500, category: 'belanja'),
    expense(2914000, category: 'cicilan'),
    expense(1900000, category: 'tempat'),
    expense(1245000, category: 'makan'),
    expense(800000, category: 'sedekah'),
    expense(550000, category: 'tagihan'),
    expense(413200, category: 'langganan'),
    expense(410000, category: 'transportasi'),
    expense(120000),
    income(rp(12000000), category: 'gaji'),
    // Pembayaran freelance: gaji bersih 37 jam × Rp72.500, pajak 2,5% = Rp2.615.438 (sen 261.543.750).
    income(261543750, freelance: 'pay1'),
    transfer(1000000),
  ];

  PeriodSummary summary(
    Iterable<Transaction> transactions, {
    CategoryKind kind = CategoryKind.expense,
    String? walletId,
  }) => summarizePeriod(
    transactions,
    from: from,
    until: until,
    kind: kind,
    categoryOf: categoryOf,
    walletId: walletId,
  );

  group('persen tampil (B-8)', () {
    test('dibulatkan setengah ke atas dengan bilangan bulat; di bawah 0,5% tampil "<1%"', () {
      expect(AnalysisShare.of(5, 1000), const AnalysisShare(percent: 1, belowOne: false), reason: '0,5% tepat → 1%');
      expect(AnalysisShare.of(499, 100000), const AnalysisShare(percent: 0, belowOne: true), reason: '0,499% → <1%');
      expect(AnalysisShare.of(1, 1000000), const AnalysisShare(percent: 0, belowOne: true));
      expect(AnalysisShare.of(149, 1000), const AnalysisShare(percent: 15, belowOne: false), reason: '14,9% → 15%');
      expect(AnalysisShare.of(145, 1000), const AnalysisShare(percent: 15, belowOne: false), reason: '14,5% → 15%');
      expect(AnalysisShare.of(144, 1000), const AnalysisShare(percent: 14, belowOne: false));
      expect(AnalysisShare.of(0, 1000), const AnalysisShare(percent: 0, belowOne: false), reason: 'nol bukan <1%');
      expect(AnalysisShare.of(1000, 1000), const AnalysisShare(percent: 100, belowOne: false));
      expect(AnalysisShare.of(10, 0), const AnalysisShare(percent: 0, belowOne: false));
    });
  });

  group('contoh §10, September 2026', () {
    test('pengeluaran: total Rp11.420.700, urutan, persen, Lainnya 12% (bukan 13%), Tanpa kategori 1%', () {
      final s = summary(september());
      expect(s.total, rp(11420700));
      expect(s.count, 9);
      expect([for (final g in s.groups) g.kind], [
        AnalysisGroupKind.category,
        AnalysisGroupKind.category,
        AnalysisGroupKind.category,
        AnalysisGroupKind.category,
        AnalysisGroupKind.category,
        AnalysisGroupKind.others,
        AnalysisGroupKind.uncategorized,
      ]);
      expect([for (final g in s.groups.take(5)) g.category!.name], [
        'Belanja',
        'Cicilan',
        'Tempat tinggal',
        'Makan',
        'Sedekah',
      ]);
      expect([for (final g in s.groups) g.amount], [
        rp(3068500),
        rp(2914000),
        rp(1900000),
        rp(1245000),
        rp(800000),
        rp(1373200),
        rp(120000),
      ]);
      expect([for (final g in s.groups) g.share.percent], [27, 26, 17, 11, 7, 12, 1]);
      // Tampil 101%; jumlah persen tidak dipaksa 100 (B-8).
      expect(s.groups.fold(0, (sum, g) => sum + g.share.percent), 101);
      // Persen Lainnya dari nominal gabungannya, bukan jumlah persen anggotanya (5 + 4 + 4).
      final others = s.groups[5];
      expect(others.children.map((g) => g.category!.name), ['Tagihan', 'Langganan', 'Transportasi']);
      expect(others.children.map((g) => g.share.percent), [5, 4, 4]);
      // Jumlah nominal semua baris, termasuk Lainnya dan Tanpa kategori, = total persis (B-8).
      expect(s.groups.fold(0, (sum, g) => sum + g.amount), s.total);
    });

    test('pemasukan: Rp14.615.438 dengan Freelance sebagai kelompok turunan (B-9); selisih Rp3.194.738', () {
      // Gaji bersih freelance 37 jam × Rp72.500 − pajak 2,5% = 261.543.750 sen (Rp2.615.437,50); dokumen
      // membulatkan tampilannya ke Rp2.615.438, jadi total dan selisih di bawah juga setengah rupiah.
      final transactions = september();
      final s = summary(transactions, kind: CategoryKind.income);
      expect(s.total, 1461543750);
      expect([for (final g in s.groups) g.kind], [AnalysisGroupKind.category, AnalysisGroupKind.freelance]);
      expect(s.groups[0].category!.name, 'Gaji');
      expect([for (final g in s.groups) g.amount], [rp(12000000), 261543750]);
      expect([for (final g in s.groups) g.share.percent], [82, 18]);
      final expenses = summary(transactions);
      expect(s.total - expenses.total, 319473750);
    });

    test('transfer hanya informasi (B-4): satu baris untuk semua dompet, tidak masuk total atau persen', () {
      final s = summary(september());
      expect(s.transfers.perWallet, isFalse);
      expect(s.transfers.total, rp(1000000));
      expect(s.transfers.hasAny, isTrue);
      expect(s.total, rp(11420700));
    });

    test('satu dompet: transfer masuk dan keluar terpisah, total hanya dari dompet itu (B-4)', () {
      final transactions = [...september(), transfer(250000, fromWallet: 'gopay', toWallet: 'bca')];
      final bca = summary(transactions, walletId: 'bca');
      expect(bca.transfers.perWallet, isTrue);
      expect(bca.transfers.incoming, rp(250000));
      expect(bca.transfers.outgoing, rp(1000000));
      expect(bca.total, rp(11420700));
      final tabungan = summary(transactions, walletId: 'tabungan');
      expect(tabungan.total, 0);
      expect(tabungan.isEmpty, isTrue);
      expect(tabungan.transfers.incoming, rp(1000000));
      expect(tabungan.transfers.outgoing, 0);
      final gopay = summary(transactions, walletId: 'gopay');
      expect(gopay.transfers.hasAny, isTrue);
    });
  });

  group('daftar kategori (B-10)', () {
    test('satu kategori sisa tampil langsung, tanpa Lainnya', () {
      final six = [for (var i = 0; i < 6; i++) cat('k$i', 'Kategori $i')];
      final lookup = {for (final c in six) c.id: c};
      final s = summarizePeriod(
        [for (var i = 0; i < 6; i++) expense(1000 - i * 100, category: 'k$i')],
        from: from,
        until: until,
        kind: CategoryKind.expense,
        categoryOf: (id) => lookup[id],
      );
      expect(s.groups.map((g) => g.kind), everyElement(AnalysisGroupKind.category));
      expect(s.groups, hasLength(6));
    });

    test('nominal sama diurut nama; Tanpa kategori selalu terakhir dan tidak masuk Lainnya', () {
      final names = {for (final n in ['Bensin', 'Apotek', 'Cafe', 'Dapur', 'Es', 'Fotokopi', 'Gym']) n: cat(n, n)};
      final s = summarizePeriod(
        [
          for (final n in names.keys) expense(500, category: n),
          expense(100000), // terbesar tetapi tanpa kategori
        ],
        from: from,
        until: until,
        kind: CategoryKind.expense,
        categoryOf: (id) => names[id],
      );
      expect(s.groups.last.kind, AnalysisGroupKind.uncategorized);
      final named = s.groups.where((g) => g.kind == AnalysisGroupKind.category).map((g) => g.category!.name);
      expect(named, ['Apotek', 'Bensin', 'Cafe', 'Dapur', 'Es']);
      final others = s.groups.singleWhere((g) => g.kind == AnalysisGroupKind.others);
      expect(others.children.map((g) => g.category!.name), ['Fotokopi', 'Gym']);
    });

    test('di atas nol tetapi di bawah 0,5% tampil "<1%"', () {
      final s = summary([expense(9990, category: 'belanja'), expense(1, category: 'makan')]);
      expect(s.groups.last.share, const AnalysisShare(percent: 0, belowOne: true));
    });
  });

  group('kategori dan kelompok turunan (B-9, B-14)', () {
    test('kategori diarsipkan tetap dihitung dan ditandai', () {
      final archived = cat('lama', 'Lama', archived: true);
      final s = summarizePeriod(
        [expense(1000, category: 'lama')],
        from: from,
        until: until,
        kind: CategoryKind.expense,
        categoryOf: (id) => id == 'lama' ? archived : null,
      );
      expect(s.groups.single.isArchived, isTrue);
      expect(s.total, rp(1000));
    });

    test('id kategori yang tidak dikenal dibaca sebagai Tanpa kategori', () {
      final s = summary([expense(700, category: 'hilang')]);
      expect(s.groups.single.kind, AnalysisGroupKind.uncategorized);
      expect(s.total, rp(700));
    });

    test('pembayaran freelance berkategori masuk kategorinya; tanpa kategori dan bukan freelance = Tanpa kategori', () {
      final s = summary([
        income(rp(500), category: 'gaji', freelance: 'p1'),
        income(rp(300), freelance: 'p2'),
        income(rp(200)),
      ], kind: CategoryKind.income);
      expect([for (final g in s.groups) g.kind], [
        AnalysisGroupKind.category,
        AnalysisGroupKind.freelance,
        AnalysisGroupKind.uncategorized,
      ]);
    });
  });

  group('periode (B-2)', () {
    test('batas: awal periode masuk, awal periode berikutnya tidak', () {
      final s = summary([
        expense(100, category: 'makan', date: DateTime(2026, 9)),
        expense(200, category: 'makan', date: DateTime(2026, 9, 30, 23, 59)),
        expense(400, category: 'makan', date: DateTime(2026, 10)),
        expense(800, category: 'makan', date: DateTime(2026, 8, 31, 23, 59)),
      ]);
      expect(s.total, rp(300));
    });

    test('gaji 23 Okt tertaut kemunculan 25 Okt masuk periode 25 Okt, bukan 25 Sep – 24 Okt (contoh D)', () {
      final early = income(
        rp(12000000),
        category: 'gaji',
        date: DateTime(2026, 10, 23, 9),
      ).withRecurrence(RecurrenceLink(ruleId: 'gaji', occurrenceDate: DateTime(2026, 10, 25)));
      final previous = summarizePeriod(
        [early],
        from: DateTime(2026, 9, 25),
        until: DateTime(2026, 10, 25),
        kind: CategoryKind.income,
        categoryOf: categoryOf,
      );
      final current = summarizePeriod(
        [early],
        from: DateTime(2026, 10, 25),
        until: DateTime(2026, 11, 25),
        kind: CategoryKind.income,
        categoryOf: categoryOf,
      );
      expect(previous.total, 0);
      expect(current.total, rp(12000000));
    });
  });

  group('kecocokan dengan layar lain', () {
    test('B-3: total Analisis (semua dompet) = Pemasukan dan Pengeluaran kartu Arus Beranda', () {
      final transactions = [
        ...september(),
        // Dompet nonaktif tetap dihitung (B-5) dan transaksi tertaut rutin ikut tanggal kemunculannya.
        expense(450000, category: 'makan', wallet: 'lama'),
        income(
          rp(100),
          category: 'gaji',
          date: DateTime(2026, 10, 3),
        ).withRecurrence(RecurrenceLink(ruleId: 'gaji', occurrenceDate: DateTime(2026, 9, 30))),
      ];
      final cash = const CalculateCashFlow().inPeriod(transactions, from: from, until: until);
      expect(summary(transactions).total, cash.expense);
      expect(summary(transactions, kind: CategoryKind.income).total, cash.income);
    });

    test('B-15: total pengeluaran = rutin tercatat + anggaran terpakai tanpa transfer + di luar rencana', () {
      RecurringRule rule(String id, int rupiah, int day) => RecurringRule(
        id: id,
        kind: RecurringKind.expense,
        amount: rp(rupiah),
        walletId: 'bca',
        note: id,
        schedule: RecurringSchedule(frequency: RecurringFrequency.monthly, anchorDate: DateTime(2026, 9, day)),
      );
      ExpenseTransaction recorded(RecurringRule r, String category) => expense(
        r.amount ~/ 100,
        category: category,
        date: r.schedule.anchorDate.add(const Duration(hours: 9)),
        recurrence: RecurrenceLink(ruleId: r.id, occurrenceDate: r.schedule.anchorDate),
      );
      final rules = [
        rule('cicilan', 2914000, 10),
        rule('kos', 1900000, 1),
        rule('sabil', 800000, 28),
        rule('tagihan', 550000, 5),
        rule('langganan', 413200, 3),
      ];
      final transactions = <Transaction>[
        recorded(rules[0], 'cicilan'),
        recorded(rules[1], 'tempat'),
        recorded(rules[2], 'sedekah'),
        recorded(rules[3], 'tagihan'),
        recorded(rules[4], 'langganan'),
        // Anggaran Belanja, dan transfer Tabungan Rp1.000.000 tertaut pos tabungan.
        expense(3068500, category: 'belanja', budgetItem: 'belanja-sep'),
        transfer(1000000, budgetItem: 'tabungan-sep'),
        // Di luar rencana: Makan, Transportasi, Tanpa kategori.
        expense(1245000, category: 'makan'),
        expense(410000, category: 'transportasi'),
        expense(120000),
      ];
      final plan = monthPlan(
        rules,
        from: from,
        until: until,
        today: DateTime(2026, 10, 10),
        transactions: transactions,
        budgetLines: [
          (itemId: 'belanja-sep', key: null, planned: rp(3068500), spent: rp(3068500)),
          (itemId: 'tabungan-sep', key: null, planned: rp(1000000), spent: rp(1000000)),
        ],
      );
      expect(plan.recordedRecurringOut, rp(6577200));
      expect(plan.unplannedOut, rp(1775000));
      // Satu-satunya selisih sah (B-15, aturan 7): transfer tertaut pos terhitung "anggaran terpakai" di Rencana.
      const transferLinkedToBudget = 100000000;
      expect(plan.budgetSpent - transferLinkedToBudget, rp(3068500));
      expect(
        summary(transactions).total,
        plan.recordedRecurringOut + (plan.budgetSpent - transferLinkedToBudget) + plan.unplannedOut,
      );
      expect(summary(transactions).total, rp(11420700));
    });
  });
}
