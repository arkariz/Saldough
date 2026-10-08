import 'package:dependencies/dependencies.dart';
import 'package:di/di.dart';
import 'package:failures/failures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/app/shell/app_shell_page.dart';
import 'package:saldough/core/foundation/effect_handler/app_effect_registry.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/budget/data/adapters/budget_item_catalog_impl.dart';
import 'package:saldough/features/budget/data/repositories/budget_repository_impl.dart';
import 'package:saldough/features/budget/data/repositories/budget_template_repository_impl.dart';
import 'package:saldough/features/budget/domain/entities/budget_item.dart';
import 'package:saldough/features/budget/domain/entities/budget_item_kind.dart';
import 'package:saldough/features/budget/domain/entities/budget_template.dart';
import 'package:saldough/features/budget/domain/repositories/budget_repository.dart';
import 'package:saldough/features/budget/domain/repositories/budget_template_repository.dart';
import 'package:saldough/features/budget/presentation/pages/budget_template_page.dart';
import 'package:saldough/features/budget/presentation/widgets/budget_form_sheet.dart';
import 'package:saldough/features/home/domain/budget_overview_source.dart';
import 'package:saldough/features/home/domain/freelance_overview_source.dart';
import 'package:saldough/features/plan/domain/plan_sources.dart';
import 'package:saldough/shared/auth/auth.dart';
import 'package:saldough/shared/budget_catalog/budget_catalog.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

import '../../../../helpers/fake_auth_repository.dart';
import '../../../../helpers/mocks.dart';
import '../../../../helpers/plan_sources.dart';
import '../../../../helpers/routes.dart';

T _right<T>(Either<Failure, T> result) => result.getOrElse((_) => throw StateError('expected Right'));

