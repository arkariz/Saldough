// Penyusun cadangan data contoh untuk tangkapan layar listing Play.
//
// Bukan uji: dijalankan manual lewat
//   .fvm/flutter_sdk/bin/flutter test tool/store_screenshots/demo_backup_test.dart
// dan menulis `build/store_screenshots/demo_<bahasa>.tkbak`. Pulihkan di
// perangkat lewat Akun › Data kamu › Pulihkan dari cadangan. Data disusun
// dengan repositori nyata lalu saldo dihitung ulang, sama seperti
// `backup_roundtrip_test.dart`, dan tanggal relatif ke hari ini supaya
// Beranda dan Rencana selalu berisi periode berjalan.
//
// Nama dompet, catatan, dan nama rutin/anggaran/proyek adalah data pengguna
// (tidak diterjemahkan aplikasi), jadi ada satu set per bahasa listing.
// Dompet memakai nama generik (PLAY_STORE_LISTING.md §4).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/app/data_portability/app_backup_registry.dart';
import 'package:saldough/features/budget/data/repositories/budget_repository_impl.dart';
import 'package:saldough/features/budget/domain/entities/budget.dart';
import 'package:saldough/features/budget/domain/entities/budget_item.dart';
import 'package:saldough/features/budget/domain/entities/budget_item_kind.dart';
import 'package:saldough/features/budget/domain/entities/budget_period.dart';
import 'package:saldough/features/data_portability/data/backup_codec.dart';
import 'package:saldough/features/data_portability/data/backup_scope.dart';
import 'package:saldough/features/data_portability/data/backup_validator.dart';
import 'package:saldough/features/freelance/data/repositories/freelance_repository_impl.dart';
import 'package:saldough/features/freelance/domain/entities/freelance_payment.dart';
import 'package:saldough/features/freelance/domain/entities/freelance_project.dart';
import 'package:saldough/features/freelance/domain/entities/payment_status.dart';
import 'package:saldough/features/freelance/domain/entities/worklog_entry.dart';
import 'package:saldough/shared/category/data/category_repository_impl.dart';
import 'package:saldough/shared/category/domain/built_in_categories.dart';
import 'package:saldough/shared/category/domain/category.dart';
import 'package:saldough/shared/recurring/data/recurring_rule_repository_impl.dart';
import 'package:saldough/shared/recurring/domain/recurring_rule.dart';
import 'package:saldough/shared/transaction/data/transaction_repository_impl.dart';
import 'package:saldough/shared/transaction/domain/transaction.dart';
import 'package:saldough/shared/transaction/domain/usecases/recompute_wallet_balances.dart';
import 'package:saldough/shared/wallet/data/wallet_repository_impl.dart';
import 'package:saldough/shared/wallet/domain/wallet.dart';

/// Rupiah ke sen.
int rp(int rupiah) => rupiah * 100;

/// Teks data pengguna per bahasa.
final class _Copy {
  const _Copy(this.values);

  final Map<String, String> values;

  String operator [](String key) => values[key]!;
}

