import 'dart:typed_data';

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/features/notification_capture/data/notification_capture_store_impl.dart';
import 'package:saldough/features/notification_capture/domain/entities/capture_inbox_entry.dart';
import 'package:saldough/features/notification_capture/domain/entities/captured_notification.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_capture_settings.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_pattern.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_source.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_store.dart';
import 'package:saldough/features/notification_capture/domain/usecases/capture_inbox_actions.dart';
import 'package:saldough/features/notification_capture/domain/usecases/process_captured_notifications.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

import '../../../helpers/fake_notification_capture_gateway.dart';
import 'notification_fixtures.dart';

void main() {
  late InMemoryKeyValueStorage storage;
  late NotificationCaptureStoreImpl store;
  late WalletRepositoryImpl wallets;
  late TransactionRepositoryImpl ledger;
  late FakeNotificationCaptureGateway gateway;
  late RecordTransaction recordTransaction;
  final now = DateTime(2026, 10, 1, 15);
  var nextId = 0;

  ProcessCapturedNotifications processor() => ProcessCapturedNotifications(
    gateway: gateway,
    store: store,
    composer: notificationComposer(),
    recordTransaction: recordTransaction,
    walletRepository: wallets,
    transactionRepository: ledger,
    categories: () => notificationCategories,
    currencyCode: () => 'IDR',
    languageCode: () => 'id',
    sourceIcons: SourceIconRepositoryImpl(storage: storage),
    clock: () => now,
    newId: () => 'tx${nextId++}',
  );

  CaptureInboxActions actions() => CaptureInboxActions(
    store: store,
    recordTransaction: recordTransaction,
    transactionRepository: ledger,
    composer: notificationComposer(),
    walletRepository: wallets,
    categories: () => notificationCategories,
    currencyCode: () => 'IDR',
    languageCode: () => 'id',
  );

  Future<void> enable(AutoRecordLevel level, {List<NotificationSource> sources = const [brimoSource]}) =>
      store.saveSettings(NotificationCaptureSettings(enabled: true, autoRecordLevel: level, sources: sources));

  CapturedNotification notif(
    String id,
    String body, {
    String pkg = 'id.co.bri.brimo',
    DateTime? at,
    Uint8List? icon,
  }) => CapturedNotification(
    id: id,
    packageName: pkg,
    title: 'BRImo',
    body: body,
    postedAt: at ?? DateTime(2026, 10, 1, 14),
    icon: icon,
  );

  Future<List<Transaction>> ledgerNow() async => (await ledger.listTransactionsInMonth(now)).getOrElse((_) => []);

  setUp(() async {
    storage = InMemoryKeyValueStorage();
    store = NotificationCaptureStoreImpl(storage: storage);
    wallets = WalletRepositoryImpl(storage: storage);
    ledger = TransactionRepositoryImpl(storage: storage);
    gateway = FakeNotificationCaptureGateway();
    recordTransaction = RecordTransaction(
      transactionRepository: ledger,
      recomputeWalletBalances: RecomputeWalletBalances(walletRepository: wallets, transactionRepository: ledger),
      ledgerChanges: LedgerChanges(),
    );
    for (final w in notificationWallets) {
      await wallets.saveWallet(w);
    }
  });

  const payment = 'Pembayaran Rp25.000 ke KOPI KENANGAN berhasil. Saldo Rp1.234.567';

  test('tingkat 1: semua ke kotak masuk, tidak ada transaksi, antrean di-ack', () async {
    await enable(AutoRecordLevel.reviewAll);
    gateway.queue = [notif('a', payment)];
    final result = await processor()();
    expect(result.recorded, isEmpty);
    expect(result.queued.single.draft.amountSen, 2500000);
    expect(await ledgerNow(), isEmpty);
    expect(gateway.acked, ['a']);
    expect((await store.loadInbox()).getOrElse((_) => []).single.id, 'a');
  });

  test('tingkat 2: draf lengkap tercatat lewat RecordTransaction, saldo dompet ikut', () async {
    await enable(AutoRecordLevel.whenComplete);
    gateway.queue = [notif('a', payment)];
    final result = await processor()();
    expect(result.recorded.single.amountSen, 2500000);
    final tx = (await ledgerNow()).single as ExpenseTransaction;
    expect(tx.walletId, 'bri');
    expect(tx.amount, 2500000);
    final bri = (await wallets.listWallets()).getOrElse((_) => []).firstWhere((w) => w.id == 'bri');
    expect(bri.currentBalance, -2500000);
    expect((await store.loadAutoRecorded()).getOrElse((_) => []).single.transactionId, tx.id);
  });

  test('ikon notifikasi disimpan sekali; id-nya ikut transaksi, log otomatis, dan kotak masuk', () async {
    final icon = Uint8List.fromList([137, 80, 78, 71, 1, 2, 3]);
    await enable(AutoRecordLevel.whenComplete);
    gateway.queue = [
      notif('a', payment, icon: icon),
      notif('b', 'Transaksi Rp50.000 berhasil', at: DateTime(2026, 10, 1, 15), icon: icon),
    ];
    await processor()();
    final id = sourceIconIdOf(icon);
    expect((await ledgerNow()).single.sourceIconId, id);
    expect((await store.loadAutoRecorded()).getOrElse((_) => []).single.iconId, id);
    final pending = (await store.loadInbox()).getOrElse((_) => []).single;
    expect(pending.iconId, id);
    // Dibawa draf ke CATAT (Catat dari kotak masuk).
    expect(pending.draft.sourceIconId, id);
    expect((await SourceIconRepositoryImpl(storage: storage).read(id)).getOrElse((_) => null), icon);
  });

  test('tingkat 2 tanpa kategori → kotak masuk; tingkat 3 → tercatat', () async {
    const noCategory = 'Pembayaran Rp40.000 ke PT ABC berhasil';
    await enable(AutoRecordLevel.whenComplete);
    gateway.queue = [notif('a', noCategory)];
    expect((await processor()()).queued, hasLength(1));
    await enable(AutoRecordLevel.whenAmountAndWallet);
    gateway.queue = [notif('b', noCategory, at: DateTime(2026, 10, 1, 9))];
    expect((await processor()()).recorded, hasLength(1));
  });

  test('ragu (tanpa kata arah) → kotak masuk walau tingkat 3', () async {
    await enable(AutoRecordLevel.whenAmountAndWallet);
    gateway.queue = [notif('a', 'Transaksi Rp50.000 berhasil')];
    final result = await processor()();
    expect(result.recorded, isEmpty);
    expect(result.queued, hasLength(1));
  });

  test('dugaan ganda dengan buku besar → kotak masuk bertanda', () async {
    await enable(AutoRecordLevel.whenComplete);
    await ledger.saveTransaction(
      ExpenseTransaction(id: 'old', date: DateTime(2026, 10, 1, 8), amount: 2500000, note: '', walletId: 'bri'),
    );
    gateway.queue = [notif('a', payment)];
    final result = await processor()();
    expect(result.recorded, isEmpty);
    expect(result.queued.single.possibleDuplicate, isTrue);
  });

  test('id yang sudah diproses tidak dicatat dua kali (crash sebelum ack)', () async {
    await enable(AutoRecordLevel.whenComplete);
    gateway
      ..queue = [notif('a', payment)]
      ..failAck = true;
    await processor()();
    await processor()();
    expect(await ledgerNow(), hasLength(1));
  });

  test('simpan kotak masuk gagal → berhenti, tangkapan tidak di-ack (tidak hilang)', () async {
    await enable(AutoRecordLevel.reviewAll);
    gateway.queue = [notif('a', payment), notif('b', payment, at: DateTime(2026, 10, 1, 9))];
    final failing = _FailingInboxStore(store);
    ProcessCapturedNotifications withStore(NotificationCaptureStore s) => ProcessCapturedNotifications(
      gateway: gateway,
      store: s,
      composer: notificationComposer(),
      recordTransaction: recordTransaction,
      walletRepository: wallets,
      transactionRepository: ledger,
      categories: () => notificationCategories,
      currencyCode: () => 'IDR',
      languageCode: () => 'id',
      clock: () => now,
    );
    final result = await withStore(failing)();
    expect(result.queued, isEmpty);
    expect(gateway.acked, isEmpty);
    expect((await store.loadProcessedIds()).getOrElse((_) => {}), isEmpty);

    // Penyimpanan pulih: putaran berikutnya memproses keduanya.
    failing.fail = false;
    expect((await withStore(failing)()).queued, hasLength(2));
    expect(gateway.acked, containsAll(['a', 'b']));
  });

  test('OTP, sumber tidak terdaftar, dan kata kunci tidak cocok diabaikan tanpa disimpan', () async {
    await enable(
      AutoRecordLevel.whenComplete,
      sources: [
        brimoSource.copyWith(keywords: ['berhasil']),
      ],
    );
    gateway.queue = [
      notif('otp', 'Kode OTP 123456 untuk pembayaran Rp25.000 berhasil. Jangan berikan'),
      notif('other', payment, pkg: 'com.lain'),
      notif('kw', 'Pembayaran Rp10.000 diproses'),
    ];
    final result = await processor()();
    expect(result.isEmpty, isTrue);
    expect((await store.loadInbox()).getOrElse((_) => []), isEmpty);
    expect(gateway.acked, containsAll(['otp', 'other', 'kw']));
  });

  test('whitelist: filter kosong tidak menangkap apa pun; filter bawaan menolak promo', () async {
    const promo = 'Diskon hingga Rp50.000 pakai voucher! Yuk bayar pakai BRImo';
    const paid = 'Pembayaran berhasil Rp25.000 ke KOPI KENANGAN. Saldo Rp1.234.567';
    expect(brimoSource.copyWith(keywords: []).matchesKeywords(paid), isFalse);
    final defaults = brimoSource.copyWith(keywords: defaultNotificationKeywords);
    expect(defaults.matchesKeywords(promo), isFalse);
    expect(defaults.matchesKeywords(paid), isTrue);

    await enable(AutoRecordLevel.reviewAll, sources: [defaults]);
    gateway.queue = [notif('promo', promo), notif('paid', paid)];
    final result = await processor()();
    expect([for (final e in result.queued) e.id], ['paid']);
  });

  test('fitur mati → antrean tidak disentuh', () async {
    gateway.queue = [notif('a', payment)];
    await processor()();
    expect(gateway.acked, isEmpty);
  });

  test('pemicu ganda digabung, tidak paralel', () async {
    await enable(AutoRecordLevel.reviewAll);
    gateway.queue = [notif('a', payment)];
    final p = processor();
    final results = await Future.wait([p(), p()]);
    expect(results.first.queued, hasLength(1));
    expect((await store.loadInbox()).getOrElse((_) => []), hasLength(1));
  });

  test('Batalkan menghapus transaksi otomatis dan memulihkan saldo', () async {
    await enable(AutoRecordLevel.whenComplete);
    gateway.queue = [notif('a', payment)];
    final entry = (await processor()()).recorded.single;
    expect((await actions().undo(entry)).isRight(), isTrue);
    expect(await ledgerNow(), isEmpty);
    final bri = (await wallets.listWallets()).getOrElse((_) => []).firstWhere((w) => w.id == 'bri');
    expect(bri.currentBalance, 0);
    expect((await store.loadAutoRecorded()).getOrElse((_) => []), isEmpty);
  });

  test('entri lebih dari 7 hari dipangkas', () async {
    await enable(AutoRecordLevel.reviewAll);
    gateway.queue = [notif('a', payment, at: DateTime(2026, 9, 20))];
    await processor()();
    gateway.queue = [];
    await processor()();
    expect((await store.loadInbox()).getOrElse((_) => []), isEmpty);
  });
}