/// Layar Template Anggaran (T-7.2) dan pembuatan anggaran dari template
/// (T-7.3, FR-BUD-005) lewat shell sungguhan dengan penyimpanan di memori.
void main() {
  late WalletRepositoryImpl walletRepository;
  late BudgetRepositoryImpl budgetRepository;
  late BudgetTemplateRepositoryImpl templateRepository;
  late GetIt container;

  const bca = Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 0, currentBalance: 500000000);
  const template = BudgetTemplate(
    id: 'tpl',
    name: 'Belanja bulanan',
    items: [
      BudgetItem(id: 'beras', name: 'Beras', quantity: 2, unitPrice: 7500000),
      BudgetItem(id: 'sabun', name: 'Sabun', enteredAmount: 5000000),
    ],
  );

  setUpAll(registerEffectHandlers);

  setUp(() async {
    final storage = InMemoryKeyValueStorage();
    walletRepository = WalletRepositoryImpl(storage: storage);
    budgetRepository = BudgetRepositoryImpl(storage: storage);
    templateRepository = BudgetTemplateRepositoryImpl(storage: storage);
    container = GetIt.asNewInstance()
      ..registerLazySingleton<AuthRepository>(FakeAuthRepository.new)
      ..registerLazySingleton<BudgetOverviewSource>(stubBudgetOverviewSource)
      ..registerLazySingleton<FreelanceOverviewSource>(stubFreelanceOverviewSource)
      ..registerLazySingleton<WalletRepository>(() => walletRepository)
      ..registerLazySingleton<LedgerChanges>(LedgerChanges.new)
      ..registerLazySingleton<RecurringChanges>(RecurringChanges.new)
      ..registerLazySingleton<RecurringRuleRepository>(
        () => RecurringRuleRepositoryImpl(storage: InMemoryKeyValueStorage()),
      )
      ..registerLazySingleton<PlanBudgetSource>(EmptyPlanBudgetSource.new)
      ..registerLazySingleton<PlanFreelanceSource>(EmptyPlanFreelanceSource.new)
      ..registerSingleton<RouteRegistry>(appRouteRegistry())
      ..registerLazySingleton<TransactionRepository>(() => TransactionRepositoryImpl(storage: storage))
      ..registerLazySingleton<BudgetRepository>(() => budgetRepository)
      ..registerLazySingleton<BudgetTemplateRepository>(() => templateRepository)
      ..registerLazySingleton<BudgetItemCatalog>(() => BudgetItemCatalogImpl(repository: budgetRepository))
      ..registerLazySingleton<CategoryRepository>(() => CategoryRepositoryImpl(storage: InMemoryKeyValueStorage()));
    await walletRepository.saveWallet(bca);
  });

  Future<void> openTemplates(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ScopeProvider(
        container: container,
        child: MaterialApp(theme: PixelTheme.light, home: const AppShellPage()),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }
    await tester.tap(find.descendant(of: find.byType(AppNavBar), matching: find.text(t.appShell.planTabLabel)));
    await tester.pumpAndSettle();
    // Awal sesi membuka Bulan ini (KT-L4).
    await tester.tap(find.text(t.appShell.budgetTabLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.budget.templatesAction));
    await tester.pumpAndSettle();
    expect(find.byType(BudgetTemplatePage), findsOneWidget);
  }

  testWidgets('Gunakan template: anggaran mandiri dengan id pos baru; template dan saldo tidak berubah', (
    tester,
  ) async {
    await templateRepository.saveTemplate(template);
    await openTemplates(tester);

    expect(find.text(template.name), findsOneWidget);
    await tester.tap(find.text(t.budget.templateUseAction));
    await tester.pumpAndSettle();
    // Formulir anggaran yang SAMA, terisi pos template; dompet tunggal
    // otomatis terpilih.
    final form = find.byType(BudgetFormSheet);
    expect(find.descendant(of: form, matching: find.text('Beras')), findsOneWidget);
    expect(find.descendant(of: form, matching: find.text('Sabun')), findsOneWidget);
    await tester.ensureVisible(find.text(t.budget.saveAddAction));
    await tester.tap(find.text(t.budget.saveAddAction));
    await tester.pumpAndSettle();

    final budget = _right(await budgetRepository.listBudgets()).single;
    expect(budget.name, template.name);
    expect(budget.walletId, 'bca');
    expect(budget.plannedAmount, template.plannedAmount);
    expect(budget.items.map((i) => i.id).toSet().intersection({'beras', 'sabun'}), isEmpty);
    expect(_right(await templateRepository.listTemplates()), [template]);
    expect(_right(await walletRepository.listWallets()), [bca]);
    // Kembali ke daftar Anggaran, tempat anggaran baru itu tampil.
    expect(find.byType(BudgetTemplatePage), findsNothing);
  });

  testWidgets('pos transfer template yang menuju dompet anggaran menahan simpan sampai tujuannya diganti', (
    tester,
  ) async {
    await templateRepository.saveTemplate(
      const BudgetTemplate(
        id: 'tpl2',
        name: 'Tabungan',
        items: [
          BudgetItem(
            id: 'tabung',
            name: 'Ke tabungan',
            enteredAmount: 50000000,
            kind: BudgetItemKind.transfer,
            targetWalletId: 'bca',
          ),
        ],
      ),
    );
    await openTemplates(tester);

    await tester.tap(find.text(t.budget.templateUseAction));
    await tester.pumpAndSettle();

    expect(find.text(t.budget.itemTargetConflict(name: 'Ke tabungan')), findsOneWidget);
    final save = tester.widget<AppButton>(find.widgetWithText(AppButton, t.budget.saveAddAction));
    expect(save.onPressed, isNull);
  });

  testWidgets('template nonaktif tetap tampil tetapi tidak bisa dipakai', (tester) async {
    await templateRepository.saveTemplate(template.copyWith(isEnabled: false));
    await openTemplates(tester);

    expect(find.text(t.budget.templateInactiveBadge.toUpperCase()), findsOneWidget);
    final use = tester.widget<AppButton>(find.widgetWithText(AppButton, t.budget.templateUseAction));
    expect(use.onPressed, isNull);
  });
}
