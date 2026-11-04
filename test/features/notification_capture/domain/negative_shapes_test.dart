import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/features/notification_capture/data/negative_shape_store_impl.dart';
import 'package:saldough/features/notification_capture/data/notification_capture_store_impl.dart';
import 'package:saldough/features/notification_capture/domain/entities/capture_inbox_entry.dart';
import 'package:saldough/features/notification_capture/domain/entities/captured_notification.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_capture_settings.dart';
import 'package:saldough/features/notification_capture/domain/services/negative_shapes.dart';
import 'package:saldough/features/notification_capture/domain/usecases/capture_inbox_actions.dart';
import 'package:saldough/features/notification_capture/domain/usecases/process_captured_notifications.dart';
import 'package:saldough/shared/capture/capture.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

import '../../../helpers/fake_notification_capture_gateway.dart';
import 'notification_fixtures.dart';

/// Bentuk yang bukan transaksi (ADR-044 §3.4, E1/B-85).
void main() {
  const promo = 'Diskon Rp50.000 untuk kamu hari ini. Kode 123456';

  test('templat: nominal pertama jadi {amount}, angka lain {*}; tanpa nominal tidak dipelajari', () {
    expect(negativeTemplateFor(promo), 'Diskon {amount} untuk kamu hari ini. Kode {*}');
    expect(negativeTemplateFor('Halo, selamat datang'), isNull);
  });

  late InMemoryKeyValueStorage storage;
  late StoreBackedNegativeShapes shapes;

  setUp(() {
    storage = InMemoryKeyValueStorage();
    shapes = StoreBackedNegativeShapes(NegativeShapeStoreImpl(storage: storage));
  });

  test('bentuk cocok untuk nominal dan kode lain dari aplikasi yang sama saja', () async {
    await shapes.add(packageName: 'app.a', text: promo);
    expect(shapes.matches('app.a', 'Diskon Rp75.000 untuk kamu hari ini. Kode 998877'), isTrue);
    expect(shapes.matches('app.b', promo), isFalse, reason: 'per aplikasi');
    expect(shapes.matches('app.a', 'Pembayaran Rp25.000 ke KOPI berhasil'), isFalse);
  });

  test('Batalkan melupakan bentuk; menambah dua kali tidak menggandakan', () async {
    final undo = await shapes.add(packageName: 'app.a', text: promo);
    await shapes.add(packageName: 'app.a', text: promo);
    expect((await NegativeShapeStoreImpl(storage: storage).load()).getOrElse((_) => const []), hasLength(1));
    await undo!();
    expect(shapes.matches('app.a', promo), isFalse);
  });

  test('penuh: yang tertua dibuang', () async {
    // Huruf, bukan angka: angka di kata menjadi {*} dan semua templat jadi sama.
    String name(int i) => String.fromCharCodes([97 + i ~/ 26, 97 + i % 26]);
    for (var i = 0; i < negativeShapeLimit + 2; i++) {
      await shapes.add(packageName: 'app.a', text: 'Promo ${name(i)} Rp1.000');
    }
    await shapes.refresh();
    expect(shapes.matches('app.a', 'Promo ${name(0)} Rp1.000'), isFalse);
    expect(shapes.matches('app.a', 'Promo ${name(negativeShapeLimit + 1)} Rp1.000'), isTrue);
  });

  group('pemroses dan aksi kartu', () {
    late NotificationCaptureStoreImpl store;
    late WalletRepositoryImpl wallets;
    late TransactionRepositoryImpl ledger;
    late FakeNotificationCaptureGateway gateway;
    late RecordTransaction recordTransaction;

    setUp(() async {
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
      await store.saveSettings(const NotificationCaptureSettings(enabled: true, sources: [brimoSource]));
    });

    CapturedNotification notif(String id, String body) => CapturedNotification(
      id: id,
      packageName: 'id.co.bri.brimo',
      title: '',
      body: body,
      postedAt: DateTime(2026, 10, 1, 14),
    );

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
      negativeShapes: shapes,
      clock: () => DateTime(2026, 10, 1, 15),
      newId: () => 'tx',
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
      negativeShapes: shapes,
    );

    CaptureInboxEntry entry(String text) => CaptureInboxEntry(
      id: 'e1',
      packageName: 'id.co.bri.brimo',
      appLabel: 'BRImo',
      text: text,
      capturedAt: DateTime(2026, 10, 1, 14),
      draft: const RecordDraft(kind: DraftKind.expense, amountSen: 5000000),
    );

    test('bentuk negatif dilewati diam-diam (tidak masuk kotak masuk) sampai dibatalkan', () async {
      await shapes.add(packageName: 'id.co.bri.brimo', text: 'Transaksi gagal Rp50.000 hari ini');
      gateway.queue = [notif('n1', 'Transaksi gagal Rp70.000 hari ini')];
      await processor()();
      expect((await store.loadInbox()).getOrElse((_) => const []), isEmpty);
      expect(gateway.queue, isEmpty, reason: 'tetap di-ack supaya tidak diproses lagi');
    });

    test('Bukan transaksi: kartu ditutup dan bentuknya dipelajari; Batalkan mengembalikan keduanya', () async {
      final e = entry(promo);
      await store.saveInbox([e]);
      final undo = await actions().markNotTransaction(e);
      expect((await store.loadInbox()).getOrElse((_) => const []), isEmpty);
      expect(shapes.matches('id.co.bri.brimo', promo), isTrue);
      await undo!();
      expect((await store.loadInbox()).getOrElse((_) => const []).map((x) => x.id), ['e1']);
      expect(shapes.matches('id.co.bri.brimo', promo), isFalse);
    });

    test('teks tanpa nominal: kartu ditutup tanpa belajar', () async {
      final e = entry('Halo, selamat datang');
      await store.saveInbox([e]);
      expect(await actions().markNotTransaction(e), isNull);
      expect((await store.loadInbox()).getOrElse((_) => const []), isEmpty);
    });
  });
}