/// [NotificationCaptureStore] yang gagal menyimpan kotak masuk selama [fail].
final class _FailingInboxStore implements NotificationCaptureStore {
  _FailingInboxStore(this._inner);

  final NotificationCaptureStore _inner;
  bool fail = true;

  @override
  Future<Either<Failure, Unit>> saveInbox(List<CaptureInboxEntry> entries) async =>
      fail ? const Left(SystemFailure(code: FailureCode.unknown, message: 'disk penuh')) : _inner.saveInbox(entries);

  @override
  Future<Either<Failure, NotificationCaptureSettings>> loadSettings() => _inner.loadSettings();

  @override
  Future<Either<Failure, Unit>> saveSettings(NotificationCaptureSettings settings) => _inner.saveSettings(settings);

  @override
  Future<Either<Failure, List<NotificationPattern>>> loadPatterns() => _inner.loadPatterns();

  @override
  Future<Either<Failure, Unit>> savePatterns(List<NotificationPattern> patterns) => _inner.savePatterns(patterns);

  @override
  Future<Either<Failure, List<CaptureInboxEntry>>> loadInbox() => _inner.loadInbox();

  @override
  Future<Either<Failure, List<AutoRecordedEntry>>> loadAutoRecorded() => _inner.loadAutoRecorded();

  @override
  Future<Either<Failure, Unit>> saveAutoRecorded(List<AutoRecordedEntry> entries) => _inner.saveAutoRecorded(entries);

  @override
  Future<Either<Failure, Map<String, DateTime>>> loadProcessedIds() => _inner.loadProcessedIds();

  @override
  Future<Either<Failure, Unit>> saveProcessedIds(Map<String, DateTime> ids) => _inner.saveProcessedIds(ids);
}
