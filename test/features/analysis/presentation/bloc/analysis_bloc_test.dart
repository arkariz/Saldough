import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/features/analysis/presentation/bloc/analysis_bloc.dart';
import 'package:saldough/features/analysis/presentation/bloc/analysis_state.dart';
import 'package:saldough/shared/transaction/transaction.dart';
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
    ActiveFinancialMonth.notifier.value = FinancialMonthSchedule.initial;
    for (final bloc in blocs) {
      await bloc.close();
    }
  });

  AnalysisBloc create({TransactionRepository? source}) {
    final bloc = AnalysisBloc(
      transactionRepository: source ?? repository,
      ledgerChanges: ledger,
      categoryOf: analysisCategoryOf,
      now: () => today,
    );
    blocs.add(bloc);
    return bloc;
  }

  Future<void> seed(Iterable<Transaction> transactions) async {
    for (final transaction in transactions) {
      await repository.saveTransaction(transaction);
    }
  }

  Future<AnalysisState> loaded(AnalysisBloc bloc, [AnalysisEvent event = const AnalysisStarted()]) {
    bloc.add(event);
    return bloc.stream.firstWhere((s) => !s.isLoading);
  }

  test('awalnya memuat; periode berjalan Oktober 2026, tidak bisa maju, bisa mundur bila ada bulan lebih lama', () async {
    await seed([...september2026(), expenseOn(DateTime(2026, 10, 3), 520000, category: 'makan')]);
    final bloc = create();
    expect(bloc.state.isLoading, isTrue);
    final state = await loaded(bloc);
    expect(state.period.label, 'Oktober 2026');
    expect(state.isCurrent, isTrue);
    expect(state.canGoBack, isTrue);
    expect(state.hasAnyTransactions, isTrue);
    expect(state.summary!.total, rp(520000));
    expect(state.loadFailed, isFalse);
  });

  test('mundur ke September menampilkan contoh §10; maju kembali ke periode berjalan; di periode terlama mundur ditolak', () async {
    await seed([...september2026(), expenseOn(DateTime(2026, 10, 3), 520000, category: 'makan')]);
    final bloc = create();
    await loaded(bloc);

    bloc.add(const AnalysisPeriodStepped(forward: false));
    final september = await bloc.stream.firstWhere((s) => s.period.start == DateTime(2026, 9));
    expect(september.period.label, 'September 2026');
    expect(september.isCurrent, isFalse);
    expect(september.summary!.total, rp(11420700));
    expect(september.canGoBack, isFalse, reason: 'September memuat bulan pertama pencatatan');

    bloc.add(const AnalysisPeriodStepped(forward: false));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(bloc.state.period.start, DateTime(2026, 9), reason: 'tidak ada periode lebih lama');

    bloc.add(const AnalysisPeriodStepped(forward: true));
    final october = await bloc.stream.firstWhere((s) => s.period.start == DateTime(2026, 10));
    expect(october.isCurrent, isTrue);

    bloc.add(const AnalysisPeriodStepped(forward: true));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(bloc.state.period.start, DateTime(2026, 10), reason: 'Analisis tidak melihat ke depan');
  });

  test('dibuka untuk periode tertentu dari luar (kilas balik); periode di masa depan diklem ke periode berjalan', () async {
    await seed(september2026());
    final september = await loaded(create(), AnalysisStarted(periodStart: DateTime(2026, 9, 15)));
    expect(september.period.start, DateTime(2026, 9));
    expect(september.isCurrent, isFalse);
    expect(september.summary!.total, rp(11420700));

    final clamped = await loaded(create(), AnalysisStarted(periodStart: DateTime(2027, 3)));
    expect(clamped.period.start, DateTime(2026, 10));
    expect(clamped.isCurrent, isTrue);
  });

  test('belum ada transaksi sama sekali: keadaan kosong, tanpa ringkasan', () async {
    final state = await loaded(create());
    expect(state.hasAnyTransactions, isFalse);
    expect(state.summary, isNull);
    expect(state.canGoBack, isFalse);
  });

  test('gagal membaca: pemuatan pertama menampilkan galat dengan pemberitahuan', () async {
    final failing = MockTransactionRepository();
    when(failing.listAvailableMonths).thenAnswer(
      (_) async => left(const SystemFailure(code: FailureCode('TEST_FORCED_FAILURE'), message: 'dipaksa gagal')),
    );
    final state = await loaded(create(source: failing));
    expect(state.loadFailed, isTrue);
    expect(state.summary, isNull);
    expect(state.effect, isA<ShowSnackBarEffect>());
  });

  test('transaksi baru menyegarkan lewat LedgerChanges; sumbernya sendiri tidak memicu', () async {
    await seed(september2026());
    final bloc = create();
    await loaded(bloc, AnalysisStarted(periodStart: DateTime(2026, 9)));
    expect(bloc.state.summary!.total, rp(11420700));

    await repository.saveTransaction(expenseOn(DateTime(2026, 9, 29), 1000, category: 'makan'));
    ledger.notifyChanged(source: Object());
    final refreshed = await bloc.stream.firstWhere((s) => s.summary!.total == rp(11421700));
    expect(refreshed.summary!.count, 10);

    // Pancaran dari bloc itu sendiri diabaikan (B-13: Analisis tidak menulis).
    ledger.notifyChanged(source: bloc);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(bloc.state.summary!.total, rp(11421700));
  });

  test('awal bulan keuangan diubah: periode peralihan 1 – 24 Okt (24 hari) dihitung ulang', () async {
    await seed([expenseOn(DateTime(2026, 10, 3), 520000, category: 'makan'), expenseOn(DateTime(2026, 9, 3), 1000, category: 'makan')]);
    final bloc = create();
    final before = await loaded(bloc);
    expect(before.period.isTransition, isFalse);

    // Contoh B: 1 → 25 pada 10 Okt.
    ActiveFinancialMonth.notifier.value = FinancialMonthSchedule.initial.changedOn(
      DateTime(2026, 10, 10),
      const FinancialMonthStart.day(25),
    );
    final transition = await bloc.stream.firstWhere((s) => s.period.isTransition);
    expect(transition.period.rangeLabel, '1\u00A0–\u00A024\u00A0Okt');
    expect(transition.period.days, 24);
    expect(transition.summary!.total, rp(520000));
    expect(transition.isCurrent, isTrue);
  });
}