const _copies = {
  'id': _Copy({
    'bank': 'Bank',
    'ewallet': 'E-wallet',
    'cash': 'Tunai',
    'savings': 'Tabungan',
    'salary': 'Gaji Oktober',
    'salaryRule': 'Gaji',
    'lunch': 'Makan siang',
    'coffee': 'Kopi susu',
    'dinner': 'Makan malam bareng',
    'groceries': 'Belanja dapur mingguan',
    'fuel': 'Bensin motor',
    'commute': 'Ojek ke kantor',
    'power': 'Token listrik',
    'internet': 'Internet rumah',
    'streaming': 'Langganan streaming',
    'pharmacy': 'Vitamin dan obat flu',
    'shirt': 'Kemeja kerja',
    'rent': 'Kos',
    'save': 'Nabung',
    'topup': 'Isi saldo e-wallet',
    'withdraw': 'Tarik tunai',
    'parents': 'Kiriman orang tua',
    'budget': 'Bulanan',
    'itemFood': 'Makan',
    'itemGroceries': 'Belanja dapur',
    'itemTransport': 'Transportasi',
    'itemFun': 'Hiburan',
    'itemSave': 'Dana darurat',
    'project': 'Desain logo Kopi Senja',
    'work1': 'Riset dan moodboard',
    'work2': 'Sketsa tiga konsep',
    'work3': 'Revisi konsep terpilih',
    'work4': 'Panduan warna',
    'work5': 'Mockup kemasan',
  }),
  'en': _Copy({
    'bank': 'Bank',
    'ewallet': 'E-wallet',
    'cash': 'Cash',
    'savings': 'Savings',
    'salary': 'October salary',
    'salaryRule': 'Salary',
    'lunch': 'Lunch',
    'coffee': 'Iced latte',
    'dinner': 'Dinner with friends',
    'groceries': 'Weekly groceries',
    'fuel': 'Scooter fuel',
    'commute': 'Ride to the office',
    'power': 'Electricity top-up',
    'internet': 'Home internet',
    'streaming': 'Streaming plan',
    'pharmacy': 'Vitamins and cold medicine',
    'shirt': 'Work shirt',
    'rent': 'Rent',
    'save': 'Savings',
    'topup': 'E-wallet top-up',
    'withdraw': 'Cash withdrawal',
    'parents': 'Money for parents',
    'budget': 'Monthly',
    'itemFood': 'Food',
    'itemGroceries': 'Groceries',
    'itemTransport': 'Transport',
    'itemFun': 'Fun',
    'itemSave': 'Emergency fund',
    'project': 'Logo design for Dusk Coffee',
    'work1': 'Research and moodboard',
    'work2': 'Three concept sketches',
    'work3': 'Revise chosen concept',
    'work4': 'Color guide',
    'work5': 'Packaging mockup',
  }),
};

/// Jam wajar per jenis catatan, supaya daftar tidak menampilkan 00.00.
const _clock = {
  'salary': (9, 5),
  'lunch': (12, 24),
  'coffee': (8, 12),
  'dinner': (19, 41),
  'groceries': (10, 18),
  'fuel': (17, 36),
  'commute': (7, 48),
  'power': (20, 3),
  'internet': (6, 0),
  'streaming': (6, 0),
  'pharmacy': (18, 22),
  'shirt': (15, 9),
  'rent': (8, 30),
  'save': (9, 15),
  'topup': (21, 2),
  'withdraw': (16, 44),
  'parents': (9, 30),
  'project': (14, 27),
};

DateTime _timed(DateTime date, String key) {
  final (hour, minute) = _clock[key] ?? (12, 0);
  return DateTime(date.year, date.month, date.day, hour, minute);
}

/// Kategori bawaan seperti yang dibuat bootstrap (`MigrateLegacyCategories`),
/// bernama dari i18n bahasa [lang] supaya aplikasi bisa melokalkannya ulang.
Future<void> _seedCategories(InMemoryKeyValueStorage storage, String lang) async {
  final json = jsonDecode(File('assets/i18n/$lang.i18n.json').readAsStringSync()) as Map<String, dynamic>;
  final names = (json['category'] as Map<String, dynamic>)['builtIn(map)'] as Map<String, dynamic>;
  await CategoryRepositoryImpl(storage: storage).saveCategories([
    for (final (index, builtIn) in BuiltInCategories.all.indexed)
      Category(
        id: builtIn.id,
        kind: builtIn.kind,
        name: names[builtIn.key] as String? ?? builtIn.key,
        builtInKey: builtIn.key,
        iconKey: builtIn.iconKey,
        sortOrder: index,
      ),
  ]);
}

