import 'package:di/di.dart' show GetIt, ScopeProvider;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/analysis/presentation/navigation/analysis_route_keys.dart';
import 'package:saldough/features/analysis/presentation/pages/category_detail_page.dart';
import 'package:saldough/features/transaction/presentation/navigation/transaction_route_keys.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Rincian kategori (T-19.5): angka contoh §10 (Makan September), tren dengan
/// garis rata-rata, transaksi, dan tautan ke Daftar tersaring.
void main() {
  late InMemoryKeyValueStorage storage;
  late TransactionRepositoryImpl repository;
  TransactionFilterInput? filtered;

  int rp(int rupiah) => rupiah * 100;
  var next = 0;
  ExpenseTransaction spend(DateTime date, int rupiah, String category, {String note = ''}) => ExpenseTransaction(
    id: 'e${next++}',
    date: date,
    amount: rp(rupiah),
    note: note,
    walletId: 'bca',
    categoryId: category,
  );

  const makan = Category(id: 'makan', kind: CategoryKind.expense, name: 'Makan');
  const sehat = Category(id: 'sehat', kind: CategoryKind.expense, name: 'Kesehatan', isArchived: true);

  setUp(() async {
    storage = InMemoryKeyValueStorage();
    repository = TransactionRepositoryImpl(storage: storage);
    filtered = null;
    ActiveCategories.notifier.value = [makan, sehat];
    await WalletRepositoryImpl(storage: storage).saveWallet(
      const Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 0, currentBalance: 0),
    );
  });

  tearDown(() {
    ActiveCategories.notifier.value = const [];
    ActiveFinancialMonth.notifier.value = FinancialMonthSchedule.initial;
    AmountVisibility.notifier.value = false;
    LocaleSettings.setLocaleSync(AppLocale.id);
  });

  Future<void> seed(Iterable<Transaction> transactions) async {
    for (final t in transactions) {
      await repository.saveTransaction(t);
    }
  }

  Future<void> pump(
    WidgetTester tester,
    CategoryDetailInput input, {
    double width = 360,
    TextScaler scaler = TextScaler.noScaling,
  }) async {
    tester.view.physicalSize = Size(width, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = GetIt.asNewInstance()
      ..registerSingleton<TransactionRepository>(repository)
      ..registerSingleton<WalletRepository>(WalletRepositoryImpl(storage: storage))
      ..registerSingleton<LedgerChanges>(LedgerChanges())
      ..registerSingleton<RouteRegistry>(
        RouteRegistry.fromModules([
          _Stubs(onFiltered: (i) => filtered = i),
        ]),
      );
    await tester.pumpWidget(
      ScopeProvider(
        container: container,
        child: MaterialApp(
          theme: PixelTheme.light,
          builder: (context, child) =>
              MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: scaler), child: child!),
          home: CategoryDetailPage(input: input),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // Makan: Jun 1, Jul 2, Agt 2, Sep 2 (§10, B-17); pengeluaran September lain: Rp10.175.700.
  List<Transaction> data() => [
    spend(DateTime(2026, 6, 5), 900000, 'makan'),
    spend(DateTime(2026, 7, 5), 450000, 'makan'),
    spend(DateTime(2026, 7, 20), 500000, 'makan'),
    spend(DateTime(2026, 8, 4), 400000, 'makan'),
    spend(DateTime(2026, 8, 25), 600000, 'makan'),
    spend(DateTime(2026, 9, 5), 380000, 'makan', note: 'Makan bersama kantor'),
    spend(DateTime(2026, 9, 20), 865000, 'makan', note: 'Makan malam keluarga'),
    spend(DateTime(2026, 9, 10), 10175700, 'sehat'),
  ];

  CategoryDetailInput september({String category = 'makan'}) =>
      CategoryDetailInput(categoryId: category, kind: CategoryKind.expense, periodStart: DateTime(2026, 9, 15));

  testWidgets('Makan September: total, 11%, pembanding, frekuensi, biasanya (contoh §10, B-17)', (tester) async {
    await seed(data());
    await pump(tester, september());
    final summary = find.byKey(const ValueKey('category-summary'));
    expect(find.descendant(of: summary, matching: find.text('September 2026')), findsOneWidget);
    expect(find.descendant(of: summary, matching: find.text('Rp12.450.000')), findsNothing);
    expect(find.descendant(of: summary, matching: find.text('Rp1.245.000')), findsOneWidget);
    expect(find.descendant(of: summary, matching: find.text('11% dari pengeluaran')), findsOneWidget);
    expect(find.textContaining('Rp295.000 dibanding rata-rata 3 bulan', findRichText: true), findsOneWidget);
    expect(find.text('2 transaksi · rata-rata Rp622.500 per transaksi'), findsOneWidget);
    expect(find.text('biasanya 1,7 transaksi · Rp570.000'), findsOneWidget);
    expect(find.byKey(const ValueKey('category-archived')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tren satu besaran: empat kolom, garis rata-rata 3 bulan, panel "di atas rata-rata"', (tester) async {
    await seed(data());
    await pump(tester, september());
    for (final i in [0, 1, 2, 3]) {
      expect(find.byKey(ValueKey('trend-col-$i')), findsOneWidget);
    }
    expect(find.text('rata-rata 3 bulan'), findsOneWidget, reason: 'label garis');
    final readout = find.byKey(const ValueKey('category-readout'));
    expect(find.descendant(of: readout, matching: find.text('September 2026')), findsOneWidget);
    expect(find.textContaining('Rp295.000 di atas rata-rata', findRichText: true), findsOneWidget);
    expect(find.byKey(const ValueKey('category-trend-jump')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('trend-col-0')));
    await tester.pump();
    expect(find.descendant(of: readout, matching: find.text('Juni 2026')), findsOneWidget);
    expect(find.textContaining('Rp50.000 di bawah rata-rata', findRichText: true), findsOneWidget);
    expect(find.text('Lihat analisis Juni'), findsOneWidget);
  });

  testWidgets('transaksi periode ini per hari, terbaru dulu; Lihat semua transaksi membuka Daftar tersaring sama', (
    tester,
  ) async {
    await seed(data());
    await pump(tester, september());
    expect(find.text('Makan malam keluarga'), findsOneWidget);
    expect(find.text('Makan bersama kantor'), findsOneWidget);
    final top = tester.getTopLeft(find.text('Makan malam keluarga')).dy;
    expect(top, lessThan(tester.getTopLeft(find.text('Makan bersama kantor')).dy), reason: 'terbaru dulu');

    await tester.ensureVisible(find.byKey(const ValueKey('category-see-all')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('category-see-all')));
    await tester.pumpAndSettle();
    expect(filtered!.title, 'Makan');
    expect(filtered!.subtitle, 'September 2026');
    expect(filtered!.filter.categoryId, 'makan');
    expect(filtered!.filter.from, DateTime(2026, 9));
    expect(filtered!.filter.until, DateTime(2026, 10));
    expect(filtered!.filter.type, TransactionTypeFilter.expense);
  });

  testWidgets('paling banyak 20 transaksi; sisanya lewat Lihat semua transaksi', (tester) async {
    await seed([
      spend(DateTime(2026, 6, 5), 1, 'makan'),
      for (var i = 0; i < 25; i++) spend(DateTime(2026, 9, 1 + i % 28, 8 + i % 10), 1000 + i, 'makan', note: 'tx$i'),
    ]);
    await pump(tester, september());
    expect(find.text('20 transaksi terbaru'), findsOneWidget);
  });

  testWidgets('kategori baru bulan ini: badge, tanpa garis rata-rata dan tanpa "biasanya"', (tester) async {
    await seed([spend(DateTime(2026, 6, 5), 900000, 'makan'), spend(DateTime(2026, 9, 21), 350000, 'sehat')]);
    await pump(tester, september(category: 'sehat'));
    expect(find.byKey(const ValueKey('analysis-new')), findsOneWidget);
    expect(find.text('baru bulan ini'), findsOneWidget);
    expect(find.byKey(const ValueKey('category-usual')), findsNothing);
    expect(find.text('rata-rata 3 bulan'), findsNothing, reason: 'tanpa garis acuan');
    expect(find.byKey(const ValueKey('category-archived')), findsOneWidget, reason: 'kategori diarsipkan ditandai');
    expect(find.text('1 transaksi · rata-rata Rp350.000 per transaksi'), findsOneWidget);
  });

  testWidgets('periode berjalan: kolom "s.d.", panel tanpa pembanding; nominal tersembunyi menutup angka', (tester) async {
    AmountVisibility.notifier.value = true;
    await seed(data());
    final now = DateTime.now();
    await seed([spend(DateTime(now.year, now.month), 100000, 'makan')]);
    await pump(
      tester,
      CategoryDetailInput(categoryId: 'makan', kind: CategoryKind.expense, periodStart: now),
    );
    expect(find.text('Rp•••••'), findsWidgets);
    expect(find.textContaining('Rp295.000', findRichText: true), findsNothing);
    expect(find.textContaining('s.d.'), findsWidgets);
    expect(find.textContaining('di atas rata-rata', findRichText: true), findsNothing);
  });

  testWidgets('bahasa Inggris dan teks 2x di 360dp: tanpa overflow', (tester) async {
    await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.en));
    await seed(data());
    await pump(tester, september(), scaler: const TextScaler.linear(2));
    expect(find.textContaining('2 transactions · '), findsOneWidget);
    expect(find.textContaining('usually 1.7 transactions · '), findsOneWidget);
    expect(find.text('See all transactions'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

final class _Stubs extends FeatureRouteModule {
  const _Stubs({required this.onFiltered});

  final void Function(TransactionFilterInput input) onFiltered;

  @override
  List<RouteNode> get routes => [
    RouteNode.typed<TransactionFilterInput>(
      key: TransactionRouteKeys.filtered,
      builder: (context, input) {
        onFiltered(input);
        return const Scaffold(body: Text('daftar tersaring'));
      },
    ),
    RouteNode.typed<TransactionDetailInput>(
      key: TransactionRouteKeys.detail,
      builder: (context, input) => const Scaffold(body: Text('rincian transaksi')),
    ),
    RouteNode.typed<AnalysisInput>(
      key: AnalysisRouteKeys.open,
      builder: (context, input) => const Scaffold(body: Text('analisis')),
    ),
  ];
}
