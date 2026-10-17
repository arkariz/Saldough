import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/transaction/presentation/navigation/transaction_route_keys.dart';
import 'package:saldough/features/transaction/presentation/pages/filtered_transactions_page.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Layar Daftar tersaring (T-19.3, F4/F5): judul, jumlah dan total, serta
/// transaksinya per hari.
void main() {
  late InMemoryKeyValueStorage storage;
  late TransactionRepositoryImpl transactions;

  final input = TransactionFilterInput(
    title: 'Tanpa kategori',
    subtitle: 'September 2026',
    filter: PeriodTransactionFilter(
      from: DateTime(2026, 9),
      until: DateTime(2026, 10),
      type: TransactionTypeFilter.expense,
      uncategorized: true,
    ),
  );

  setUp(() async {
    storage = InMemoryKeyValueStorage();
    transactions = TransactionRepositoryImpl(storage: storage);
    await WalletRepositoryImpl(storage: storage).saveWallet(
      const Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 0, currentBalance: 0),
    );
  });

  Future<void> pump(WidgetTester tester, {double width = 360}) async {
    tester.view.physicalSize = Size(width, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = GetIt.asNewInstance()
      ..registerSingleton<TransactionRepository>(transactions)
      ..registerSingleton<WalletRepository>(WalletRepositoryImpl(storage: storage))
      ..registerSingleton<LedgerChanges>(LedgerChanges());
    await tester.pumpWidget(
      ScopeProvider(
        container: container,
        child: MaterialApp(theme: PixelTheme.light, home: FilteredTransactionsPage(input: input)),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> seed() async {
    for (final t in [
      ExpenseTransaction(id: 'a', date: DateTime(2026, 9, 15, 9), amount: 12000000, note: 'Parkir kantor', walletId: 'bca'),
      ExpenseTransaction(id: 'b', date: DateTime(2026, 9, 15, 11), amount: 5000000, note: 'Tip', walletId: 'bca'),
      ExpenseTransaction(id: 'c', date: DateTime(2026, 9, 2, 8), amount: 3000000, note: 'Fotokopi', walletId: 'bca'),
      ExpenseTransaction(id: 'x', date: DateTime(2026, 10, 2), amount: 999, note: 'Oktober', walletId: 'bca'),
    ]) {
      await transactions.saveTransaction(t);
    }
  }

  testWidgets('judul, keterangan periode, jumlah, total, dan baris per hari', (tester) async {
    await seed();
    await pump(tester);
    expect(find.text('Tanpa kategori'), findsOneWidget);
    expect(find.text('September 2026'), findsOneWidget);
    expect(find.text('3 transaksi'), findsOneWidget);
    expect(find.text('Rp200.000'), findsOneWidget, reason: 'total = jumlah nominal yang lolos');
    expect(find.text('Parkir kantor'), findsOneWidget);
    expect(find.text('Tip'), findsOneWidget);
    expect(find.text('Fotokopi'), findsOneWidget);
    expect(find.text('Oktober'), findsNothing, reason: 'di luar periode');
    expect(tester.takeException(), isNull);
  });

  testWidgets('tidak ada yang lolos: ringkasan nol dan pesan netral', (tester) async {
    await pump(tester);
    expect(find.text('0 transaksi'), findsOneWidget);
    expect(find.byKey(const ValueKey('filtered-empty')), findsOneWidget);
    expect(find.text('Tidak ada lagi transaksi di sini.'), findsOneWidget);
  });
}
