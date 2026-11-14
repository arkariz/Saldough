import 'package:di/di.dart' show GetIt;
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/app/dev_seed/notification_inbox_seed_pack.dart';
import 'package:saldough/app/dev_seed/seed_pack.dart';
import 'package:saldough/app/dev_seed/wallet_seed_pack.dart';
import 'package:saldough/features/notification_capture/data/notification_capture_store_impl.dart';
import 'package:saldough/features/notification_capture/domain/entities/capture_inbox_entry.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_capture_settings.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_store.dart';
import 'package:saldough/features/notification_capture/domain/services/capture_inbox_changes.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

void main() {
  final now = DateTime(2026, 11, 11, 10);
  late GetIt c;
  late NotificationCaptureStore store;

  setUp(() {
    final storage = InMemoryKeyValueStorage();
    store = NotificationCaptureStoreImpl(storage: storage);
    c = GetIt.asNewInstance()
      ..registerSingleton<WalletRepository>(WalletRepositoryImpl(storage: storage))
      ..registerSingleton<TransactionRepository>(TransactionRepositoryImpl(storage: storage))
      ..registerSingleton<NotificationCaptureStore>(store)
      ..registerSingleton<CaptureInboxChanges>(CaptureInboxChanges())
      ..registerSingleton<LedgerChanges>(LedgerChanges());
  });

  test('lima draf dengan alasan peninjauan berbeda, semuanya dalam retensi 7 hari', () async {
    await const NotificationInboxSeedPack().applyAt(c, now);
    final inbox = (await store.loadInbox()).getOrElse((_) => []);
    expect(inbox.length, 5);
    expect(inbox.map((e) => e.reviewReason).whereType<CaptureReviewReason>().toSet(), {
      CaptureReviewReason.categoryUnclear,
      CaptureReviewReason.walletUnknown,
      CaptureReviewReason.amountUnclear,
      CaptureReviewReason.kindUnclear,
    });
    expect(inbox.where((e) => e.possibleDuplicate).length, 1);
    expect(inbox.every((e) => !CaptureRetention.expired(e.capturedAt, now)), isTrue);
    expect(inbox.every((e) => e.text.isNotEmpty && e.draft.sourceText == e.text), isTrue);
  });

  test('empat tercatat otomatis punya transaksi nyata dan saldo dompet ikut berkurang', () async {
    await const NotificationInboxSeedPack().applyAt(c, now);
    final log = (await store.loadAutoRecorded()).getOrElse((_) => []);
    expect(log.length, 4);
    expect(log.where((e) => e.isNew).length, 1);
    final all = (await c<TransactionRepository>().listAllTransactions()).getOrElse((_) => []);
    for (final entry in log) {
      final tx = all.singleWhere((t) => t.id == entry.transactionId);
      expect(tx.amount, entry.amountSen);
    }
    final wallets = {for (final w in (await c<WalletRepository>().listWallets()).getOrElse((_) => [])) w.id: w};
    final spentMingguan = log
        .where((e) => (all.singleWhere((t) => t.id == e.transactionId) as ExpenseTransaction).walletId == SeedIds.walletMingguan)
        .fold(0, (a, e) => a + e.amountSen);
    final mingguan = WalletSeedPack.wallets.firstWhere((w) => w.id == SeedIds.walletMingguan);
    expect(wallets[SeedIds.walletMingguan]!.currentBalance, mingguan.initialBalance - spentMingguan);
  });

  test('setelan diisi bila masih bawaan, tidak ditimpa bila sudah disetel', () async {
    await const NotificationInboxSeedPack().applyAt(c, now);
    final seeded = (await store.loadSettings()).getOrElse((_) => const NotificationCaptureSettings());
    expect(seeded.enabled, isTrue);
    expect(seeded.sources.length, 4);

    final storage = InMemoryKeyValueStorage();
    final other = NotificationCaptureStoreImpl(storage: storage);
    await other.saveSettings(const NotificationCaptureSettings(enabled: true));
    final c2 = GetIt.asNewInstance()
      ..registerSingleton<WalletRepository>(WalletRepositoryImpl(storage: storage))
      ..registerSingleton<TransactionRepository>(TransactionRepositoryImpl(storage: storage))
      ..registerSingleton<NotificationCaptureStore>(other)
      ..registerSingleton<CaptureInboxChanges>(CaptureInboxChanges())
      ..registerSingleton<LedgerChanges>(LedgerChanges());
    await const NotificationInboxSeedPack().applyAt(c2, now);
    final kept = (await other.loadSettings()).getOrElse((_) => const NotificationCaptureSettings());
    expect(kept.sources, isEmpty);
    expect(kept.autoRecordLevel, AutoRecordLevel.reviewAll);
  });

  test('diterapkan ulang di hari yang sama tidak menggandakan; hari lain menambah data segar', () async {
    await const NotificationInboxSeedPack().applyAt(c, now);
    final again = await const NotificationInboxSeedPack().applyAt(c, now.add(const Duration(hours: 2)));
    expect(again.added, 0);
    expect((await store.loadInbox()).getOrElse((_) => []).length, 5);
    await const NotificationInboxSeedPack().applyAt(c, now.add(const Duration(days: 1)));
    expect((await store.loadInbox()).getOrElse((_) => []).length, 10);
    expect((await store.loadAutoRecorded()).getOrElse((_) => []).length, 8);
  });

  test('notifikasi perubahan dikirim ke kotak masuk dan buku besar', () async {
    var inboxSignals = 0;
    var ledgerSignals = 0;
    c<CaptureInboxChanges>().stream.listen((_) => inboxSignals++);
    c<LedgerChanges>().changes.listen((_) => ledgerSignals++);
    await const NotificationInboxSeedPack().applyAt(c, now);
    await Future<void>.delayed(Duration.zero);
    expect(inboxSignals, 1);
    expect(ledgerSignals, greaterThanOrEqualTo(1));
  });
}
