// Skrip pengembang SEKALI PAKAI (Fase 6 — Seed). Bukan bagian `lib/`, tidak
// ikut ter-build ke rilis, tidak punya UI. Lihat docs/04-planning/TASK_LIST.md
// bagian Fase 6 dan ADR-0009 (catatan revisi) untuk alasan desainnya.
//
// ignore_for_file: avoid_print — progres & hasil rekonsiliasi WAJIB terlihat
// di terminal, ini bukan "production code" yang perlu logging framework.
//
// Membaca tool/seed_data.json (data historis nyata pemilik, lihat berkas itu
// untuk sumber dan keputusan cakupannya) dan menulis langsung lewat
// repository tiap fitur ke KeyValueStorage — TANPA lewat GetIt/IsolatedScope
// (repository-nya sendiri tidak punya dependensi Flutter).
//
// MASALAH TEKNIS: `HiveKeyValueStorage.initialize()` (package hive_storage)
// memanggil `Hive.initFlutter()`, yang butuh `WidgetsFlutterBinding` dan
// `path_provider` — tidak tersedia di proses `dart run` murni. Skrip ini
// memakai `hive_ce` (murni Dart, lihat dev_dependencies di pubspec.yaml)
// langsung, membuka box Hive bernama SAMA (`saldough_kv`) lewat `Hive.init`
// biasa pada path yang diberikan — BUKAN `initFlutter`. Supaya skrip ini
// menulis ke box yang SAMA yang dibaca aplikasi sungguhan, `--db-path` harus
// menunjuk folder dokumen aplikasi di perangkat pemilik (lihat --help).
//
// Cara pakai:
//   dart run tool/seed_import.dart --db-path <folder_data_app>
//   dart run tool/seed_import.dart --db-path /tmp/saldough_dry_run --dry-run
//
// `--dry-run` menulis ke folder sementara lalu membaca-ulang & mencocokkan
// setiap siklus terhadap data sumbernya (T-6.8) tanpa menyentuh data asli.
import 'dart:convert';
import 'dart:io';

import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:saldough/features/card/data/card_roll_up_resolver.dart';
import 'package:saldough/features/card/data/repositories/card_statement_repository_impl.dart';
import 'package:saldough/features/card/data/repositories/credit_card_repository_impl.dart';
import 'package:saldough/features/card/domain/entities/card_statement.dart';
import 'package:saldough/features/card/domain/entities/card_transaction.dart';
import 'package:saldough/features/card/domain/entities/credit_card.dart';
import 'package:saldough/features/cycle/data/repositories/cycle_repository_impl.dart';
import 'package:saldough/features/cycle/domain/entities/allocation.dart';
import 'package:saldough/features/cycle/domain/entities/budget_line.dart';
import 'package:saldough/features/cycle/domain/entities/budget_line_kind.dart';
import 'package:saldough/features/cycle/domain/entities/income_line.dart';
import 'package:saldough/features/cycle/domain/entities/investment_plan.dart';
import 'package:saldough/features/cycle/domain/entities/monthly_cycle.dart';
import 'package:saldough/features/cycle/domain/entities/roll_up_resolution.dart';
import 'package:saldough/features/cycle/domain/entities/roll_up_source.dart';
import 'package:saldough/features/cycle/domain/repositories/roll_up_resolver.dart';
import 'package:saldough/features/cycle/domain/usecases/calculate_cycle_totals.dart';
import 'package:saldough/features/grocery/data/grocery_roll_up_resolver.dart';
import 'package:saldough/features/grocery/data/repositories/grocery_plan_repository_impl.dart';
import 'package:saldough/features/grocery/domain/entities/grocery_item.dart';
import 'package:saldough/features/grocery/domain/entities/grocery_plan.dart';
import 'package:saldough/features/worklog/data/repositories/worklog_repository_impl.dart';
import 'package:saldough/features/worklog/domain/entities/billing_book.dart';
import 'package:saldough/features/worklog/domain/entities/work_log_entry.dart';
import 'package:saldough/shared/goal/data/goal_repository_impl.dart';
import 'package:saldough/shared/goal/domain/goal.dart';
import 'package:saldough/shared/income/data/income_source_repository_impl.dart';
import 'package:saldough/shared/income/domain/calculate_net_pay.dart';
import 'package:saldough/shared/income/domain/deduction_kind.dart';
import 'package:saldough/shared/income/domain/deduction_rule.dart';
import 'package:saldough/shared/income/domain/income_source.dart';
import 'package:saldough/shared/income/domain/income_source_kind.dart';

