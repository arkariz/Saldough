import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/features/notification_capture/data/approved_shape_store_impl.dart';
import 'package:saldough/features/notification_capture/data/notification_capture_store_impl.dart';
import 'package:saldough/features/notification_capture/domain/entities/capture_inbox_entry.dart';
import 'package:saldough/features/notification_capture/domain/entities/captured_notification.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_capture_settings.dart';
import 'package:saldough/features/notification_capture/domain/services/approved_shapes.dart';
import 'package:saldough/features/notification_capture/domain/services/capture_resolver.dart';
import 'package:saldough/features/notification_capture/domain/usecases/capture_inbox_actions.dart';
import 'package:saldough/features/notification_capture/domain/usecases/process_captured_notifications.dart';
import 'package:saldough/shared/capture/capture.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

import '../../../helpers/fake_notification_capture_gateway.dart';
import 'notification_fixtures.dart';

/// Catat otomatis per bentuk (ADR-044 §3.7, E3/B-87).
void main() {
  const pkg = 'id.co.bri.brimo';
  const payment = 'Pembayaran Rp25.000 ke KOPI KENANGAN berhasil. Saldo Rp1.234.567';

  group('templat dan pagar', () {
    test('pedagang di teks jadi {note}: pedagang lain dengan bentuk sama ikut cocok', () {
      final template = approvedTemplateFor(payment, 'KOPI KENANGAN');
      expect(template, 'Pembayaran {amount} ke {note} berhasil. Saldo {*}');
    });

    test('pedagang tidak ditemukan di teks: tetap literal; tanpa nominal: tidak ada templat', () {
      expect(approvedTemplateFor(payment, 'WARUNG'), 'Pembayaran {amount} ke KOPI KENANGAN berhasil. Saldo {*}');
      expect(approvedTemplateFor('Halo selamat datang', 'X'), isNull);
    });

    test('median dan pagar: tanpa 3 contoh tidak ada pagar; di atas 10x median ditinjau', () {
      ApprovedShape shape(List<int> amounts) =>
          ApprovedShape(packageName: pkg, template: 't', approvedAt: DateTime(2026, 11), amounts: amounts);
      expect(medianOf([1, 5, 3]), 3);
      expect(medianOf([2, 4]), 3);
      expect(isUnusualShapeAmount(shape([2500000, 2500000]), 900000000), isFalse, reason: 'baru 2 contoh');
      final s = shape([2500000, 2500000, 3000000]);
      expect(isUnusualShapeAmount(s, 25000000), isFalse, reason: 'tepat 10x tidak lewat pagar');
      expect(isUnusualShapeAmount(s, 25000001), isTrue);
    });
  });

  group('mesin tanpa layar mencatat sendiri (mayAutoRecordFromWorker)', () {
    final shape = ApprovedShape(
      packageName: pkg,
      template: 't',
      approvedAt: DateTime(2026, 11),
      amounts: const [2500000, 2500000, 3000000],
    );
    const draft = RecordDraft(kind: DraftKind.expense, amountSen: 2500000, walletId: 'bri', note: 'KOPI');
    bool may({
      ApprovedShape? s,
      RecordDraft d = draft,
      PlanResolution plan = PlanResolution.none,
      bool duplicate = false,
    }) => mayAutoRecordFromWorker(shape: s, draft: d, plan: plan, duplicate: duplicate);

    test('bentuk disetujui, draf lengkap, tanpa kembar: boleh', () {
      expect(may(s: shape), isTrue);
    });

    test('tanpa persetujuan, kembar, atau nominal/dompet kosong: tidak', () {
      expect(may(), isFalse);
      expect(may(s: shape, duplicate: true), isFalse);
      expect(
        may(
          s: shape,
          d: const RecordDraft(kind: DraftKind.expense, walletId: 'bri'),
        ),
        isFalse,
      );
      expect(
        may(
          s: shape,
          d: const RecordDraft(kind: DraftKind.expense, amountSen: 100),
        ),
        isFalse,
      );
    });

    test('nominal jauh di atas kebiasaan: tidak', () {
      expect(
        may(
          s: shape,
          d: const RecordDraft(kind: DraftKind.expense, amountSen: 90000000, walletId: 'bri'),
        ),
        isFalse,
      );
    });

    test('rutin meragukan (beberapa kemunculan cocok, tak terputus): tidak', () {
      expect(may(s: shape, plan: const PlanResolution(ambiguous: true)), isFalse);
    });
  });

  group('simpanan dan pemroses', () {
    late InMemoryKeyValueStorage storage;
    late StoreBackedApprovedShapes shapes;
    late NotificationCaptureStoreImpl store;
    late WalletRepositoryImpl wallets;
    late TransactionRepositoryImpl ledger;
    late FakeNotificationCaptureGateway gateway;
    late RecordTransaction recordTransaction;

    setUp(() async {
      storage = InMemoryKeyValueStorage();
      shapes = StoreBackedApprovedShapes(
        ApprovedShapeStoreImpl(storage: storage),
        clock: () => DateTime(2026, 11, 5),
      );
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

    var seq = 0;
    CapturedNotification notif(String body) => CapturedNotification(
      id: 'n${seq++}',
      packageName: pkg,
      title: '',
      body: body,
      postedAt: DateTime(2026, 10, 1, 14).add(Duration(hours: seq)),
    );

    ProcessCapturedNotifications processor({bool plus = true}) => ProcessCapturedNotifications(
      gateway: gateway,
      store: store,
      composer: notificationComposer(),
      recordTransaction: recordTransaction,
      walletRepository: wallets,
      transactionRepository: ledger,
      categories: () => notificationCategories,
      currencyCode: () => 'IDR',
      languageCode: () => 'id',
      approvedShapes: shapes,
      isPlus: () => plus,
      clock: () => DateTime(2026, 10, 2),
      newId: () => 'tx${seq++}',
    );

    String pay(String amount, [String merchant = 'WARUNG MAKAN']) =>
        'Pembayaran Rp$amount ke $merchant berhasil. Saldo Rp1.234.567';

    Future<List<AutoRecordedEntry>> autos() async => (await store.loadAutoRecorded()).getOrElse((_) => const []);
    Future<List<CaptureInboxEntry>> inbox() async => (await store.loadInbox()).getOrElse((_) => const []);

    test('tanpa persetujuan dan tingkat global mati: masuk kotak masuk', () async {
      gateway.queue = [notif(pay('25.000'))];
      await processor()();
      expect(await autos(), isEmpty);
      expect(await inbox(), hasLength(1));
    });

    test(
      'bentuk disetujui: pedagang lain tercatat otomatis walau tingkat global mati; dua pertama bertanda baru',
      () async {
        await shapes.approve(packageName: pkg, text: payment, note: 'KOPI KENANGAN', amountSen: 2500000);
        gateway.queue = [notif(pay('25.000')), notif(pay('30.000', 'BAKSO')), notif(pay('27.000', 'SATE'))];
        await processor()();

        final auto = (await autos()).reversed.toList();
        expect(auto, hasLength(3));
        expect(auto.map((e) => e.isNew), [true, true, false]);
        expect(await inbox(), isEmpty);
        expect((await ledger.listTransactionsInMonth(DateTime(2026, 10))).getOrElse((_) => const []), hasLength(3));
      },
    );

    test('nominal di atas 10x median: ditinjau dengan alasan, tidak dicatat otomatis', () async {
      await shapes.approve(packageName: pkg, text: payment, note: 'KOPI KENANGAN', amountSen: 2500000);
      gateway.queue = [notif(pay('25.000')), notif(pay('30.000'))];
      await processor()();
      expect(await autos(), hasLength(2));

      gateway.queue = [notif(pay('300.000'))];
      await processor()();

      expect(await autos(), hasLength(2));
      final cards = await inbox();
      expect(cards.single.reviewReason, CaptureReviewReason.amountUnusual);
      expect(cards.single.draft.amountSen, 30000000);
    });

    test('Gratis: bentuk disetujui tidak mencatat otomatis', () async {
      await shapes.approve(packageName: pkg, text: payment, note: 'KOPI KENANGAN', amountSen: 2500000);
      gateway.queue = [notif(pay('25.000'))];
      await processor(plus: false)();
      expect(await autos(), isEmpty);
      expect(await inbox(), hasLength(1));
    });

    test('Batalkan melupakan persetujuan; menyetujui dua kali tidak menggandakan', () async {
      final undo = await shapes.approve(packageName: pkg, text: payment, note: 'KOPI KENANGAN', amountSen: 2500000);
      await shapes.approve(packageName: pkg, text: payment, note: 'KOPI KENANGAN', amountSen: 2500000);
      expect((await ApprovedShapeStoreImpl(storage: storage).load()).getOrElse((_) => const []), hasLength(1));
      await undo!();
      await shapes.refresh();
      expect(shapes.isApproved(pkg, payment), isFalse);
    });

    test('hanya 20 nominal terakhir diingat', () async {
      await shapes.approve(packageName: pkg, text: payment, note: 'KOPI KENANGAN', amountSen: 100);
      for (var i = 1; i <= 25; i++) {
        await shapes.recordAuto(shapes.find(pkg, payment)!, 100 + i);
      }
      final shape = shapes.find(pkg, payment)!;
      expect(shape.amounts, hasLength(approvedShapeAmountWindow));
      expect(shape.amounts.last, 125);
      expect(shape.autoCount, 25);
    });

    group('tawaran sesudah Simpan', () {
      CaptureInboxEntry entry() => CaptureInboxEntry(
        id: 'e1',
        packageName: pkg,
        appLabel: 'BRImo',
        text: payment,
        capturedAt: DateTime(2026, 10, 1, 14),
        draft: const RecordDraft(kind: DraftKind.expense, amountSen: 2500000, walletId: 'bri', note: 'KOPI KENANGAN'),
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
        approvedShapes: shapes,
      );

      Future<String?> offer({
        DraftKind? kind = DraftKind.expense,
        int? amount = 2500000,
        String? wallet = 'bri',
      }) => actions().autoOfferFor(entry(), savedKind: kind, savedAmountSen: amount, savedWalletId: wallet);

      test('tak diubah (jenis, dompet, nominal): ada tawaran dengan templat bentuk', () async {
        expect(await offer(), 'Pembayaran {amount} ke {note} berhasil. Saldo {*}');
      });

      test('nominal, dompet, atau jenis diubah: tidak ada tawaran', () async {
        expect(await offer(amount: 3000000), isNull);
        expect(await offer(wallet: 'bca'), isNull);
        expect(await offer(kind: DraftKind.income), isNull);
        expect(await offer(kind: null), isNull);
      });

      test('Ya menyetujui; sesudahnya tidak ditawarkan lagi', () async {
        final undo = await actions().approveShape(entry(), amountSen: 2500000);
        expect(undo, isNotNull);
        expect(await offer(), isNull);
        await undo!();
        expect(await offer(), isNotNull);
      });
    });
  });
}
