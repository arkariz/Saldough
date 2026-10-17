import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/features/analysis/domain/period_summary.dart';
import 'package:saldough/features/analysis/presentation/bloc/analysis_bloc.dart';
import 'package:saldough/features/analysis/presentation/bloc/analysis_state.dart';
import 'package:saldough/features/analysis/presentation/navigation/analysis_route_keys.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

import '../../../../helpers/mocks.dart';
import '../../analysis_fixtures.dart';

/// Bloc Analisis (T-19.1/T-19.4): periode berjalan, melangkah mundur dan maju,
/// segar lewat LedgerChanges dan awal bulan keuangan, galat pemuatan.
void main() {
  late InMemoryKeyValueStorage storage;
  late TransactionRepositoryImpl repository;
  late LedgerChanges ledger;
  late List<AnalysisBloc> blocs;
  // Hari ini 10 Okt 2026: periode berjalan Oktober, September sudah selesai.
  final today = DateTime(2026, 10, 10, 9);

  setUp(() {
    storage = InMemoryKeyValueStorage();
    repository = TransactionRepositoryImpl(storage: storage);
    ledger = LedgerChanges();
    blocs = [];
  });

  tearDown(() async {
    HistoryPeriod.reset();
    ActiveFinancialMonth.notifier.value = FinancialMonthSchedule.initial;
    for (final bloc in blocs) {
      await bloc.close();
    }
  });

  AnalysisBloc create({TransactionRepository? source, bool shares = false}) {
    final bloc = AnalysisBloc(
      transactionRepository: source ?? repository,
      walletRepository: WalletRepositoryImpl(storage: storage),
      ledgerChanges: ledger,
      categoryOf: analysisCategoryOf,
      now: () => today,
      sharesHistoryPeriod: shares,
    );
    blocs.add(bloc);
    return bloc;
  }

  Future<void> seed(Iterable<Transaction> transactions) async {
    for (final transaction in transactions) {
      await repository.saveTransaction(transaction);
    }
  }

  Future<AnalysisState> loaded(
    AnalysisBloc bloc, [
    AnalysisEvent event = const AnalysisStarted(),
  ]) {
    bloc.add(event);
    return bloc.stream.firstWhere((s) => !s.isLoading);
  }

  group('periode dibagi dengan Daftar (T-19.10)', () {
    test(
      'mulai di periode yang dipilih Daftar; berpindah periode memperbarui HistoryPeriod; yang bukan segmen tidak',
      () async {
        await seed([...september2026(), expenseOn(DateTime(2026, 10, 3), 520000, category: 'makan')]);
        HistoryPeriod.notifier.value = DateTime(2026, 9);
        final shared = create(shares: true);
        final state = await loaded(shared);
        expect(state.period.label, 'September 2026');

        HistoryPeriod.reset();
        final alone = create();
        final separate = await loaded(alone);
        expect(separate.period.label, 'Oktober 2026', reason: 'bukan segmen Riwayat: periodenya sendiri');
        alone.add(const AnalysisPeriodStepped(forward: false));
        await alone.stream.firstWhere((s) => s.period.label == 'September 2026' && !s.isLoading);
        expect(HistoryPeriod.anchor, isNull, reason: 'tidak menulis HistoryPeriod');
      },
    );

    test('mundur di Analisis menulis HistoryPeriod; perubahan dari Daftar dibaca dan memperbarui periode', () async {
      await seed([...september2026(), expenseOn(DateTime(2026, 10, 3), 520000, category: 'makan')]);
      final bloc = create(shares: true);
      await loaded(bloc);
      bloc.add(const AnalysisPeriodStepped(forward: false));
      await bloc.stream.firstWhere((s) => s.period.label == 'September 2026' && !s.isLoading);
      expect(HistoryPeriod.anchor, DateTime(2026, 9));

      HistoryPeriod.reset();
      final back = await bloc.stream.firstWhere((s) => s.period.label == 'Oktober 2026' && !s.isLoading);
      expect(back.isCurrent, isTrue);
    });
  });

  group('analitik (T-19.9)', () {
    late List<AnalyticsEvent> events;

    setUp(() {
      events = [];
      AppAnalytics.debugSink = events.add;
      addTearDown(() => AppAnalytics.debugSink = null);
    });

    List<AnalyticsEvent> named(String name) => events.where((e) => e.name == name).toList();

    Future<void> history() async {
      await seed([
        expenseOn(DateTime(2026, 6, 5), 900000, category: 'makan'),
        expenseOn(DateTime(2026, 7, 5), 950000, category: 'makan'),
        expenseOn(DateTime(2026, 8, 5), 1000000, category: 'makan'),
        ...september2026(),
      ]);
    }

    test('analysis_viewed sekali per layar dengan pintu, jenis, dan peralihan; segar tidak menggandakan', () async {
      await history();
      final bloc = create();
      await loaded(bloc, AnalysisStarted(periodStart: DateTime(2026, 9, 15), source: AnalysisSource.lookback));
      expect(named('analysis_viewed').single.parameters, {
        'source': 'lookback',
        'kind': 'expense',
        'transition': 'false',
      });
      ledger.notifyChanged();
      bloc
        ..add(const AnalysisRefreshed())
        ..add(const AnalysisPeriodStepped(forward: false));
      await bloc.stream.firstWhere((s) => s.period.label == 'Agustus 2026' && !s.isLoading);
      expect(named('analysis_viewed'), hasLength(1));
    });

    test('pintu Beranda dan Riwayat dicatat apa adanya', () async {
      await history();
      for (final source in [AnalysisSource.home, AnalysisSource.history]) {
        events.clear();
        await loaded(create(), AnalysisStarted(source: source));
        expect(named('analysis_viewed').single.parameters['source'], source.name);
      }
    });

    test('analysis_highlights_shown sekali per periode yang dibuka, bukan per ganti jenis atau segar', () async {
      await history();
      final bloc = create();
      await loaded(bloc, AnalysisStarted(periodStart: DateTime(2026, 9, 15)));
      expect(named('analysis_highlights_shown').single.parameters, {'count': 1});

      bloc
        ..add(const AnalysisKindChanged(CategoryKind.income))
        ..add(const AnalysisRefreshed());
      await bloc.stream.firstWhere((s) => s.kind == CategoryKind.income);
      expect(named('analysis_highlights_shown'), hasLength(1));

      bloc.add(const AnalysisPeriodStepped(forward: false));
      await bloc.stream.firstWhere((s) => s.period.label == 'Agustus 2026' && !s.isLoading);
      final shown = named('analysis_highlights_shown');
      expect(shown, hasLength(2));
      expect(shown.last.parameters['count'], isA<int>());
    });

    test('periode berubah lewat panah atau tautan tren, jenis, dan dompet dicatat tanpa nominal', () async {
      await history();
      final wallets = WalletRepositoryImpl(storage: storage);
      await wallets.saveWallet(
        const Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 0, currentBalance: 0),
      );
      final bloc = create();
      await loaded(bloc, AnalysisStarted(periodStart: DateTime(2026, 9, 15)));

      bloc.add(const AnalysisPeriodStepped(forward: false));
      await bloc.stream.firstWhere((s) => s.period.label == 'Agustus 2026' && !s.isLoading);
      bloc.add(AnalysisPeriodJumped(DateTime(2026, 7)));
      await bloc.stream.firstWhere((s) => s.period.label == 'Juli 2026' && !s.isLoading);
      expect(named('analysis_period_changed').map((e) => e.parameters['via']), ['stepper', 'trend']);

      bloc.add(const AnalysisKindChanged(CategoryKind.income));
      await bloc.stream.firstWhere((s) => s.kind == CategoryKind.income);
      expect(named('analysis_kind_switched').single.parameters, {'kind': 'income'});

      bloc.add(const AnalysisWalletChanged('bca'));
      await bloc.stream.firstWhere((s) => s.walletId == 'bca');
      bloc.add(const AnalysisWalletChanged(null));
      await bloc.stream.firstWhere((s) => s.walletId == null);
      expect(named('analysis_wallet_filtered').map((e) => e.parameters['filtered']), ['true', 'false']);

      for (final e in events) {
        for (final value in e.parameters.values) {
          expect('$value', isNot(contains('Rp')));
          expect('$value', isNot(contains('Makan')));
        }
      }
    });

    test('ikut periode Daftar tidak dianggap pindah periode oleh pengguna', () async {
      await history();
      final bloc = create(shares: true);
      await loaded(bloc);
      HistoryPeriod.notifier.value = DateTime(2026, 8);
      await bloc.stream.firstWhere((s) => s.period.label == 'Agustus 2026' && !s.isLoading);
      expect(named('analysis_period_changed'), isEmpty);
    });
  });

  group('tren (F6)', () {
    test(
      'enam periode berakhir di periode yang dilihat; kolom terpilih tidak memindah periode; lompat memindah',
      () async {
        await seed([
          expenseOn(DateTime(2026, 6, 5), 100000, category: 'makan'),
          expenseOn(DateTime(2026, 7, 5), 100000, category: 'makan'),
          ...september2026(),
        ]);
        final bloc = create();
        final state = await loaded(
          bloc,
          AnalysisStarted(periodStart: DateTime(2026, 9, 15)),
        );
        expect(state.trend.map((p) => p.period.start), [
          DateTime(2026, 6),
          DateTime(2026, 7),
          DateTime(2026, 8),
          DateTime(2026, 9),
        ]);
        expect(state.trendIndex, 3);

        bloc.add(const AnalysisTrendSelected(1));
        final picked = await bloc.stream.firstWhere(
          (s) => s.trendSelected == 1,
        );
        expect(
          picked.period.label,
          'September 2026',
          reason: 'memilih tidak berpindah',
        );
        expect(picked.trendIndex, 1);

        bloc.add(AnalysisPeriodJumped(picked.trend[1].period.start));
        final jumped = await bloc.stream.firstWhere(
          (s) => s.period.label == 'Juli 2026' && !s.isLoading,
        );
        expect(jumped.trendSelected, isNull);
        expect(jumped.trend.last.period.label, 'Juli 2026');
        expect(jumped.trend.length, 2);
      },
    );

    test(
      'penyaring dompet menghitung ulang tren tanpa membaca ulang',
      () async {
        await seed([
          ...september2026(),
          expenseOn(
            DateTime(2026, 8, 3),
            70000,
            category: 'makan',
            wallet: 'tabungan',
          ),
        ]);
        final bloc = create();
        await loaded(bloc, AnalysisStarted(periodStart: DateTime(2026, 9, 15)));
        bloc.add(const AnalysisWalletChanged('tabungan'));
        final state = await bloc.stream.firstWhere(
          (s) => s.walletId == 'tabungan',
        );
        expect(state.trend.map((p) => p.expense), [rp(70000), 0]);
      },
    );
  });

  group('pembanding (B-6)', () {
    test(
      'September dengan Jun–Agt: 3 bulan pembanding, sorotan Makan; periode peralihan tanpa pembanding',
      () async {
        await seed([
          expenseOn(DateTime(2026, 6, 5), 900000, category: 'makan'),
          expenseOn(DateTime(2026, 7, 5), 950000, category: 'makan'),
          expenseOn(DateTime(2026, 8, 5), 1000000, category: 'makan'),
          ...september2026(),
        ]);
        final bloc = create();
        final state = await loaded(
          bloc,
          AnalysisStarted(periodStart: DateTime(2026, 9, 15)),
        );
        expect(state.comparison!.months, 3);
        expect(state.comparison!.toDay, isNull);
        expect(state.highlights.map((h) => h.group.key), ['cat:makan']);

        // Jenis berganti: dihitung ulang dari transaksi yang sama (Pemasukan tanpa riwayat → semua baru).
        bloc.add(const AnalysisKindChanged(CategoryKind.income));
        final income = await bloc.stream.firstWhere(
          (s) => s.kind == CategoryKind.income,
        );
        expect(income.comparison!.totalSum, 0);
        expect(income.highlights, isEmpty);
      },
    );

    test(
      'periode berjalan: toDay = tanggal hari ini; bulan pertama pencatatan tidak punya pembanding',
      () async {
        await seed([
          expenseOn(DateTime(2026, 8, 4), 100000, category: 'makan'),
          expenseOn(DateTime(2026, 10, 4), 50000, category: 'makan'),
        ]);
        final state = await loaded(create());
        expect(state.comparison!.toDay, 10);
        expect(
          state.comparison!.months,
          2,
          reason: 'September dan Agustus; Juli sebelum pencatatan pertama',
        );

        final first = await loaded(
          create(),
          AnalysisStarted(periodStart: DateTime(2026, 8, 15)),
        );
        expect(first.comparison, isNull);
      },
    );
  });

  group('jenis dan dompet (F2, F3)', () {
    Future<void> seedWallets() async {
      final wallets = WalletRepositoryImpl(storage: storage);
      for (final id in ['bca', 'tabungan']) {
        await wallets.saveWallet(
          Wallet(
            id: id,
            name: id.toUpperCase(),
            iconKey: 'walletBank',
            initialBalance: 0,
            currentBalance: 0,
          ),
        );
      }
    }

    test(
      'bawaannya pengeluaran dan semua dompet; dompet dimuat untuk penyaring',
      () async {
        await seedWallets();
        await seed(september2026());
        final state = await loaded(
          create(),
          AnalysisStarted(periodStart: DateTime(2026, 9, 15)),
        );
        expect(state.kind, CategoryKind.expense);
        expect(state.walletId, isNull);
        expect(state.wallets.map((w) => w.id), ['bca', 'tabungan']);
        expect(state.summary!.total, rp(11420700));
      },
    );

    test(
      'Pemasukan: Gaji dan Freelance; total = Rp14.615.437,50; pilihan baris dikosongkan',
      () async {
        await seedWallets();
        await seed(september2026());
        final bloc = create();
        await loaded(bloc, AnalysisStarted(periodStart: DateTime(2026, 9, 15)));
        bloc
          ..add(const AnalysisGroupSelected('cat:makan'))
          ..add(const AnalysisKindChanged(CategoryKind.income));
        final state = await bloc.stream.firstWhere(
          (s) => s.kind == CategoryKind.income,
        );
        expect(state.selectedKey, isNull);
        expect(state.summary!.kind, CategoryKind.income);
        expect(state.summary!.total, 1461543750);
        expect(state.summary!.groups.map((g) => g.key), [
          'cat:gaji',
          'freelance',
        ]);
      },
    );

    test(
      'satu dompet: hanya transaksinya, transfer masuk/keluar dompet itu; semua dompet kembali',
      () async {
        await seedWallets();
        await seed([
          ...september2026(),
          expenseOn(
            DateTime(2026, 9, 9),
            50000,
            category: 'makan',
            wallet: 'tabungan',
          ),
        ]);
        final bloc = create();
        await loaded(bloc, AnalysisStarted(periodStart: DateTime(2026, 9, 15)));
        bloc.add(const AnalysisWalletChanged('tabungan'));
        var state = await bloc.stream.firstWhere(
          (s) => s.walletId == 'tabungan',
        );
        expect(state.summary!.total, rp(50000));
        expect(state.summary!.transfers.perWallet, isTrue);
        expect(state.summary!.transfers.incoming, rp(1000000));
        expect(state.summary!.transfers.outgoing, 0);

        bloc.add(const AnalysisWalletChanged(null));
        state = await bloc.stream.firstWhere((s) => s.walletId == null);
        expect(state.summary!.total, rp(11470700));
        expect(state.summary!.transfers.perWallet, isFalse);
      },
    );

    test(
      'jenis dan dompet bertahan lewat penyegaran dan pindah periode',
      () async {
        await seedWallets();
        await seed(september2026());
        final bloc = create();
        await loaded(bloc);
        bloc
          ..add(const AnalysisKindChanged(CategoryKind.income))
          ..add(const AnalysisWalletChanged('bca'));
        await bloc.stream.firstWhere((s) => s.walletId == 'bca');
        bloc.add(const AnalysisPeriodStepped(forward: false));
        final state = await bloc.stream.firstWhere(
          (s) => s.period.label == 'September 2026' && !s.isLoading,
        );
        expect(state.kind, CategoryKind.income);
        expect(state.walletId, 'bca');
        expect(state.summary!.total, 1461543750);
      },
    );

    test(
      'mengulang pilihan yang sama tidak memancarkan keadaan baru',
      () async {
        await seedWallets();
        await seed(september2026());
        final bloc = create();
        final first = await loaded(bloc);
        bloc.add(const AnalysisKindChanged(CategoryKind.expense));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(identical(bloc.state, first), isTrue);
      },
    );
  });

  test(
    'awalnya memuat; periode berjalan Oktober 2026, tidak bisa maju, bisa mundur bila ada bulan lebih lama',
    () async {
      await seed([
        ...september2026(),
        expenseOn(DateTime(2026, 10, 3), 520000, category: 'makan'),
      ]);
      final bloc = create();
      expect(bloc.state.isLoading, isTrue);
      final state = await loaded(bloc);
      expect(state.period.label, 'Oktober 2026');
      expect(state.isCurrent, isTrue);
      expect(state.canGoBack, isTrue);
      expect(state.hasAnyTransactions, isTrue);
      expect(state.summary!.total, rp(520000));
      expect(state.loadFailed, isFalse);
    },
  );

  test(
    'mundur ke September menampilkan contoh §10; maju kembali ke periode berjalan; di periode terlama mundur ditolak',
    () async {
      await seed([
        ...september2026(),
        expenseOn(DateTime(2026, 10, 3), 520000, category: 'makan'),
      ]);
      final bloc = create();
      await loaded(bloc);

      bloc.add(const AnalysisPeriodStepped(forward: false));
      final september = await bloc.stream.firstWhere(
        (s) => s.period.start == DateTime(2026, 9),
      );
      expect(september.period.label, 'September 2026');
      expect(september.isCurrent, isFalse);
      expect(september.summary!.total, rp(11420700));
      expect(
        september.canGoBack,
        isFalse,
        reason: 'September memuat bulan pertama pencatatan',
      );

      bloc.add(const AnalysisPeriodStepped(forward: false));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(
        bloc.state.period.start,
        DateTime(2026, 9),
        reason: 'tidak ada periode lebih lama',
      );

      bloc.add(const AnalysisPeriodStepped(forward: true));
      final october = await bloc.stream.firstWhere(
        (s) => s.period.start == DateTime(2026, 10),
      );
      expect(october.isCurrent, isTrue);

      bloc.add(const AnalysisPeriodStepped(forward: true));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(
        bloc.state.period.start,
        DateTime(2026, 10),
        reason: 'Analisis tidak melihat ke depan',
      );
    },
  );

  test(
    'dibuka untuk periode tertentu dari luar (kilas balik); periode di masa depan diklem ke periode berjalan',
    () async {
      await seed(september2026());
      final september = await loaded(
        create(),
        AnalysisStarted(periodStart: DateTime(2026, 9, 15)),
      );
      expect(september.period.start, DateTime(2026, 9));
      expect(september.isCurrent, isFalse);
      expect(september.summary!.total, rp(11420700));

      final clamped = await loaded(
        create(),
        AnalysisStarted(periodStart: DateTime(2027, 3)),
      );
      expect(clamped.period.start, DateTime(2026, 10));
      expect(clamped.isCurrent, isTrue);
    },
  );

  group('pilihan kategori (F1)', () {
    Future<AnalysisBloc> september() async {
      await seed(september2026());
      final bloc = create();
      await loaded(bloc, AnalysisStarted(periodStart: DateTime(2026, 9)));
      return bloc;
    }

    Future<AnalysisState> select(AnalysisBloc bloc, String key) {
      bloc.add(AnalysisGroupSelected(key));
      return bloc.stream.first;
    }

    test(
      'mengetuk memilih, mengetuk lagi membatalkan; hanya satu pilihan sekaligus',
      () async {
        final bloc = await september();
        expect(bloc.state.selectedKey, isNull);
        var state = await select(bloc, 'cat:makan');
        expect(state.selected!.category!.name, 'Makan');
        expect(state.summary!.sliceOf('cat:makan'), 3);
        state = await select(bloc, 'cat:belanja');
        expect(state.selectedKey, 'cat:belanja');
        state = await select(bloc, 'cat:belanja');
        expect(state.selectedKey, isNull);
      },
    );

    test(
      'Lainnya memilih sekaligus membuka anggotanya; mengetuk lagi menutup keduanya; anggota menyalakan irisan Lainnya',
      () async {
        final bloc = await september();
        var state = await select(bloc, 'others');
        expect([state.selectedKey, state.othersOpen], ['others', true]);
        state = await select(bloc, 'cat:tagihan');
        expect(state.selected!.category!.name, 'Tagihan');
        expect(
          state.othersOpen,
          isTrue,
          reason: 'anggota tetap terbuka saat dipilih',
        );
        expect(
          state.summary!.sliceOf('cat:tagihan'),
          5,
          reason: 'irisan Lainnya yang menyala',
        );
        state = await select(bloc, 'cat:tagihan');
        state = await select(bloc, 'others');
        state = await select(bloc, 'others');
        expect([state.selectedKey, state.othersOpen], [null, false]);
      },
    );

    test(
      'kunci yang tidak ada diabaikan; Tanpa kategori bisa dipilih',
      () async {
        final bloc = await september();
        bloc.add(const AnalysisGroupSelected('cat:tidak-ada'));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(bloc.state.selectedKey, isNull);
        final state = await select(bloc, 'uncategorized');
        expect(state.selected!.kind, AnalysisGroupKind.uncategorized);
      },
    );

    test(
      'pindah periode mengosongkan pilihan; penyegaran mempertahankannya selama barisnya ada',
      () async {
        await seed([
          ...september2026(),
          expenseOn(DateTime(2026, 8, 12), 700000, category: 'makan'),
        ]);
        final bloc = create();
        await loaded(bloc, AnalysisStarted(periodStart: DateTime(2026, 9)));
        await select(bloc, 'cat:makan');
        await select(bloc, 'others');

        ledger.notifyChanged(source: Object());
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(
          bloc.state.selectedKey,
          'others',
          reason: 'penyegaran tidak menghapus pilihan',
        );
        expect(bloc.state.othersOpen, isTrue);

        bloc.add(const AnalysisPeriodStepped(forward: false));
        final august = await bloc.stream.firstWhere(
          (s) => s.period.start == DateTime(2026, 8),
        );
        expect(august.selectedKey, isNull);
        expect(august.othersOpen, isFalse);
      },
    );

    test('penyegaran membuang pilihan yang barisnya sudah hilang', () async {
      final bloc = await september();
      await select(bloc, 'uncategorized');
      // Tanpa kategori diberi kategori di layar lain.
      final uncategorized = (await repository.listTransactionsInMonth(
        DateTime(2026, 9),
      )).getOrElse((_) => const []).whereType<ExpenseTransaction>().firstWhere((t) => t.categoryId == null);
      await repository.saveTransaction(
        uncategorized.copyWith(categoryId: 'makan'),
      );
      ledger.notifyChanged(source: Object());
      final refreshed = await bloc.stream.firstWhere(
        (s) => s.summary!.groupOf('uncategorized') == null,
      );
      expect(refreshed.selectedKey, isNull);
    });
  });

  test(
    'belum ada transaksi sama sekali: keadaan kosong, tanpa ringkasan',
    () async {
      final state = await loaded(create());
      expect(state.hasAnyTransactions, isFalse);
      expect(state.summary, isNull);
      expect(state.canGoBack, isFalse);
    },
  );

  test(
    'gagal membaca: pemuatan pertama menampilkan galat dengan pemberitahuan',
    () async {
      final failing = MockTransactionRepository();
      when(failing.listAvailableMonths).thenAnswer(
        (_) async => left(
          const SystemFailure(
            code: FailureCode('TEST_FORCED_FAILURE'),
            message: 'dipaksa gagal',
          ),
        ),
      );
      final state = await loaded(create(source: failing));
      expect(state.loadFailed, isTrue);
      expect(state.summary, isNull);
      expect(state.effect, isA<ShowSnackBarEffect>());
    },
  );

  test(
    'transaksi baru menyegarkan lewat LedgerChanges; sumbernya sendiri tidak memicu',
    () async {
      await seed(september2026());
      final bloc = create();
      await loaded(bloc, AnalysisStarted(periodStart: DateTime(2026, 9)));
      expect(bloc.state.summary!.total, rp(11420700));

      await repository.saveTransaction(
        expenseOn(DateTime(2026, 9, 29), 1000, category: 'makan'),
      );
      ledger.notifyChanged(source: Object());
      final refreshed = await bloc.stream.firstWhere(
        (s) => s.summary!.total == rp(11421700),
      );
      expect(refreshed.summary!.count, 10);

      // Pancaran dari bloc itu sendiri diabaikan (B-13: Analisis tidak menulis).
      ledger.notifyChanged(source: bloc);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(bloc.state.summary!.total, rp(11421700));
    },
  );

  test(
    'awal bulan keuangan diubah: periode peralihan 1 – 24 Okt (24 hari) dihitung ulang',
    () async {
      await seed([
        expenseOn(DateTime(2026, 10, 3), 520000, category: 'makan'),
        expenseOn(DateTime(2026, 9, 3), 1000, category: 'makan'),
      ]);
      final bloc = create();
      final before = await loaded(bloc);
      expect(before.period.isTransition, isFalse);

      // Contoh B: 1 → 25 pada 10 Okt.
      ActiveFinancialMonth.notifier.value = FinancialMonthSchedule.initial.changedOn(
        DateTime(2026, 10, 10),
        const FinancialMonthStart.day(25),
      );
      final transition = await bloc.stream.firstWhere(
        (s) => s.period.isTransition,
      );
      expect(transition.period.rangeLabel, '1\u00A0–\u00A024\u00A0Okt');
      expect(transition.period.days, 24);
      expect(transition.summary!.total, rp(520000));
      expect(transition.isCurrent, isTrue);
    },
  );
}