Future<void> _seed(InMemoryKeyValueStorage storage, _Copy t, DateTime today) async {
  final wallets = WalletRepositoryImpl(storage: storage);
  final transactions = TransactionRepositoryImpl(storage: storage);

  for (final w in [
    Wallet(id: 'bank', name: t['bank'], iconKey: 'walletBank', initialBalance: rp(6200000), currentBalance: 0),
    Wallet(id: 'ewallet', name: t['ewallet'], iconKey: 'walletEwallet', initialBalance: rp(180000), currentBalance: 0),
    Wallet(id: 'cash', name: t['cash'], iconKey: 'walletCash', initialBalance: rp(250000), currentBalance: 0),
    Wallet(
      id: 'savings',
      name: t['savings'],
      iconKey: 'walletSavings',
      initialBalance: rp(12000000),
      currentBalance: 0,
    ),
  ]) {
    await wallets.saveWallet(w);
  }

  // Bulan lalu dan bulan berjalan (periode bawaan mulai tanggal 1).
  final thisMonth = DateTime(today.year, today.month);
  DateTime last(int day) => DateTime(thisMonth.year, thisMonth.month - 1, day);
  DateTime now(int daysAgo) => DateTime(today.year, today.month, today.day - daysAgo);
  bool inThisMonth(DateTime d) => !d.isBefore(thisMonth);

  // Pos anggaran bulan berjalan (dompet Bank).
  const food = 'item-food';
  const groceries = 'item-groceries';
  const transport = 'item-transport';
  const fun = 'item-fun';
  const save = 'item-save';

  var seq = 0;
  final list = <Transaction>[];
  void expense(DateTime date, int amount, String key, String category, String wallet, {String? item}) => list.add(
    ExpenseTransaction(
      id: 'tx-${seq++}',
      date: _timed(date, key),
      amount: rp(amount),
      note: t[key],
      walletId: wallet,
      categoryId: 'builtin.$category',
      budgetItemId: wallet == 'bank' && inThisMonth(date) ? item : null,
    ),
  );
  void income(DateTime date, int amount, String key, String category, String wallet, {String? paymentId}) => list.add(
    IncomeTransaction(
      id: 'tx-${seq++}',
      date: _timed(date, key),
      amount: rp(amount),
      note: t[key],
      walletId: wallet,
      categoryId: 'builtin.$category',
      freelancePaymentId: paymentId,
    ),
  );
  void transfer(DateTime date, int amount, String key, String from, String to, {String? item}) => list.add(
    TransferTransaction(
      id: 'tx-${seq++}',
      date: _timed(date, key),
      amount: rp(amount),
      note: t[key],
      fromWalletId: from,
      toWalletId: to,
      budgetItemId: from == 'bank' && inThisMonth(date) ? item : null,
    ),
  );

  // Bulan lalu.
  transfer(last(1), 1800000, 'rent', 'bank', 'cash');
  expense(last(2), 52000, 'lunch', 'food', 'ewallet');
  expense(last(3), 28000, 'coffee', 'food', 'ewallet');
  expense(last(4), 412000, 'groceries', 'groceries', 'bank');
  expense(last(6), 35000, 'fuel', 'transport', 'cash');
  expense(last(8), 200000, 'power', 'bills', 'bank');
  expense(last(10), 350000, 'internet', 'internet', 'bank');
  expense(last(11), 386000, 'groceries', 'groceries', 'bank');
  expense(last(13), 46000, 'lunch', 'food', 'ewallet');
  expense(last(15), 54000, 'streaming', 'entertainment', 'bank');
  expense(last(16), 168000, 'dinner', 'food', 'bank');
  expense(last(18), 398000, 'groceries', 'groceries', 'bank');
  expense(last(19), 24000, 'commute', 'transport', 'ewallet');
  expense(last(21), 289000, 'shirt', 'shopping', 'bank');
  transfer(last(22), 300000, 'topup', 'bank', 'ewallet');
  expense(last(23), 98000, 'pharmacy', 'health', 'bank');
  income(last(25), 8500000, 'salary', 'salary', 'bank');
  expense(last(25), 500000, 'parents', 'family', 'bank');
  transfer(last(26), 1000000, 'save', 'bank', 'savings');
  expense(last(27), 421000, 'groceries', 'groceries', 'bank');
  expense(last(29), 31000, 'coffee', 'food', 'ewallet');
  // 12 jam x Rp150.000 dari tiga worklog pertama, diterima awal bulan ini
  // supaya kartu Arus Beranda punya pemasukan.
  final received = inThisMonth(now(4)) ? now(4) : last(30);
  income(received, 1800000, 'project', 'freelance', 'bank', paymentId: 'pay-1');

  // Bulan berjalan, hanya sampai hari ini.
  void at(int daysAgo, void Function(DateTime) add) {
    final date = now(daysAgo);
    if (inThisMonth(date)) add(date);
  }

  at(6, (d) => expense(d, 1800000, 'rent', 'bills', 'bank'));
  at(6, (d) => expense(d, 58000, 'lunch', 'food', 'bank', item: food));
  at(5, (d) => expense(d, 437000, 'groceries', 'groceries', 'bank', item: groceries));
  at(5, (d) => expense(d, 29000, 'coffee', 'food', 'ewallet'));
  at(4, (d) => expense(d, 38000, 'fuel', 'transport', 'bank', item: transport));
  at(3, (d) => expense(d, 64000, 'lunch', 'food', 'bank', item: food));
  at(3, (d) => transfer(d, 400000, 'withdraw', 'bank', 'cash'));
  at(2, (d) => expense(d, 185000, 'dinner', 'food', 'bank', item: fun));
  at(1, (d) => expense(d, 26000, 'commute', 'transport', 'bank', item: transport));
  at(1, (d) => transfer(d, 1000000, 'save', 'bank', 'savings', item: save));
  at(0, (d) => expense(d, 32000, 'coffee', 'food', 'bank', item: food));
  at(0, (d) => expense(d, 24000, 'commute', 'transport', 'cash'));

  for (final tx in list) {
    await transactions.saveTransaction(tx);
  }
  await RecomputeWalletBalances(walletRepository: wallets, transactionRepository: transactions)();

  await BudgetRepositoryImpl(storage: storage).saveBudget(
    Budget(
      id: 'budget-monthly',
      name: t['budget'],
      walletId: 'bank',
      period: BudgetPeriod.monthly,
      startDate: thisMonth,
      items: [
        BudgetItem(id: food, name: t['itemFood'], enteredAmount: rp(1500000)),
        BudgetItem(id: groceries, name: t['itemGroceries'], enteredAmount: rp(1600000)),
        BudgetItem(id: transport, name: t['itemTransport'], enteredAmount: rp(500000)),
        BudgetItem(id: fun, name: t['itemFun'], enteredAmount: rp(400000)),
        BudgetItem(
          id: save,
          name: t['itemSave'],
          enteredAmount: rp(1000000),
          kind: BudgetItemKind.transfer,
          targetWalletId: 'savings',
        ),
      ],
    ),
  );

  // Rutin berjadwal ke depan, jadi tidak ada kemunculan yang tertunggak.
  DateTime next(int day) {
    final candidate = DateTime(today.year, today.month, day);
    return candidate.isAfter(today) ? candidate : DateTime(today.year, today.month + 1, day);
  }

  final rules = RecurringRuleRepositoryImpl(storage: storage);
  for (final rule in [
    RecurringRule(
      id: 'rule-salary',
      kind: RecurringKind.income,
      amount: rp(8500000),
      walletId: 'bank',
      categoryId: 'builtin.salary',
      note: t['salaryRule'],
      schedule: RecurringSchedule(frequency: RecurringFrequency.monthly, anchorDate: next(25)),
    ),
    RecurringRule(
      id: 'rule-internet',
      kind: RecurringKind.expense,
      amount: rp(350000),
      walletId: 'bank',
      categoryId: 'builtin.internet',
      note: t['internet'],
      paymentMode: RecurringPaymentMode.autoDebit,
      schedule: RecurringSchedule(frequency: RecurringFrequency.monthly, anchorDate: next(10)),
    ),
    RecurringRule(
      id: 'rule-streaming',
      kind: RecurringKind.expense,
      amount: rp(54000),
      walletId: 'bank',
      categoryId: 'builtin.entertainment',
      note: t['streaming'],
      paymentMode: RecurringPaymentMode.autoDebit,
      schedule: RecurringSchedule(frequency: RecurringFrequency.monthly, anchorDate: next(15)),
    ),
    RecurringRule(
      id: 'rule-power',
      kind: RecurringKind.expense,
      amount: rp(200000),
      amountMode: RecurringAmountMode.estimated,
      walletId: 'bank',
      categoryId: 'builtin.bills',
      note: t['power'],
      schedule: RecurringSchedule(frequency: RecurringFrequency.monthly, anchorDate: next(8)),
    ),
    RecurringRule(
      id: 'rule-save',
      kind: RecurringKind.transfer,
      amount: rp(1000000),
      walletId: 'bank',
      toWalletId: 'savings',
      note: t['save'],
      schedule: RecurringSchedule(frequency: RecurringFrequency.monthly, anchorDate: next(26)),
    ),
    RecurringRule(
      id: 'rule-rent',
      kind: RecurringKind.expense,
      amount: rp(1800000),
      walletId: 'bank',
      categoryId: 'builtin.bills',
      note: t['rent'],
      schedule: RecurringSchedule(
        frequency: RecurringFrequency.monthly,
        anchorDate: DateTime(today.year, today.month + 1),
      ),
    ),
  ]) {
    await rules.saveRule(rule);
  }

  // Freelance: satu pembayaran sudah diterima (bulan lalu), satu menunggu.
  final freelance = FreelanceRepositoryImpl(storage: storage);
  await freelance.saveProject(FreelanceProject(id: 'project-1', name: t['project'], hourlyRate: rp(150000)));
  final paidEntries = [
    WorklogEntry(
      id: 'w-1',
      projectId: 'project-1',
      date: last(14),
      hours: 4,
      hourlyRate: rp(150000),
      note: t['work1'],
      paymentId: 'pay-1',
    ),
    WorklogEntry(
      id: 'w-2',
      projectId: 'project-1',
      date: last(17),
      hours: 5,
      hourlyRate: rp(150000),
      note: t['work2'],
      paymentId: 'pay-1',
    ),
    WorklogEntry(
      id: 'w-3',
      projectId: 'project-1',
      date: last(20),
      hours: 3,
      hourlyRate: rp(150000),
      note: t['work3'],
      paymentId: 'pay-1',
    ),
  ];
  final openEntries = [
    WorklogEntry(
      id: 'w-4',
      projectId: 'project-1',
      date: last(28),
      hours: 3,
      hourlyRate: rp(150000),
      note: t['work4'],
      paymentId: 'pay-2',
    ),
    WorklogEntry(
      id: 'w-5',
      projectId: 'project-1',
      date: now(2),
      hours: 4,
      hourlyRate: rp(150000),
      note: t['work5'],
      paymentId: 'pay-2',
    ),
  ];
  await freelance.saveEntries([...paidEntries, ...openEntries]);
  final paidIncome = list.whereType<IncomeTransaction>().firstWhere((tx) => tx.freelancePaymentId == 'pay-1');
  await freelance.savePayment(
    FreelancePayment(
      id: 'pay-1',
      projectId: 'project-1',
      entryIds: paidEntries.map((e) => e.id).toList(),
      expectedDate: last(30),
      status: PaymentStatus.paid,
      walletId: 'bank',
      incomeTransactionId: paidIncome.id,
      receivedDate: paidIncome.date,
    ),
  );
  await freelance.savePayment(
    FreelancePayment(
      id: 'pay-2',
      projectId: 'project-1',
      entryIds: openEntries.map((e) => e.id).toList(),
      expectedDate: DateTime(today.year, today.month, today.day + 10),
    ),
  );
}

void main() {
  for (final MapEntry(key: lang, value: copy) in _copies.entries) {
    test('cadangan demo $lang', () async {
      final storage = InMemoryKeyValueStorage();
      final now = DateTime.now();
      await _seedCategories(storage, lang);
      await _seed(storage, copy, DateTime(now.year, now.month, now.day));

      final docs = await BackupScope.collect(storage, appBackupRegistry);
      final summary = BackupValidator.summarize(docs, appBackupRegistry);
      final bytes = BackupCodec.encode(docs: docs, createdAt: now, appVersion: '1.0.0', appBuild: 22, summary: summary);
      BackupValidator.validate(BackupCodec.decode(bytes), appBackupRegistry);

      final out = File('build/store_screenshots/demo_$lang.${BackupCodec.extension}')
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes);
      // Alat manual: jalurnya perlu terlihat di keluaran `flutter test`.
      // ignore: avoid_print
      print('${out.path}: ${summary.toJson()}');
    });
  }
}
