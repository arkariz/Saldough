import 'package:dependencies/dependencies.dart';
import 'package:di/di.dart';
import 'package:failures/failures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/core/foundation/effect_handler/app_effect_registry.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/shell/app_shell_page.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/record/presentation/widgets/record_choice_sheet.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Dobel gagal untuk [WalletRepository] -- lihat `app_shell_page_test.dart`.
final class _FailingWalletRepository implements WalletRepository {
  @override
  Future<Either<Failure, List<Wallet>>> listWallets() async => const Left(
    SystemFailure(code: FailureCode('TEST_FORCED_FAILURE'), message: 'dipaksa gagal untuk uji'),
  );

  @override
  Future<Either<Failure, Unit>> saveWallet(Wallet wallet) => throw UnimplementedError();

  @override
  Future<Either<Failure, Unit>> deleteWallet(String id) => throw UnimplementedError();
}

void main() {
  late InMemoryKeyValueStorage storage;
  late WalletRepositoryImpl walletRepository;
  late TransactionRepositoryImpl transactionRepository;
  late GetIt container;

  setUpAll(registerEffectHandlers);

  setUp(() {
    storage = InMemoryKeyValueStorage();
    walletRepository = WalletRepositoryImpl(storage: storage);
    transactionRepository = TransactionRepositoryImpl(storage: storage);
    container = GetIt.asNewInstance()
      ..registerLazySingleton<WalletRepository>(() => walletRepository)
      ..registerLazySingleton<TransactionRepository>(() => transactionRepository);
  });

  Widget pumpableShell() {
    return ScopeProvider(
      container: container,
      child: const MaterialApp(home: AppShellPage()),
    );
  }

  Future<void> openTransactionsTab(WidgetTester tester) async {
    await tester.pumpWidget(pumpableShell());
    await tester.pump();
    // Dua `pump()` -- ScopeWidget<TransactionScope> bersarang setelah
    // ScopeWidget<RecordScope>, jadi initialisasi async-nya baru mulai satu
    // frame setelah RecordScope selesai; satu `pump()` saja belum cukup.
    await tester.pump();
    await tester.tap(find.widgetWithText(NavigationDestination, t.appShell.transactionsTabLabel));
    await tester.pumpAndSettle();
  }

  group('TransactionListPage', () {
    testWidgets('bulan berjalan genuinely belum ada transaksi menampilkan keadaan kosong bulan', (tester) async {
      await openTransactionsTab(tester);

      expect(find.text(t.transaction.emptyMonthTitle), findsOneWidget);
      expect(find.text(t.transaction.emptyFilterTitle), findsNothing);
    });

    testWidgets('filter yang menyisakan nol hasil menampilkan keadaan kosong filter, BUKAN keadaan kosong bulan', (
      tester,
    ) async {
      await walletRepository.saveWallet(
        const Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 0, currentBalance: 0),
      );
      final now = DateTime.now();
      await transactionRepository.saveTransaction(
        ExpenseTransaction(id: 'e1', date: now, amount: 30000, note: 'kopi', walletId: 'bca'),
      );

      await openTransactionsTab(tester);
      expect(find.text(t.transaction.emptyMonthTitle), findsNothing);

      await tester.tap(find.text(t.transaction.incomeFilterLabel(count: 0)));
      await tester.pumpAndSettle();

      expect(find.text(t.transaction.emptyFilterTitle), findsOneWidget);
      expect(find.text(t.transaction.emptyMonthTitle), findsNothing);
    });

    testWidgets('kegagalan pembacaan menampilkan keadaan galat, bukan keadaan kosong', (tester) async {
      final failingContainer = GetIt.asNewInstance()
        ..registerLazySingleton<WalletRepository>(_FailingWalletRepository.new)
        ..registerLazySingleton<TransactionRepository>(() => transactionRepository);

      await tester.pumpWidget(
        ScopeProvider(
          container: failingContainer,
          child: const MaterialApp(home: AppShellPage()),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.tap(find.widgetWithText(NavigationDestination, t.appShell.transactionsTabLabel));
      await tester.pumpAndSettle();

      expect(find.text(t.transaction.loadErrorTitle), findsOneWidget);
      expect(find.text(t.transaction.emptyMonthTitle), findsNothing);
    });

    testWidgets(
      'CTA keadaan kosong bulan membuka alur CATAT sungguhan (uji pengawatan penuh)',
      (tester) async {
        await openTransactionsTab(tester);
        expect(find.text(t.transaction.emptyMonthTitle), findsOneWidget);

        await tester.tap(find.widgetWithText(AppButton, t.transaction.emptyMonthCta));
        await tester.pumpAndSettle();

        expect(find.byType(RecordChoiceSheet), findsOneWidget);
        expect(find.text(t.record.incomeAction), findsWidgets);
      },
    );
  });
}
