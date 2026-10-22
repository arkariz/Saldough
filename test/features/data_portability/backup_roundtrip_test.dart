import 'dart:convert';
import 'dart:typed_data';

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/app/data_portability/app_backup_registry.dart';
import 'package:saldough/core/currency/app_currency.dart';
import 'package:saldough/core/currency/currency_preference_repository_impl.dart';
import 'package:saldough/features/data_portability/data/backup_codec.dart';
import 'package:saldough/features/data_portability/data/backup_scope.dart';
import 'package:saldough/features/data_portability/data/backup_validator.dart';
import 'package:saldough/features/data_portability/data/restore_engine.dart';
import 'package:saldough/shared/category/data/category_repository_impl.dart';
import 'package:saldough/shared/category/domain/category.dart';
import 'package:saldough/shared/transaction/data/source_icon_repository_impl.dart';
import 'package:saldough/shared/transaction/data/transaction_repository_impl.dart';
import 'package:saldough/shared/transaction/domain/transaction.dart';
import 'package:saldough/shared/transaction/domain/usecases/recompute_wallet_balances.dart';
import 'package:saldough/shared/wallet/data/wallet_repository_impl.dart';
import 'package:saldough/shared/wallet/domain/wallet.dart';

/// Bolak-balik dengan repositori nyata (ADR-040 §7 butir 2): cadangkan →
/// pulihkan ke penyimpanan kosong → seluruh data dan nilai turunannya identik.
void main() {
  Future<T> unwrap<T>(Future<Either<Failure, T>> either) async =>
      (await either).getOrElse((_) => throw StateError('Left'));

  late InMemoryKeyValueStorage source;
  late InMemoryKeyValueStorage target;
  late InMemoryKeyValueStorage staging;

  Future<void> seedSource({int bcaCache = 0}) async {
    final wallets = WalletRepositoryImpl(storage: source);
    final transactions = TransactionRepositoryImpl(storage: source);
    await wallets.saveWallet(
      Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 5000000, currentBalance: bcaCache),
    );
    await wallets.saveWallet(
      const Wallet(id: 'tunai', name: 'Tunai', iconKey: 'walletCash', initialBalance: 200000, currentBalance: 0),
    );
    await CategoryRepositoryImpl(storage: source).saveCategories(const [
      Category(id: 'builtin.food', kind: CategoryKind.expense, name: 'Makan'),
      Category(id: 'builtin.salary', kind: CategoryKind.income, name: 'Gaji', isArchived: true),
    ]);
    final iconId = await unwrap<String>(
      SourceIconRepositoryImpl(storage: source).save(Uint8List.fromList(List.generate(64, (i) => i))),
    );
    await CurrencyPreferenceRepositoryImpl(storage: source).save(AppCurrency.idr);

    for (final t in <Transaction>[
      IncomeTransaction(
        id: 'gaji',
        date: DateTime(2026, 8, 25),
        amount: 850000000,
        note: 'Gaji, dengan "kutip" dan\nbaris baru',
        categoryId: 'builtin.salary',
        walletId: 'bca',
      ),
      ExpenseTransaction(
        id: 'makan',
        date: DateTime(2026, 9, 3),
        amount: 4500000,
        note: 'Nasi padang 🍛',
        walletId: 'tunai',
        categoryId: 'builtin.food',
        sourceIconId: iconId,
      ),
      TransferTransaction(
        id: 'isi',
        date: DateTime(2026, 10),
        amount: 10000000,
        note: '',
        fromWalletId: 'bca',
        toWalletId: 'tunai',
      ),
    ]) {
      await transactions.saveTransaction(t);
    }
    await RecomputeWalletBalances(walletRepository: wallets, transactionRepository: transactions)();
  }

  setUp(() {
    source = InMemoryKeyValueStorage();
    target = InMemoryKeyValueStorage();
    staging = InMemoryKeyValueStorage();
  });

  Future<Uint8List> backup(InMemoryKeyValueStorage storage) async {
    final docs = await BackupScope.collect(storage, appBackupRegistry);
    return BackupCodec.encode(
      docs: docs,
      createdAt: DateTime(2026, 10, 22),
      appVersion: '0.8.0',
      appBuild: 14,
      summary: BackupValidator.summarize(docs, appBackupRegistry),
    );
  }

  Future<void> restoreInto(InMemoryKeyValueStorage storage, Uint8List bytes) async {
    final contents = BackupCodec.decode(bytes);
    BackupValidator.validate(contents, appBackupRegistry);
    final engine = RestoreEngine(live: storage, staging: staging, registry: appBackupRegistry);
    await engine.stage(incoming: contents.docs, kind: RestoreKind.onboarding);
    await engine.recover();
    await engine.finalize(
      () async => RecomputeWalletBalances(
        walletRepository: WalletRepositoryImpl(storage: storage),
        transactionRepository: TransactionRepositoryImpl(storage: storage),
      )(),
    );
  }

  test('seluruh dokumen identik, dan cadangan lolos pemeriksaannya sendiri', () async {
    await seedSource();
    final bytes = await backup(source);
    BackupValidator.validate(BackupCodec.decode(bytes), appBackupRegistry);

    await restoreInto(target, bytes);
    expect(await BackupScope.collect(target, appBackupRegistry), await BackupScope.collect(source, appBackupRegistry));
  });

  test('nilai turunan identik: dompet, saldo, transaksi tiap bulan, nominal tetap int sen', () async {
    await seedSource();
    await restoreInto(target, await backup(source));

    final a = (WalletRepositoryImpl(storage: source), TransactionRepositoryImpl(storage: source));
    final b = (WalletRepositoryImpl(storage: target), TransactionRepositoryImpl(storage: target));
    final walletsA = await unwrap<List<Wallet>>(a.$1.listWallets());
    final walletsB = await unwrap<List<Wallet>>(b.$1.listWallets());
    expect(walletsB, walletsA);
    // 5.000.000 + 8.500.000 − 100.000 (transfer keluar) dalam sen.
    expect(walletsB.firstWhere((w) => w.id == 'bca').currentBalance, 5000000 + 850000000 - 10000000);
    expect(walletsB.firstWhere((w) => w.id == 'tunai').currentBalance, 200000 - 4500000 + 10000000);

    expect(
      await unwrap<List<Transaction>>(b.$2.listAllTransactions()),
      await unwrap<List<Transaction>>(a.$2.listAllTransactions()),
    );
    for (final month in [DateTime(2026, 8), DateTime(2026, 9), DateTime(2026, 10)]) {
      expect(
        await unwrap<List<Transaction>>(b.$2.listTransactionsInMonth(month)),
        await unwrap<List<Transaction>>(a.$2.listTransactionsInMonth(month)),
      );
    }
    final note = (await unwrap<List<Transaction>>(b.$2.listAllTransactions())).first.note;
    expect(note, 'Gaji, dengan "kutip" dan\nbaris baru');
  });

  test('saldo dompet tidak dipercaya dari berkas: cache yang melenceng dihitung ulang (R-6)', () async {
    await seedSource();
    // Cache saldo di berkas sengaja salah.
    final docs = await BackupScope.collect(source, appBackupRegistry);
    final wallets = jsonDecode(docs['wallet_all']!) as Map<String, dynamic>;
    for (final w in wallets['items'] as List<dynamic>) {
      (w as Map<String, dynamic>)['currentBalance'] = 1;
    }
    docs['wallet_all'] = jsonEncode(wallets);
    final bytes = BackupCodec.encode(
      docs: docs,
      createdAt: DateTime(2026, 10, 22),
      appVersion: '0.8.0',
      appBuild: 14,
      summary: BackupValidator.summarize(docs, appBackupRegistry),
    );

    await restoreInto(target, bytes);
    final restored = await unwrap<List<Wallet>>(WalletRepositoryImpl(storage: target).listWallets());
    expect(restored.firstWhere((w) => w.id == 'bca').currentBalance, 5000000 + 850000000 - 10000000);
  });

  test('kunci milik perangkat di tujuan tidak disentuh', () async {
    await seedSource();
    await target.write('settings_language', '{"schemaVersion":1,"code":"en"}');
    await restoreInto(target, await backup(source));
    expect(await target.read('settings_language'), '{"schemaVersion":1,"code":"en"}');
  });

  test('ringkasan di berkas cocok dengan isinya', () async {
    await seedSource();
    final docs = await BackupScope.collect(source, appBackupRegistry);
    final summary = BackupValidator.summarize(docs, appBackupRegistry);
    expect((summary.transactions, summary.wallets, summary.firstDate, summary.currency), (3, 2, '2026-08-25', 'IDR'));
  });
}
