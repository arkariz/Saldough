import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/features/notification_capture/data/merchant_memory_store_impl.dart';
import 'package:saldough/features/notification_capture/data/notification_capture_store_impl.dart';
import 'package:saldough/features/notification_capture/domain/entities/capture_inbox_entry.dart';
import 'package:saldough/features/notification_capture/domain/services/budget_item_suggestion.dart';
import 'package:saldough/features/notification_capture/domain/services/store_backed_merchant_memory.dart';
import 'package:saldough/features/notification_capture/domain/usecases/capture_inbox_actions.dart';
import 'package:saldough/shared/budget_catalog/budget_catalog.dart';
import 'package:saldough/shared/capture/capture.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

import 'notification_fixtures.dart';

/// Saran pos anggaran untuk pengeluaran bebas (ADR-044 §3.2, E2/B-86).
void main() {
  final date = DateTime(2026, 11, 10);

  BudgetItemOption option(
    String id,
    String name, {
    String wallet = 'bca',
    String? transferTo,
    bool archived = false,
    DateTime? start,
    DateTime? end,
  }) => BudgetItemOption(
    budgetId: 'b1',
    budgetName: 'November',
    itemId: id,
    itemName: name,
    walletId: wallet,
    startDate: start ?? DateTime(2026, 11),
    endDate: end ?? DateTime(2026, 12),
    isArchived: archived,
    transferToWalletId: transferTo,
  );

  RecordDraft draft({DraftKind kind = DraftKind.expense, String? wallet = 'bca'}) =>
      RecordDraft(kind: kind, amountSen: 2500000, walletId: wallet, note: 'KOPI');

  BudgetItemOption? suggest(
    List<BudgetItemOption> options, {
    RecordDraft? d,
    String text = 'Bayar Makan siang Rp25.000',
  }) => suggestBudgetItem(draft: d ?? draft(), date: date, text: text, options: options);

  test('nama pos yang muncul di teks disarankan', () {
    expect(suggest([option('i1', 'Makan'), option('i2', 'Bensin')])?.itemId, 'i1');
  });

  test('lebih dari satu pos cocok: ambigu, tanpa saran', () {
    expect(suggest([option('i1', 'Makan'), option('i2', 'Siang')]), isNull);
  });

  test('pos sama di dua anggaran berbeda id: ambigu; satu pos saja tetap disarankan', () {
    expect(suggest([option('i1', 'Makan'), option('i9', 'Makan')]), isNull);
    expect(suggest([option('i1', 'Makan'), option('i1', 'Makan')])?.itemId, 'i1');
  });

  test('kata utuh saja: "Makanan" tidak cocok dengan pos "Makan"', () {
    expect(suggest([option('i1', 'Makan')], text: 'Makanan Rp25.000'), isNull);
  });

  test('syarat: pengeluaran, dompet sama, belum diarsipkan, bukan transfer, mencakup tanggal', () {
    final base = [option('i1', 'Makan')];
    expect(suggest(base, d: draft(kind: DraftKind.income)), isNull);
    expect(suggest(base, d: draft(wallet: 'bri')), isNull);
    expect(suggest(base, d: draft(wallet: null)), isNull);
    expect(suggest([option('i1', 'Makan', archived: true)]), isNull);
    expect(suggest([option('i1', 'Makan', transferTo: 'bri')]), isNull);
    expect(suggest([option('i1', 'Makan', start: DateTime(2026, 12), end: DateTime(2027))]), isNull);
  });

  test('nama pos terlalu pendek (kurang dari 3 huruf) tidak dipakai', () {
    expect(suggest([option('i1', 'Ke')], text: 'Bayar ke warung Rp25.000'), isNull);
  });

  test('tanpa nama di teks: pos yang diingat untuk pedagang itu (nama sama, id berbeda tiap periode)', () {
    final options = [option('i7', 'Makan'), option('i8', 'Bensin')];
    final d = draft();
    expect(
      suggestBudgetItem(
        draft: d,
        date: date,
        text: 'Bayar KOPI Rp25.000',
        options: options,
        rememberedName: 'makan',
      )?.itemId,
      'i7',
    );
    expect(suggestBudgetItem(draft: d, date: date, text: 'Bayar KOPI', options: options), isNull);
    expect(
      suggestBudgetItem(draft: d, date: date, text: 'Bayar KOPI', options: options, rememberedName: 'hiburan'),
      isNull,
      reason: 'pos yang diingat tidak ada periode ini',
    );
  });

  test('nama di teks mengalahkan ingatan', () {
    final options = [option('i1', 'Makan'), option('i2', 'Bensin')];
    expect(
      suggestBudgetItem(
        draft: draft(),
        date: date,
        text: 'Isi Bensin',
        options: options,
        rememberedName: 'Makan',
      )?.itemId,
      'i2',
    );
  });

  group('CaptureInboxActions.rememberBudgetItem', () {
    late InMemoryKeyValueStorage storage;
    late StoreBackedMerchantMemory memory;

    setUp(() {
      storage = InMemoryKeyValueStorage();
      memory = StoreBackedMerchantMemory(MerchantMemoryStoreImpl(storage: storage));
    });

    CaptureInboxEntry entry() => CaptureInboxEntry(
      id: 'e1',
      packageName: 'app.a',
      appLabel: 'App A',
      text: 'Pembayaran Rp25.000 ke KOPI berhasil',
      capturedAt: DateTime(2026, 11, 10),
      draft: draft(),
    );

    CaptureInboxActions actions(List<BudgetItemOption> options) {
      final ledger = TransactionRepositoryImpl(storage: storage);
      final wallets = WalletRepositoryImpl(storage: storage);
      return CaptureInboxActions(
        store: NotificationCaptureStoreImpl(storage: storage),
        merchantMemory: memory,
        budgetItems: _Catalog(options),
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
      );
    }

    test('pos dipilih di CATAT: nama diingat; kartu berikutnya dari pedagang itu disarankan pos itu', () async {
      final a = actions([option('i7', 'Makan')]);
      final learned = await a.rememberBudgetItem(entry(), budgetItemId: 'i7', suggestedItemId: null);

      expect(learned?.name, 'Makan');
      // Bulan depan: id pos baru, nama sama.
      final next = actions([option('i99', 'Makan')]);
      final suggestions = await next.budgetSuggestionsFor([entry()], const {});
      expect(suggestions['e1']?.itemId, 'i99');
    });

    test('Batalkan melupakan; sama dengan saran, tanpa pos, atau tanpa catatan: tidak belajar', () async {
      final a = actions([option('i7', 'Makan')]);
      final learned = await a.rememberBudgetItem(entry(), budgetItemId: 'i7', suggestedItemId: null);
      await learned!.undo();
      expect(memory.budgetNameFor(packageName: 'app.a', note: 'KOPI'), isNull);

      expect(await a.rememberBudgetItem(entry(), budgetItemId: 'i7', suggestedItemId: 'i7'), isNull);
      expect(await a.rememberBudgetItem(entry(), budgetItemId: null, suggestedItemId: null), isNull);
      final noNote = CaptureInboxEntry(
        id: 'e2',
        packageName: 'app.a',
        appLabel: 'App A',
        text: 'x',
        capturedAt: DateTime(2026, 11, 10),
        draft: const RecordDraft(kind: DraftKind.expense, amountSen: 100, walletId: 'bca'),
      );
      expect(await a.rememberBudgetItem(noNote, budgetItemId: 'i7', suggestedItemId: null), isNull);
    });

    test('ingatan pos tidak mengganggu ingatan kategori untuk pedagang yang sama', () async {
      final a = actions([option('i7', 'Makan')]);
      await memory.remember(packageName: 'app.a', note: 'KOPI', categoryId: 'builtin.food');
      await a.rememberBudgetItem(entry(), budgetItemId: 'i7', suggestedItemId: null);
      expect(memory.categoryFor(packageName: 'app.a', note: 'KOPI'), 'builtin.food');
      expect(memory.budgetNameFor(packageName: 'app.a', note: 'KOPI'), 'Makan');
    });
  });
}

final class _Catalog implements BudgetItemCatalog {
  _Catalog(this.options);

  final List<BudgetItemOption> options;

  @override
  Future<Either<Failure, List<BudgetItemOption>>> listOptions() async => right(options);
}