/// Rupiah penuh (seperti di JSON/spreadsheet) -> sen (satuan `int amount`
/// di seluruh entity Saldough). Satu tempat saja, supaya tidak ada kesalahan
/// kali-100 yang tersebar dan tidak konsisten.
int sen(int rupiah) => rupiah * 100;

/// Implementasi [KeyValueStorage] di atas `Box<String>` Hive murni-Dart.
/// Box ini, kalau `--db-path` menunjuk folder dokumen aplikasi sungguhan,
/// adalah box YANG SAMA yang dibaca `HiveKeyValueStorage` aplikasi (nama box
/// `saldough_kv`, key `'<namespace>_<name>'` persis StorageKey.value) — lihat
/// catatan masalah teknis di atas berkas ini.
final class _HiveBackedKeyValueStorage implements KeyValueStorage {
  _HiveBackedKeyValueStorage(this._box);

  final Box<String> _box;

  @override
  Future<String?> read(String key) async => _box.get(key);

  @override
  Future<void> write(String key, String value) async => _box.put(key, value);

  @override
  Future<void> remove(String key) async => _box.delete(key);

  @override
  Future<bool> contains(String key) async => _box.containsKey(key);

  @override
  Future<void> clear() async => _box.clear();
}

/// Menggabungkan [GroceryRollUpResolver] dan [CardRollUpResolver] di
/// belakang satu [RollUpResolver] — salinan `_CompositeRollUpResolver` privat
/// di `lib/core/di/src/root_module.dart`, dipakai ulang di sini karena
/// skrip ini bukan bagian DI aplikasi (lihat ADR-0009 soal pengecualian
/// isolasi fitur untuk skrip Fase 6 ini).
final class _CompositeRollUpResolver implements RollUpResolver {
  const _CompositeRollUpResolver({required this._grocery, required this._card});

  final RollUpResolver _grocery;
  final RollUpResolver _card;

  @override
  Future<RollUpResolution> resolve(RollUpSource source) {
    return switch (source) {
      GroceryRollUpSource() => _grocery.resolve(source),
      CardRollUpSource() => _card.resolve(source),
    };
  }
}

