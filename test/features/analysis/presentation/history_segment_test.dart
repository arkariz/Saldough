import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/app/shell/app_shell_page.dart';
import 'package:saldough/core/foundation/effect_handler/app_effect_registry.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/budget/data/repositories/budget_repository_impl.dart';
import 'package:saldough/features/budget/domain/repositories/budget_repository.dart';
import 'package:saldough/features/home/domain/budget_overview_source.dart';
import 'package:saldough/features/home/domain/freelance_overview_source.dart';
import 'package:saldough/features/plan/domain/plan_sources.dart';
import 'package:saldough/features/transaction/data/history_segment_repository_impl.dart';
import 'package:saldough/features/transaction/domain/history_segment.dart';
import 'package:saldough/shared/auth/auth.dart';
import 'package:saldough/shared/budget_catalog/budget_catalog.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

import '../../../helpers/categories.dart';
import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/mocks.dart';
import '../../../helpers/plan_sources.dart';
import '../../../helpers/routes.dart';

/// Segmen Daftar | Analisis di tab Riwayat (A1): navigasi, segmen terakhir
/// diingat, dan Analisis disisipkan akar komposisi (ADR-030).
void main() {
  late InMemoryKeyValueStorage storage;
  late GetIt container;

  setUpAll(registerEffectHandlers);

  setUp(() {
    useCategories(['Makan']);
    storage = InMemoryKeyValueStorage();
    container = GetIt.asNewInstance()
      ..registerLazySingleton<AuthRepository>(FakeAuthRepository.new)
      ..registerLazySingleton<BudgetOverviewSource>(stubBudgetOverviewSource)
      ..registerLazySingleton<FreelanceOverviewSource>(stubFreelanceOverviewSource)
      ..registerLazySingleton<BudgetRepository>(() => BudgetRepositoryImpl(storage: InMemoryKeyValueStorage()))
      ..registerLazySingleton<BudgetItemCatalog>(stubBudgetItemCatalog)
      ..registerLazySingleton<CategoryRepository>(() => CategoryRepositoryImpl(storage: InMemoryKeyValueStorage()))
      ..registerLazySingleton<WalletRepository>(() => WalletRepositoryImpl(storage: storage))
      ..registerLazySingleton<LedgerChanges>(LedgerChanges.new)
      ..registerLazySingleton<RecurringChanges>(RecurringChanges.new)
      ..registerLazySingleton<RecurringRuleRepository>(
        () => RecurringRuleRepositoryImpl(storage: InMemoryKeyValueStorage()),
      )
      ..registerLazySingleton<PlanBudgetSource>(EmptyPlanBudgetSource.new)
      ..registerLazySingleton<PlanFreelanceSource>(EmptyPlanFreelanceSource.new)
      ..registerSingleton<RouteRegistry>(appRouteRegistry())
      ..registerLazySingleton<HistorySegmentRepository>(() => HistorySegmentRepositoryImpl(storage: storage))
      ..registerLazySingleton<TransactionRepository>(() => TransactionRepositoryImpl(storage: storage));
  });

  Future<void> openHistoryTab(WidgetTester tester) async {
    await tester.pumpWidget(
      ScopeProvider(
        container: container,
        child: MaterialApp(theme: PixelTheme.light, home: const AppShellPage()),
      ),
    );
    // Scope bersarang diinisialisasi satu frame demi satu frame.
    for (var i = 0; i < 6; i++) {
      await tester.pump();
    }
    await tester.tap(find.descendant(of: find.byType(AppNavBar), matching: find.text(t.appShell.transactionsTabLabel)));
    await tester.pumpAndSettle();
  }

  Finder segment(String label) =>
      find.descendant(of: find.byType(AppSubTabs<HistorySegment>), matching: find.text(label));

  Future<HistorySegment> saved() async =>
      (await HistorySegmentRepositoryImpl(storage: storage).load()).getOrElse((_) => HistorySegment.list);

  testWidgets('Riwayat punya sub-tab Daftar dan Analisis; bawaannya Daftar', (tester) async {
    await openHistoryTab(tester);
    expect(find.byType(AppSubTabs<HistorySegment>), findsOneWidget);
    expect(segment('Daftar'), findsOneWidget);
    expect(segment('Analisis'), findsOneWidget);
    expect(find.text(t.transaction.emptyMonthTitle), findsOneWidget, reason: 'isi Daftar');
    expect(find.text(t.analysis.empty.title), findsNothing);
  });

  testWidgets('memilih Analisis mengganti seluruh isi dan mengingat pilihan; kembali ke Daftar', (tester) async {
    await openHistoryTab(tester);
    await tester.tap(segment('Analisis'));
    await tester.pumpAndSettle();
    // Belum ada transaksi sama sekali: keadaan kosong Analisis, isi Daftar hilang.
    expect(find.text(t.analysis.empty.title), findsOneWidget);
    expect(find.text(t.transaction.emptyMonthTitle), findsNothing);
    expect(await saved(), HistorySegment.analysis);

    await tester.tap(segment('Daftar'));
    await tester.pumpAndSettle();
    expect(find.text(t.transaction.emptyMonthTitle), findsOneWidget);
    expect(find.text(t.analysis.empty.title), findsNothing);
    expect(await saved(), HistorySegment.list);
  });

  testWidgets('segmen terakhir diingat: Riwayat langsung terbuka di Analisis', (tester) async {
    await HistorySegmentRepositoryImpl(storage: storage).save(HistorySegment.analysis);
    await openHistoryTab(tester);
    expect(find.text(t.analysis.empty.title), findsOneWidget);
    expect(find.text(t.transaction.emptyMonthTitle), findsNothing);
  });

  testWidgets('Analisis tersambung ke transaksi sungguhan: total dan donat tampil', (tester) async {
    final repository = TransactionRepositoryImpl(storage: storage);
    final now = DateTime.now();
    await repository.saveTransaction(
      ExpenseTransaction(id: 'e1', date: now, amount: 4500000, note: 'kopi', walletId: 'bca'),
    );
    await HistorySegmentRepositoryImpl(storage: storage).save(HistorySegment.analysis);
    await openHistoryTab(tester);
    expect(find.byKey(const ValueKey('analysis-card')), findsOneWidget);
    expect(find.text('Rp45.000'), findsWidgets);
    expect(find.text(t.analysis.uncategorized), findsOneWidget, reason: 'tanpa kategori');
  });
}
