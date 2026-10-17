import 'package:dependencies/dependencies.dart';
import 'package:di/di.dart' show GetIt, ScopeProvider;
import 'package:failures/failures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/analysis/presentation/bloc/analysis_bloc.dart';
import 'package:saldough/features/analysis/presentation/widgets/analysis_view.dart';
import 'package:saldough/features/transaction/presentation/navigation/transaction_route_keys.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:state_management/state_management.dart';

import '../../../helpers/mocks.dart';
import '../analysis_fixtures.dart';

/// Layar Analisis satu periode (A2, A4): donat, legenda, kaki transfer, dan
/// keadaannya, di dua bahasa, 360dp, dan nominal tersembunyi.
/// Rute Daftar tersaring pengganti: mencatat input yang dibuka.
final class _FilteredStub extends FeatureRouteModule {
  const _FilteredStub(this.onFiltered);

  final TransactionFilterInput? Function(TransactionFilterInput input)? onFiltered;

  @override
  List<RouteNode> get routes => [
    RouteNode.typed<TransactionFilterInput>(
      key: TransactionRouteKeys.filtered,
      builder: (context, input) {
        onFiltered?.call(input);
        return const Scaffold(body: Text('daftar tersaring'));
      },
    ),
  ];
}

void main() {
  late InMemoryKeyValueStorage storage;
  late TransactionRepositoryImpl repository;
  late LedgerChanges ledger;

  setUp(() {
    storage = InMemoryKeyValueStorage();
    repository = TransactionRepositoryImpl(storage: storage);
    ledger = LedgerChanges();
  });

  tearDown(() {
    ActiveFinancialMonth.notifier.value = FinancialMonthSchedule.initial;
    AmountVisibility.notifier.value = false;
    LocaleSettings.setLocaleSync(AppLocale.id);
  });

  Future<void> seed(Iterable<Transaction> transactions) async {
    for (final transaction in transactions) {
      await repository.saveTransaction(transaction);
    }
  }

  Future<AnalysisBloc> pump(
    WidgetTester tester, {
    DateTime? now,
    TransactionRepository? source,
    double width = 360,
    TransactionFilterInput? Function(TransactionFilterInput input)? onFiltered,
  }) async {
    tester.view.physicalSize = Size(width, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final bloc = AnalysisBloc(
      transactionRepository: source ?? repository,
      ledgerChanges: ledger,
      categoryOf: analysisCategoryOf,
      now: () => now ?? DateTime(2026, 9, 30, 10),
    )..add(const AnalysisStarted());
    addTearDown(bloc.close);
    final container = GetIt.asNewInstance()
      ..registerSingleton<RouteRegistry>(RouteRegistry.fromModules([_FilteredStub(onFiltered)]));
    await tester.pumpWidget(
      ScopeProvider(
        container: container,
        child: MaterialApp(
          theme: PixelTheme.light,
          home: Scaffold(
            body: BlocProvider.value(value: bloc, child: const AnalysisView()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return bloc;
  }

  group('contoh §10, September 2026 (periode berjalan)', () {
    testWidgets('judul periode, total di tengah donat, legenda berurut dengan persen, kaki transfer', (tester) async {
      await seed(september2026());
      await pump(tester);
      expect(find.byKey(const ValueKey('period-title')), findsOneWidget);
      expect(find.text('September 2026'), findsOneWidget);
      expect(find.text('Pengeluaran'), findsOneWidget);
      expect(find.text('Rp11.420.700'), findsOneWidget, reason: 'total hanya di tengah donat');

      final names = ['Belanja', 'Cicilan', 'Tempat tinggal', 'Makan', 'Sedekah', 'Tanpa kategori'];
      final tops = [for (final n in names) tester.getTopLeft(find.text(n)).dy];
      expect(tops, [...tops]..sort(), reason: 'terbesar dulu, Tanpa kategori terakhir');
      expect(find.textContaining('Lainnya (3 kategori)', findRichText: true), findsOneWidget);
      for (final percent in ['27%', '26%', '17%', '11%', '7%', '12%', '1%']) {
        expect(find.text(percent), findsOneWidget, reason: percent);
      }
      expect(find.text('Rp3.068.500'), findsOneWidget);

      expect(find.byKey(const ValueKey('analysis-transfers')), findsOneWidget);
      expect(find.text('Dipindahkan antardompet'), findsOneWidget);
      expect(find.text('Tidak mengurangi total uangmu'), findsOneWidget);
      expect(find.text('Rp1.000.000'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Lainnya terbuka dan tertutup memperlihatkan anggotanya dengan persen sendiri', (tester) async {
      await seed(september2026());
      await pump(tester);
      expect(find.text('Tagihan'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('analysis-row-Lainnya (3 kategori)')));
      await tester.pump();
      expect(find.text('Tagihan'), findsOneWidget);
      expect(find.text('Langganan'), findsOneWidget);
      expect(find.text('Transportasi'), findsOneWidget);
      expect(find.text('5%'), findsOneWidget);
      expect(find.text('Rp550.000'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('analysis-row-Lainnya (3 kategori)')));
      await tester.pump();
      expect(find.text('Tagihan'), findsNothing);
    });

    testWidgets('donat dan legenda bersemantik: label ringkas dan baris "nama, persen, nominal"', (tester) async {
      final semantics = tester.ensureSemantics();
      await seed(september2026());
      await pump(tester);
      expect(find.bySemanticsLabel(RegExp('^Pengeluaran September: Belanja 27%, Cicilan 26%')), findsOneWidget);
      expect(find.bySemanticsLabel('Makan, 11%, Rp1.245.000'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('nominal disembunyikan: angka tertutup, persen tetap tampil (B-12)', (tester) async {
      AmountVisibility.notifier.value = true;
      await seed(september2026());
      await pump(tester);
      expect(find.text('Rp11.420.700'), findsNothing);
      expect(find.text('Rp•••••'), findsWidgets);
      expect(find.text('27%'), findsOneWidget);
    });

    testWidgets('bahasa Inggris: label dan kaki kartu mengikuti, tanpa overflow di 360dp', (tester) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.en));
      await seed(september2026());
      await pump(tester);
      expect(find.text('Expenses'), findsOneWidget);
      expect(find.textContaining('Others (3 categories)', findRichText: true), findsOneWidget);
      expect(find.text('Uncategorized'), findsOneWidget);
      expect(find.text('Moved between wallets'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('memilih kategori (F1, F5)', () {
    Finder row(String name) => find.byKey(ValueKey('analysis-row-$name'));

    testWidgets('mengetuk baris: tengah donat berganti nama, nominal, dan "11% dari pengeluaran"; ketuk lagi kembali', (
      tester,
    ) async {
      await seed(september2026());
      await pump(tester);
      expect(find.text('Rp11.420.700'), findsOneWidget);
      expect(find.text('11% dari pengeluaran'), findsNothing);

      await tester.tap(row('Makan'));
      await tester.pump();
      expect(find.text('11% dari pengeluaran'), findsOneWidget);
      expect(find.text('Rp1.245.000'), findsNWidgets(2), reason: 'tengah donat + baris legenda');
      expect(find.text('Rp11.420.700'), findsNothing, reason: 'total diganti kategori terpilih');
      expect(find.byKey(const ValueKey('analysis-fix')), findsNothing, reason: 'Beri kategori hanya untuk Tanpa kategori');

      await tester.tap(row('Makan'));
      await tester.pump();
      expect(find.text('Rp11.420.700'), findsOneWidget);
      expect(find.text('11% dari pengeluaran'), findsNothing);
    });

    testWidgets('baris terpilih bersemantik "terpilih"; mengetuk irisan donat memilih barisnya', (tester) async {
      final semantics = tester.ensureSemantics();
      await seed(september2026());
      await pump(tester);
      await tester.tap(row('Belanja'));
      await tester.pump();
      expect(
        tester.getSemantics(row('Belanja')),
        matchesSemantics(
          label: 'Belanja, 27%, Rp3.068.500',
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
          hasTapAction: true,
        ),
      );
      // Irisan pertama (Belanja 27%) di jam 12–jam 3: titik jam 2 pada cincin.
      final origin = tester.getTopLeft(find.byType(AppDonutChart));
      await tester.tapAt(origin + const Offset(108 + 70, 108 - 66));
      await tester.pump();
      expect(find.text('27% dari pengeluaran'), findsNothing, reason: 'ketukan kedua pada irisan yang sama membatalkan');
      semantics.dispose();
    });

    testWidgets('Lainnya terpilih: tengah menyebut gabungannya dan anggotanya terbuka', (tester) async {
      await seed(september2026());
      await pump(tester);
      await tester.tap(row('Lainnya (3 kategori)'));
      await tester.pump();
      expect(find.text('12% dari pengeluaran'), findsOneWidget);
      expect(find.text('Tagihan'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('analysis-row-child-Tagihan')));
      await tester.pump();
      expect(find.text('5% dari pengeluaran'), findsOneWidget, reason: 'anggota dipilih dengan persennya sendiri');
    });

    testWidgets('Tanpa kategori terpilih memunculkan Beri kategori yang membuka Daftar tersaring periode itu', (tester) async {
      await seed(september2026());
      TransactionFilterInput? opened;
      await pump(
        tester,
        onFiltered: (input) {
          opened = input;
          return input;
        },
      );
      await tester.tap(row('Tanpa kategori'));
      await tester.pump();
      expect(find.text('1% dari pengeluaran'), findsOneWidget);
      expect(find.text('Rp120.000'), findsNWidgets(2));
      await tester.tap(find.byKey(const ValueKey('analysis-fix')));
      await tester.pumpAndSettle();

      expect(opened, isNotNull);
      expect(opened!.title, 'Tanpa kategori');
      expect(opened!.subtitle, 'September 2026');
      expect(opened!.filter.uncategorized, isTrue);
      expect(opened!.filter.type, TransactionTypeFilter.expense);
      expect(opened!.filter.from, DateTime(2026, 9));
      expect(opened!.filter.until, DateTime(2026, 10));
      expect(find.text('daftar tersaring'), findsOneWidget);
    });

    testWidgets('bahasa Inggris: "11% of expenses" dan Add category', (tester) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.en));
      await seed(september2026());
      await pump(tester);
      await tester.tap(row('Makan'));
      await tester.pump();
      expect(find.text('11% of expenses'), findsOneWidget);
      await tester.tap(row('Uncategorized'));
      await tester.pump();
      expect(find.text('Add category'), findsOneWidget);
    });
  });

  group('periode dan keadaan', () {
    testWidgets('mengetuk ‹ pindah ke periode sebelumnya; periode berjalan menonaktifkan ›', (tester) async {
      await seed([...september2026(), expenseOn(DateTime(2026, 8, 12), 700000, category: 'makan')]);
      await pump(tester);
      expect(tester.widget<AppIconButton>(find.byKey(const ValueKey('period-next'))).onPressed, isNull);
      await tester.tap(find.byKey(const ValueKey('period-previous')));
      await tester.pumpAndSettle();
      expect(find.text('Agustus 2026'), findsOneWidget);
      expect(find.text('Rp700.000'), findsWidgets);
      expect(tester.widget<AppIconButton>(find.byKey(const ValueKey('period-next'))).onPressed, isNotNull);
      await tester.tap(find.byKey(const ValueKey('period-next')));
      await tester.pumpAndSettle();
      expect(find.text('September 2026'), findsOneWidget);
    });

    testWidgets('periode tanpa pengeluaran: pesan netral, pemilih periode tetap ada', (tester) async {
      await seed([expenseOn(DateTime(2026, 8, 12), 700000, category: 'makan')]);
      await pump(tester);
      expect(find.byKey(const ValueKey('analysis-none')), findsOneWidget);
      expect(find.text('Belum ada pengeluaran di September.'), findsOneWidget);
      expect(find.byKey(const ValueKey('period-previous')), findsOneWidget);
    });

    testWidgets('belum ada transaksi sama sekali: keadaan kosong dengan Catat transaksi', (tester) async {
      await pump(tester);
      expect(find.text('Belum ada yang bisa dianalisis'), findsOneWidget);
      expect(find.text('Catat transaksi dan lihat ke mana uangmu pergi.'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Catat transaksi'), findsOneWidget);
    });

    testWidgets('gagal memuat: pesan galat netral tanpa tombol, tarik ke bawah untuk mencoba lagi', (tester) async {
      final failing = MockTransactionRepository();
      when(failing.listAvailableMonths).thenAnswer(
        (_) async => left(const SystemFailure(code: FailureCode('TEST_FORCED_FAILURE'), message: 'dipaksa gagal')),
      );
      await pump(tester, source: failing);
      expect(find.byKey(const ValueKey('analysis-error')), findsOneWidget);
      expect(find.text('Analisis gagal dimuat. Tarik ke bawah untuk mencoba lagi.'), findsOneWidget);
      expect(find.byType(AppButton), findsNothing);
    });

    testWidgets('periode peralihan 1 – 24 Okt: rentang dan penanda netral dengan panjangnya', (tester) async {
      await seed([expenseOn(DateTime(2026, 10, 3), 520000, category: 'makan'), expenseOn(DateTime(2026, 9, 3), 1000, category: 'makan')]);
      ActiveFinancialMonth.notifier.value = FinancialMonthSchedule.initial.changedOn(
        DateTime(2026, 10, 10),
        const FinancialMonthStart.day(25),
      );
      await pump(tester, now: DateTime(2026, 10, 10, 9));
      expect(find.text('1\u00A0–\u00A024\u00A0Okt'), findsOneWidget);
      expect(find.byType(AppPeriodTag), findsOneWidget);
      expect(find.text('Periode peralihan · 24 hari'), findsOneWidget);
    });

    testWidgets('memuat: kerangka berbentuk isi aslinya sebelum data tiba', (tester) async {
      await seed(september2026());
      final bloc = AnalysisBloc(
        transactionRepository: repository,
        ledgerChanges: ledger,
        categoryOf: analysisCategoryOf,
        now: () => DateTime(2026, 9, 30, 10),
      );
      addTearDown(bloc.close);
      await tester.pumpWidget(
        MaterialApp(
          theme: PixelTheme.light,
          home: Scaffold(body: BlocProvider.value(value: bloc, child: const AnalysisView())),
        ),
      );
      expect(find.byKey(const ValueKey('analysis-loading')), findsOneWidget);
      bloc.add(const AnalysisStarted());
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('analysis-loading')), findsNothing);
    });
  });
}