Future<void> main(List<String> args) async {
  final dbPath = _argValue(args, '--db-path');
  final dataPath = _argValue(args, '--data') ?? 'tool/seed_data.json';
  final dryRun = args.contains('--dry-run');

  if (dbPath == null) {
    stderr.writeln('''
Wajib isi --db-path.

  dart run tool/seed_import.dart --db-path <folder_data_app_sungguhan>
  dart run tool/seed_import.dart --db-path /tmp/coba --dry-run

Untuk data SUNGGUHAN: --db-path harus folder dokumen yang dipakai app nyata
di perangkat pemilik (Android: /data/data/<applicationId>/app_flutter,
iOS: <container>/Library/Application Support, desktop Linux: ~/Documents
atau XDG app-support dir) — bukan folder sembarang. Skrip ini membuka box
Hive `saldough_kv` di folder itu, box YANG SAMA yang dibaca aplikasi.
''');
    exitCode = 64;
    return;
  }

  final jsonFile = File(dataPath);
  if (!jsonFile.existsSync()) {
    stderr.writeln('Berkas seed tidak ditemukan: $dataPath');
    exitCode = 66;
    return;
  }
  final data = jsonDecode(jsonFile.readAsStringSync()) as Map<String, dynamic>;

  Directory(dbPath).createSync(recursive: true);
  Hive.init(dbPath);
  final box = await Hive.openBox<String>('saldough_kv');
  final storage = _HiveBackedKeyValueStorage(box);

  final incomeSourceRepo = IncomeSourceRepositoryImpl(storage: storage);
  final goalRepo = GoalRepositoryImpl(storage: storage);
  final creditCardRepo = CreditCardRepositoryImpl(storage: storage);
  final cardStatementRepo = CardStatementRepositoryImpl(storage: storage);
  final groceryPlanRepo = GroceryPlanRepositoryImpl(storage: storage);
  final worklogRepo = WorklogRepositoryImpl(storage: storage);
  final resolver = _CompositeRollUpResolver(
    grocery: GroceryRollUpResolver(repository: groceryPlanRepo),
    card: CardRollUpResolver(repository: cardStatementRepo),
  );
  final cycleRepo = CycleRepositoryImpl(
    storage: storage,
    resolver: resolver,
    incomeSourceRepository: incomeSourceRepo,
  );

  print('== T-6.3/6.4/6.5/6.6: menulis data seed ke $dbPath ==');

  // --- Income sources ---------------------------------------------------
  final sourcesJson = data['incomeSources'] as List<dynamic>;
  final incomeSourceById = <String, IncomeSource>{};
  for (final raw in sourcesJson) {
    final j = raw as Map<String, dynamic>;
    final kind = IncomeSourceKind.values.byName(j['kind'] as String);
    final source = IncomeSource(
      id: j['id'] as String,
      name: j['name'] as String,
      kind: kind,
      fixedAmount: j['fixedAmountRupiah'] == null ? null : sen(j['fixedAmountRupiah'] as int),
      hourlyRate: j['hourlyRateRupiah'] == null ? null : sen(j['hourlyRateRupiah'] as int),
      deductionRules: [
        for (final r in (j['deductionRules'] as List<dynamic>? ?? const []))
          DeductionRule(
            id: (r as Map<String, dynamic>)['id'] as String,
            label: r['label'] as String,
            kind: DeductionKind.values.byName(r['kind'] as String),
            value: r['value'] as int,
          ),
      ],
    );
    incomeSourceById[source.id] = source;
    final result = await incomeSourceRepo.saveSource(source);
    _assertRight(result, 'saveSource(${source.id})');
  }
  print('  income sources: ${incomeSourceById.length}');

  // --- Goals --------------------------------------------------------------
  final goalsJson = data['goals'] as List<dynamic>;
  for (final raw in goalsJson) {
    final j = raw as Map<String, dynamic>;
    final result = await goalRepo.saveGoal(
      Goal(id: j['id'] as String, name: j['name'] as String, openingBalance: sen(j['openingBalanceRupiah'] as int)),
    );
    _assertRight(result, 'saveGoal(${j['id']})');
  }
  print('  goals: ${goalsJson.length}');

  // --- Credit cards ---------------------------------------------------
  final cardsJson = data['cards'] as List<dynamic>;
  for (final raw in cardsJson) {
    final j = raw as Map<String, dynamic>;
    final result = await creditCardRepo.saveCard(
      CreditCard(id: j['id'] as String, name: j['name'] as String, statementDayOfMonth: j['statementDayOfMonth'] as int),
    );
    _assertRight(result, 'saveCard(${j['id']})');
  }
  print('  cards: ${cardsJson.length}');

  // --- Card statements --------------------------------------------------
  final cardStatementsJson = data['cardStatements'] as Map<String, dynamic>;
  var statementCount = 0;
  for (final entry in cardStatementsJson.entries) {
    final cardId = entry.key;
    final periods = entry.value as List<dynamic>;
    for (var i = 0; i < periods.length; i++) {
      final j = periods[i] as Map<String, dynamic>;
      if (j['skip'] == true) continue;
      final periodStart = DateTime.parse(j['periodStart'] as String);
      final periodEnd = DateTime.parse(j['periodEnd'] as String);
      final closed = j['closed'] as bool;
      final rawTransactions = j['transactions'] as List<dynamic>;
      final transactions = [
        for (var t = 0; t < rawTransactions.length; t++)
          CardTransaction(
            id: '$cardId-${periodStart.toIso8601String()}-$t',
            date: DateTime.parse((rawTransactions[t] as Map<String, dynamic>)['date'] as String),
            merchant: (rawTransactions[t] as Map<String, dynamic>)['merchant'] as String,
            amount: sen((rawTransactions[t] as Map<String, dynamic>)['amountRupiah'] as int),
          ),
      ];
      final statement = CardStatement(
        id: '${cardId}_${periodStart.toIso8601String()}',
        cardId: cardId,
        periodStart: periodStart,
        periodEnd: periodEnd,
        transactions: transactions,
        closedAt: closed ? periodEnd : null,
      );
      final result = await cardStatementRepo.saveStatement(statement);
      _assertRight(result, 'saveStatement(${statement.id})');
      statementCount++;
    }
  }
  print('  card statements: $statementCount');

  // --- Grocery plan (satu-satunya, live) --------------------------------
  final groceryJson = data['groceryPlan'] as Map<String, dynamic>;
  GroceryItem parseItem(Map<String, dynamic> j) => GroceryItem(
        id: j['id'] as String,
        name: j['name'] as String,
        quantity: j['quantity'] as int,
        unitPrice: sen(j['unitPriceRupiah'] as int),
        amountOverride: j['amountOverrideRupiah'] == null ? null : sen(j['amountOverrideRupiah'] as int),
      );
  final plan = GroceryPlan(
    weeksPerMonth: groceryJson['weeksPerMonth'] as int,
    weeklyItems: [for (final i in groceryJson['weeklyItems'] as List<dynamic>) parseItem(i as Map<String, dynamic>)],
    monthlyItems: [for (final i in groceryJson['monthlyItems'] as List<dynamic>) parseItem(i as Map<String, dynamic>)],
  );
  final groceryResult = await groceryPlanRepo.savePlan(plan);
  _assertRight(groceryResult, 'savePlan');
  print('  grocery plan: ${plan.weeklyItems.length} item mingguan, ${plan.monthlyItems.length} item bulanan');

  // --- Worklog (BillingBook) -------------------------------------------
  final worklogJson = data['worklog'] as Map<String, dynamic>;
  var bookCount = 0;
  for (final entry in worklogJson.entries) {
    final sourceId = entry.key;
    final source = incomeSourceById[sourceId]!;
    final books = entry.value as List<dynamic>;
    for (final raw in books) {
      final j = raw as Map<String, dynamic>;
      final entries = [
        for (final e in (j['entries'] as List<dynamic>))
          WorkLogEntry(
            id: '${j['id']}-${(e as Map<String, dynamic>)['date']}',
            date: DateTime.parse(e['date'] as String),
            hours: e['hours'] as int,
            startsNewBook: e['startsNewBook'] as bool? ?? false,
          ),
      ];
      final totalHours = entries.fold(0, (sum, e) => sum + e.hours);
      final explicitNet = j['netPayAmountRupiah'] == null ? null : sen(j['netPayAmountRupiah'] as int);
      final netPay = explicitNet ?? CalculateNetPay()(totalHours: totalHours, source: source).netPay;
      final book = BillingBook(
        id: j['id'] as String,
        sourceId: sourceId,
        startDate: DateTime.parse(j['startDate'] as String),
        endDate: DateTime.parse(j['endDate'] as String),
        entries: entries,
        netPayAmount: netPay,
        injectedCycleId: j['injectedCycleId'] as String?,
        injectedIncomeLineId: j['injectedCycleId'] == null ? null : 'inc-$sourceId',
      );
      final result = await worklogRepo.saveBook(book);
      _assertRight(result, 'saveBook(${book.id})');
      bookCount++;
    }
  }
  print('  worklog books: $bookCount');

  // --- Monthly cycles ----------------------------------------------------
  final cyclesJson = data['cycles'] as List<dynamic>;
  for (final raw in cyclesJson) {
    final j = raw as Map<String, dynamic>;
    final closed = j['closed'] as bool;
    final incomeLines = [
      for (final i in (j['incomeLines'] as List<dynamic>))
        IncomeLine(
          id: (i as Map<String, dynamic>)['id'] as String,
          label: i['label'] as String,
          amount: sen(i['amountRupiah'] as int),
          sourceId: i['sourceId'] as String?,
          isTemplate: i['isTemplate'] as bool? ?? false,
          needsReview: i['needsReview'] as bool? ?? false,
        ),
    ];
    final budgetLines = [
      for (final b in (j['budgetLines'] as List<dynamic>))
        _budgetLineFromJson(b as Map<String, dynamic>),
    ];
    final allocJson = j['investmentPlan'] as Map<String, dynamic>;
    final cycle = MonthlyCycle(
      id: j['id'] as String,
      incomeLines: incomeLines,
      budgetLines: budgetLines,
      investmentPlan: InvestmentPlan(
        returnDeposit: sen(allocJson['returnDepositRupiah'] as int),
        allocations: [
          for (final a in (allocJson['allocations'] as List<dynamic>))
            Allocation(goalId: (a as Map<String, dynamic>)['goalId'] as String, percentage: a['percentage'] as int),
        ],
      ),
      closedAt: closed ? DateTime.parse('${j['id']}-01').add(const Duration(days: 32)) : null,
    );
    final result = await cycleRepo.saveCycle(cycle);
    _assertRight(result, 'saveCycle(${cycle.id})');
  }
  print('  monthly cycles: ${cyclesJson.length}');

  // --- T-6.8: rekonsiliasi ------------------------------------------------
  print('\n== T-6.8: rekonsiliasi hasil hitung vs spreadsheet asli ==');
  var mismatches = 0;
  for (final raw in cyclesJson) {
    final j = raw as Map<String, dynamic>;
    final id = j['id'] as String;
    final expectedIncome = sen(_sumRupiah(j['incomeLines'] as List<dynamic>, 'amountRupiah'));
    final expectedBudget = sen(_sumBudgetRupiah(j['budgetLines'] as List<dynamic>));
    final cycleResult = await cycleRepo.getCycle(id);
    final cycle = cycleResult.fold((f) => throw StateError('getCycle($id) gagal: $f'), (c) => c!);
    final totals = CalculateCycleTotals()(cycle);
    final isOpen = j['closed'] == false;
    final incomeOk = totals.totalIncome == expectedIncome;
    // Untuk cycle TERBUKA, total budget LIVE boleh beda dari angka stale di
    // spreadsheet (lihat catatan "bulanan"/CC TOKPED di seed_data.json) -
    // bukan selisih yang perlu "diperbaiki". Untuk cycle TERTUTUP, rollup
    // dibekukan (ADR-0008) jadi harus cocok persis.
    final budgetOk = isOpen || totals.totalBudget == expectedBudget;
    final status = incomeOk && budgetOk ? 'OK' : 'SELISIH';
    if (!incomeOk || !budgetOk) mismatches++;
    print(
      '  $id [$status]${isOpen ? ' (terbuka - budget dihitung live, lihat catatan)' : ''}: '
      'income=${totals.totalIncome ~/ 100} (harap ${expectedIncome ~/ 100}), '
      'budget=${totals.totalBudget ~/ 100} (harap ${isOpen ? '-' : expectedBudget ~/ 100}), '
      'remainder=${totals.remainder ~/ 100}',
    );
    if (isOpen) {
      print('    (live) Bulanan & CC TOKPED dihitung ulang dari GroceryPlan/CardStatement terbuka, bukan dari angka stale di spreadsheet.');
    }
  }

  if (mismatches > 0) {
    stderr.writeln('\n$mismatches siklus TERTUTUP punya selisih terhadap spreadsheet - PERBAIKI sebelum dipakai nyata.');
    exitCode = 1;
  } else {
    print('\nSemua siklus tertutup cocok persis dengan spreadsheet. Siklus terbuka dihitung live sesuai desain.');
  }

  if (dryRun) {
    print('\n--dry-run: data di $dbPath bukan data asli, boleh dihapus.');
  }
}

