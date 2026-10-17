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
import 'package:saldough/shared/wallet/wallet.dart';
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
      walletRepository: WalletRepositoryImpl(storage: storage),
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
      expect(
        find.descendant(of: find.byType(AppDonutChart), matching: find.text('Pengeluaran')),
        findsOneWidget,
        reason: 'label di tengah donat',
      );
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
      expect(find.descendant(of: find.byType(AppDonutChart), matching: find.text('Expenses')), findsOneWidget);
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

  group('tren enam periode (F6)', () {
    // Juni–Agustus hanya pengeluaran; September = contoh §10 (pemasukan Rp14.615.437,50).
    List<Transaction> history() => [
      expenseOn(DateTime(2026, 6, 5), 3600000, category: 'makan'),
      expenseOn(DateTime(2026, 7, 5), 3800000, category: 'makan'),
      expenseOn(DateTime(2026, 8, 5), 3900000, category: 'makan'),
    ];

    Future<void> openSeptember(WidgetTester tester) async {
      await pump(tester, now: DateTime(2026, 10, 10, 9));
      await tester.tap(find.byKey(const ValueKey('period-previous')));
      await tester.pumpAndSettle();
    }

    testWidgets('empat kolom (Jun–Sep, tak ada nol sebelum pencatatan); panel angka September; tanpa tautan', (
      tester,
    ) async {
      await seed([...history(), ...september2026()]);
      await openSeptember(tester);
      expect(find.byKey(const ValueKey('analysis-trend')), findsOneWidget);
      expect(find.text('6 bulan terakhir'), findsOneWidget);
      for (final i in [0, 1, 2, 3]) {
        expect(find.byKey(ValueKey('trend-col-$i')), findsOneWidget);
      }
      expect(find.byKey(const ValueKey('trend-col-4')), findsNothing);
      expect(find.text('Jun'), findsOneWidget);
      expect(find.text('+3,2 jt'), findsOneWidget, reason: 'selisih September bertanda');
      expect(find.text('−3,6 jt'), findsOneWidget, reason: 'selisih Juni negatif, tanpa merah');
      final readout = find.byKey(const ValueKey('analysis-readout'));
      expect(find.descendant(of: readout, matching: find.text('September 2026')), findsOneWidget);
      expect(find.descendant(of: readout, matching: find.text('−Rp11.420.700')), findsOneWidget);
      expect(find.byKey(const ValueKey('analysis-trend-jump')), findsNothing);
    });

    testWidgets('mengetuk kolom Juni hanya memilih; tautan "Lihat analisis Juni" memindah Analisis ke Juni', (tester) async {
      await seed([...history(), ...september2026()]);
      await openSeptember(tester);
      await tester.tap(find.byKey(const ValueKey('trend-col-0')));
      await tester.pump();
      expect(find.text('September 2026'), findsWidgets);
      expect(find.descendant(of: find.byKey(const ValueKey('analysis-readout')), matching: find.text('Juni 2026')), findsOneWidget);
      expect(find.text('Lihat analisis Juni'), findsOneWidget);
      expect(find.descendant(of: find.byType(AppPeriodStepper), matching: find.text('September 2026')), findsOneWidget);

      await tester.ensureVisible(find.byKey(const ValueKey('analysis-trend-jump')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('analysis-trend-jump')));
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.byType(AppPeriodStepper), matching: find.text('Juni 2026')), findsOneWidget);
      expect(find.byKey(const ValueKey('analysis-trend')), findsNothing, reason: 'Juni pencatatan pertama: satu kolom saja');
    });

    testWidgets('periode berjalan: keterangan "s.d. 10 Okt" dan selisih tanpa tanda', (tester) async {
      await seed([...history(), ...september2026(), expenseOn(DateTime(2026, 10, 4), 520000, category: 'makan')]);
      await pump(tester, now: DateTime(2026, 10, 10, 9));
      expect(find.text('s.d. 10 Okt'), findsOneWidget, reason: 'keterangan kolom');
      expect(find.text('520 rb'), findsOneWidget, reason: 'selisih Oktober tanpa − sampai periodenya selesai');
      expect(find.text('−520 rb'), findsNothing);
      final readout = find.byKey(const ValueKey('analysis-readout'));
      expect(find.descendant(of: readout, matching: find.text('Oktober 2026 · s.d. 10 Okt')), findsOneWidget);
    });

    testWidgets('bulan pertama pencatatan: satu periode, tren tidak tampil', (tester) async {
      await seed(september2026());
      await pump(tester);
      expect(find.byKey(const ValueKey('analysis-trend')), findsNothing);
    });

    testWidgets('periode tanpa pengeluaran tetap menampilkan tren', (tester) async {
      await seed([...history(), ...september2026()]);
      await pump(tester, now: DateTime(2026, 10, 10, 9));
      expect(find.byKey(const ValueKey('analysis-none')), findsOneWidget);
      expect(find.byKey(const ValueKey('analysis-trend')), findsOneWidget);
    });

    testWidgets('nominal disembunyikan: selisih "•••", panel Rp•••••, label sumbu hilang', (tester) async {
      AmountVisibility.notifier.value = true;
      await seed([...history(), ...september2026()]);
      await openSeptember(tester);
      expect(find.text('•••'), findsNWidgets(4));
      expect(find.text('+3,2 jt'), findsNothing);
      expect(find.text('15 jt'), findsNothing);
    });

    testWidgets('dompet disaring ikut ke tren; bahasa Inggris: "Last 6 months", "Net", "M"', (tester) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.en));
      await seed([...history(), ...september2026()]);
      await openSeptember(tester);
      expect(find.text('Last 6 months'), findsOneWidget);
      expect(find.text('Net'), findsOneWidget);
      expect(find.text('+3.2M'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('semantik kolom: "September 2026, pemasukan …, pengeluaran …, selisih +…"', (tester) async {
      final semantics = tester.ensureSemantics();
      await seed([...history(), ...september2026()]);
      await openSeptember(tester);
      final label = tester.getSemantics(find.byKey(const ValueKey('trend-col-3'))).label;
      expect(label, startsWith('September 2026, pemasukan Rp'));
      expect(label, contains('pengeluaran Rp11.420.700'));
      expect(label, contains('selisih +Rp'));
      semantics.dispose();
    });
  });

  group('dibanding biasanya (F2, B-6, B-7)', () {
    // Juni–Agustus dari FINANCIAL_ANALYSIS §10: rata-rata Makan Rp950.000, Belanja Rp2.820.000.
    List<Transaction> history() => [
      expenseOn(DateTime(2026, 6, 5), 900000, category: 'makan'),
      expenseOn(DateTime(2026, 7, 5), 950000, category: 'makan'),
      expenseOn(DateTime(2026, 8, 5), 1000000, category: 'makan'),
      expenseOn(DateTime(2026, 6, 6), 2700000, category: 'belanja'),
      expenseOn(DateTime(2026, 7, 6), 2850000, category: 'belanja'),
      expenseOn(DateTime(2026, 8, 6), 2910000, category: 'belanja'),
    ];

    // Hari ini 10 Okt: September sudah selesai, dibandingkan penuh.
    Future<void> openSeptember(WidgetTester tester) async {
      await pump(tester, now: DateTime(2026, 10, 10, 9));
      await tester.tap(find.byKey(const ValueKey('period-previous')));
      await tester.pumpAndSettle();
    }

    testWidgets('total di bawah donat dan sorotan Makan +Rp295.000; Belanja (+8,8%) tidak disorot', (tester) async {
      await seed([...history(), ...september2026()]);
      await openSeptember(tester);
      expect(find.textContaining('Rp7.650.700', findRichText: true), findsOneWidget);
      expect(find.textContaining('dibanding rata-rata 3 bulan', findRichText: true), findsOneWidget);
      expect(find.text('Makan Rp295.000 lebih tinggi dari rata-rata 3 bulan'), findsOneWidget);
      expect(find.textContaining('lebih tinggi dari', findRichText: true), findsOneWidget, reason: 'hanya satu sorotan');
    });

    testWidgets('memilih Makan: pembanding kategori; Cicilan (tanpa riwayat): baru bulan ini', (tester) async {
      await seed([...history(), ...september2026()]);
      await openSeptember(tester);
      await tester.tap(find.byKey(const ValueKey('analysis-row-Makan')));
      await tester.pump();
      expect(find.textContaining('Rp295.000 dibanding rata-rata 3 bulan', findRichText: true), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('analysis-row-Cicilan')));
      await tester.pump();
      expect(find.byKey(const ValueKey('analysis-new')), findsOneWidget);
      expect(find.text('baru bulan ini'), findsOneWidget);
      expect(find.byKey(const ValueKey('analysis-compare')), findsNothing);
    });

    testWidgets('bulan pertama pencatatan: tanpa pembanding dan tanpa sorotan', (tester) async {
      await seed(september2026());
      await openSeptember(tester);
      expect(find.byKey(const ValueKey('analysis-compare')), findsNothing);
      expect(find.byKey(const ValueKey('analysis-highlights')), findsNothing);
    });

    testWidgets('periode berjalan: dibanding s.d. tanggal yang sama (Makan +Rp180.000)', (tester) async {
      await seed([
        expenseOn(DateTime(2026, 7, 3), 300000, category: 'makan'),
        expenseOn(DateTime(2026, 7, 20), 650000, category: 'makan'),
        expenseOn(DateTime(2026, 8, 4), 340000, category: 'makan'),
        expenseOn(DateTime(2026, 8, 25), 660000, category: 'makan'),
        expenseOn(DateTime(2026, 9, 2), 380000, category: 'makan'),
        expenseOn(DateTime(2026, 9, 28), 865000, category: 'makan'),
        expenseOn(DateTime(2026, 10, 4), 520000, category: 'makan'),
      ]);
      await pump(tester, now: DateTime(2026, 10, 10, 9));
      expect(find.text('Makan Rp180.000 lebih tinggi dari rata-rata s.d. tanggal 10'), findsOneWidget);
      expect(find.textContaining('dibanding rata-rata s.d. tanggal 10', findRichText: true), findsOneWidget);
    });

    testWidgets('nominal disembunyikan: sorotan tanpa nominal', (tester) async {
      AmountVisibility.notifier.value = true;
      await seed([...history(), ...september2026()]);
      await openSeptember(tester);
      expect(find.text('Makan lebih tinggi dari rata-rata 3 bulan'), findsOneWidget);
    });

    testWidgets('bahasa Inggris: "higher than 3-month average"', (tester) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.en));
      await seed([...history(), ...september2026()]);
      await openSeptember(tester);
      expect(find.textContaining('higher than 3-month average'), findsOneWidget);
    });

    testWidgets('pembanding mengikuti jenis dan dompet: Pemasukan tanpa riwayat tidak membandingkan', (tester) async {
      await seed([...history(), ...september2026()]);
      await openSeptember(tester);
      await tester.tap(find.descendant(of: find.byKey(const ValueKey('analysis-kind')), matching: find.text('Pemasukan')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('analysis-compare')), findsNothing);
      expect(find.byKey(const ValueKey('analysis-highlights')), findsNothing);
    });
  });

  group('jenis dan dompet (F2, F3)', () {
    Future<void> seedWallets({bool two = true}) async {
      final wallets = WalletRepositoryImpl(storage: storage);
      for (final id in two ? ['bca', 'tabungan'] : ['bca']) {
        await wallets.saveWallet(
          Wallet(id: id, name: id.toUpperCase(), iconKey: 'walletBank', initialBalance: 0, currentBalance: 0),
        );
      }
    }

    testWidgets('Pemasukan: Gaji dan Freelance, nominal hijau, tengah donat "Pemasukan"; kembali ke Pengeluaran', (
      tester,
    ) async {
      await seedWallets();
      await seed(september2026());
      await pump(tester);
      expect(find.byKey(const ValueKey('analysis-kind')), findsOneWidget);
      await tester.tap(find.descendant(of: find.byKey(const ValueKey('analysis-kind')), matching: find.text('Pemasukan')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('analysis-row-Gaji')), findsOneWidget);
      expect(find.byKey(const ValueKey('analysis-row-Freelance')), findsOneWidget);
      expect(find.byKey(const ValueKey('analysis-row-Makan')), findsNothing);
      final center = tester.widget<AppMoneyText>(
        find.descendant(of: find.byType(AppDonutChart), matching: find.byType(AppMoneyText)),
      );
      expect(center.sen, 1461543750);
      expect(center.color, AppColors.light.positive);

      await tester.tap(find.descendant(of: find.byKey(const ValueKey('analysis-kind')), matching: find.text('Pengeluaran')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('analysis-row-Makan')), findsOneWidget);
      expect(find.byKey(const ValueKey('analysis-row-Gaji')), findsNothing);
    });

    testWidgets('periode tanpa pemasukan: pesan "Belum ada pemasukan di …" tanpa donat', (tester) async {
      await seedWallets();
      await seed([expenseOn(DateTime(2026, 9, 3), 10000, category: 'makan')]);
      await pump(tester);
      await tester.tap(find.descendant(of: find.byKey(const ValueKey('analysis-kind')), matching: find.text('Pemasukan')));
      await tester.pumpAndSettle();
      expect(find.text('Belum ada pemasukan di September.'), findsOneWidget);
      expect(find.byType(AppDonutChart), findsNothing);
      expect(find.byKey(const ValueKey('analysis-kind')), findsOneWidget, reason: 'pilihan jenis tetap bisa dibalik');
    });

    testWidgets('penyaring dompet: pilih BCA lalu kembali ke Semua dompet', (tester) async {
      await seedWallets();
      await seed([
        ...september2026(),
        expenseOn(DateTime(2026, 9, 9), 50000, category: 'makan', wallet: 'tabungan'),
      ]);
      await pump(tester);
      expect(find.text('Semua dompet'), findsOneWidget);
      expect(find.text('Dipindahkan antardompet'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('analysis-wallet')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('TABUNGAN').last);
      await tester.pumpAndSettle();
      expect(find.text('Rp50.000'), findsWidgets);
      expect(find.text('Transfer masuk'), findsOneWidget);
      expect(find.text('Transfer keluar'), findsOneWidget);
      expect(find.text('Dipindahkan antardompet'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('analysis-wallet')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Semua dompet').last);
      await tester.pumpAndSettle();
      expect(find.text('Dipindahkan antardompet'), findsOneWidget);
      expect(find.text('Rp11.470.700'), findsOneWidget);
    });

    testWidgets('satu dompet saja: penyaring dompet tidak tampil', (tester) async {
      await seedWallets(two: false);
      await seed(september2026());
      await pump(tester);
      expect(find.byKey(const ValueKey('analysis-wallet')), findsNothing);
      expect(find.byKey(const ValueKey('analysis-kind')), findsOneWidget);
    });

    testWidgets('Beri kategori meneruskan dompet yang dipilih ke Daftar tersaring', (tester) async {
      await seedWallets();
      await seed(september2026());
      TransactionFilterInput? opened;
      await pump(
        tester,
        onFiltered: (input) {
          opened = input;
          return input;
        },
      );
      await tester.tap(find.byKey(const ValueKey('analysis-wallet')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('BCA').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('analysis-row-Tanpa kategori')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('analysis-fix')));
      await tester.pumpAndSettle();
      expect(opened!.filter.walletId, 'bca');
      expect(opened!.filter.type, TransactionTypeFilter.expense);
    });

    testWidgets('bahasa Inggris dan 360dp: "Income", "All wallets", tanpa overflow', (tester) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.en));
      await seedWallets();
      await seed(september2026());
      await pump(tester);
      expect(find.text('All wallets'), findsOneWidget);
      await tester.tap(find.descendant(of: find.byKey(const ValueKey('analysis-kind')), matching: find.text('Income')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('analysis-row-Freelance')), findsOneWidget);
      expect(tester.takeException(), isNull);
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
        walletRepository: WalletRepositoryImpl(storage: storage),
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
