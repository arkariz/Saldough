import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/features/notification_capture/data/merchant_memory_store_impl.dart';
import 'package:saldough/features/notification_capture/data/notification_capture_store_impl.dart';
import 'package:saldough/features/notification_capture/domain/entities/capture_inbox_entry.dart';
import 'package:saldough/features/notification_capture/domain/services/store_backed_merchant_memory.dart';
import 'package:saldough/features/notification_capture/domain/usecases/capture_inbox_actions.dart';
import 'package:saldough/shared/capture/capture.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

import 'notification_fixtures.dart';

/// Ingatan pedagang (ADR-044, E1/B-85): kategori yang dikonfirmasi pengguna
/// diingat per (aplikasi, catatan) dan dipakai notifikasi berikutnya.
void main() {
  late InMemoryKeyValueStorage storage;
  late StoreBackedMerchantMemory memory;

  setUp(() {
    storage = InMemoryKeyValueStorage();
    memory = StoreBackedMerchantMemory(MerchantMemoryStoreImpl(storage: storage));
  });

  test('catatan dinormalkan: huruf besar dan spasi ganda satu pedagang', () async {
    await memory.remember(packageName: 'app.a', note: 'ES  BUAH', categoryId: 'food');
    expect(memory.categoryFor(packageName: 'app.a', note: 'es buah'), 'food');
    expect(
      memory.categoryFor(packageName: 'app.b', note: 'es buah'),
      isNull,
      reason: 'per aplikasi',
    );
    expect(memory.categoryFor(packageName: 'app.a', note: '  '), isNull);
  });

  test('bertahan di penyimpanan dan dibaca ulang lewat refresh', () async {
    await memory.remember(packageName: 'app.a', note: 'es buah', categoryId: 'food');
    final other = StoreBackedMerchantMemory(MerchantMemoryStoreImpl(storage: storage));
    expect(
      other.categoryFor(packageName: 'app.a', note: 'es buah'),
      isNull,
      reason: 'belum dimuat',
    );
    await other.refresh();
    expect(other.categoryFor(packageName: 'app.a', note: 'es buah'), 'food');
  });

  test('mengganti kategori mengembalikan yang lama; restore memulihkan atau melupakan', () async {
    expect(await memory.remember(packageName: 'app.a', note: 'kopi', categoryId: 'food'), isNull);
    expect(await memory.remember(packageName: 'app.a', note: 'kopi', categoryId: 'snack'), 'food');
    await memory.restore(packageName: 'app.a', note: 'kopi', previous: 'food');
    expect(memory.categoryFor(packageName: 'app.a', note: 'kopi'), 'food');
    await memory.restore(packageName: 'app.a', note: 'kopi', previous: null);
    expect(memory.categoryFor(packageName: 'app.a', note: 'kopi'), isNull);
  });

  test('penuh: yang tertua dibuang', () async {
    for (var i = 0; i < merchantMemoryLimit + 3; i++) {
      await memory.remember(packageName: 'app.a', note: 'p$i', categoryId: 'c');
    }
    await memory.refresh();
    expect(memory.categoryFor(packageName: 'app.a', note: 'p0'), isNull);
    expect(memory.categoryFor(packageName: 'app.a', note: 'p${merchantMemoryLimit + 2}'), 'c');
  });

  group('CaptureInboxActions.rememberCategory', () {
    CaptureInboxEntry entry({String? category, DraftKind kind = DraftKind.expense}) => CaptureInboxEntry(
      id: 'e1',
      packageName: 'app.a',
      appLabel: 'App A',
      text: 'teks',
      capturedAt: DateTime(2026, 11, 4),
      draft: RecordDraft(kind: kind, amountSen: 1000000, categoryId: category, note: 'es buah'),
    );

    CaptureInboxActions actions() {
      final ledger = TransactionRepositoryImpl(storage: storage);
      final wallets = WalletRepositoryImpl(storage: storage);
      return CaptureInboxActions(
        store: NotificationCaptureStoreImpl(storage: storage),
        recordTransaction: RecordTransaction(
          ledgerChanges: LedgerChanges(),
          transactionRepository: ledger,
          recomputeWalletBalances: RecomputeWalletBalances(walletRepository: wallets, transactionRepository: ledger),
        ),
        transactionRepository: ledger,
        composer: notificationComposer(),
        walletRepository: wallets,
        categories: () => const [],
        currencyCode: () => 'IDR',
        languageCode: () => 'id',
        merchantMemory: memory,
      );
    }

    test('kategori baru dari kartu tanpa kategori: diingat, Batalkan melupakan', () async {
      final undo = await actions().rememberCategory(entry(), categoryId: 'food', note: 'es buah');
      expect(undo, isNotNull);
      expect(memory.categoryFor(packageName: 'app.a', note: 'es buah'), 'food');
      await undo!();
      expect(memory.categoryFor(packageName: 'app.a', note: 'es buah'), isNull);
    });

    test('tidak belajar: kategori sama dengan draf, tanpa kategori atau catatan, transfer', () async {
      final a = actions();
      expect(
        await a.rememberCategory(
          entry(category: 'food'),
          categoryId: 'food',
          note: 'es buah',
        ),
        isNull,
      );
      expect(await a.rememberCategory(entry(), categoryId: null, note: 'es buah'), isNull);
      expect(await a.rememberCategory(entry(), categoryId: 'food', note: ' '), isNull);
      expect(
        await a.rememberCategory(
          entry(kind: DraftKind.transfer),
          categoryId: 'food',
          note: 'x',
        ),
        isNull,
      );
      await memory.refresh();
      expect(memory.categoryFor(packageName: 'app.a', note: 'es buah'), isNull);
    });

    test('kategori diubah dari draf: yang baru diingat', () async {
      await actions().rememberCategory(
        entry(category: 'food'),
        categoryId: 'snack',
        note: 'es buah',
      );
      expect(memory.categoryFor(packageName: 'app.a', note: 'es buah'), 'snack');
    });
  });
}