BudgetLine _budgetLineFromJson(Map<String, dynamic> j) {
  final kindStr = j['kind'] as String;
  final kind = kindStr == 'rollUp' ? BudgetLineKind.rollUp : BudgetLineKind.manual;
  RollUpSource? source;
  if (kind == BudgetLineKind.rollUp) {
    final raw = j['rollUpSource'] as String;
    source = raw == 'grocery' ? RollUpSource.grocery : RollUpSource.card(raw.split(':')[1]);
  }
  return BudgetLine(
    id: j['id'] as String,
    label: j['label'] as String,
    amount: sen(j['amountRupiah'] as int),
    kind: kind,
    rollUpSource: source,
    isTemplate: j['isTemplate'] as bool? ?? false,
    needsReview: j['needsReview'] as bool? ?? false,
  );
}

int _sumRupiah(List<dynamic> lines, String field) =>
    lines.fold(0, (sum, l) => sum + ((l as Map<String, dynamic>)[field] as int));

int _sumBudgetRupiah(List<dynamic> lines) => _sumRupiah(lines, 'amountRupiah');

void _assertRight<L, R>(Either<L, R> result, String what) {
  result.fold(
    (failure) => throw StateError('$what gagal: $failure'),
    (_) => null,
  );
}

String? _argValue(List<String> args, String name) {
  final i = args.indexOf(name);
  if (i == -1 || i + 1 >= args.length) return null;
  return args[i + 1];
}
