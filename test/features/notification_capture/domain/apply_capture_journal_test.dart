import 'dart:convert';
import 'dart:typed_data';

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/features/notification_capture/data/method_channel_notification_capture_gateway.dart';
import 'package:saldough/features/notification_capture/data/notification_capture_store_impl.dart';
import 'package:saldough/features/notification_capture/domain/entities/capture_inbox_entry.dart';
import 'package:saldough/features/notification_capture/domain/entities/capture_journal_record.dart';
import 'package:saldough/features/notification_capture/domain/entities/captured_notification.dart';
import 'package:saldough/features/notification_capture/domain/services/capture_finalizer.dart';
import 'package:saldough/features/notification_capture/domain/services/capture_inbox_codec.dart';
import 'package:saldough/features/notification_capture/domain/usecases/apply_capture_journal.dart';
import 'package:saldough/shared/budget_catalog/budget_catalog.dart';
import 'package:saldough/shared/capture/capture.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

import '../../../helpers/fake_notification_capture_gateway.dart';
import 'notification_fixtures.dart';

final class _Catalog implements BudgetItemCatalog {
  _Catalog(this.options);

  final List<BudgetItemOption> options;

  @override
  Future<Either<Failure, List<BudgetItemOption>>> listOptions() async => right(options);
}

void main() {
  late InMemoryKeyValueStorage storage;
  late NotificationCaptureStoreImpl store;
  late WalletRepositoryImpl wallets;
  late TransactionRepositoryImpl ledger;
  late RecurringRuleRepositoryImpl rules;
  late FakeNotificationCaptureGateway gateway;
  late RecordTransaction recordTransaction;
  final capturedAt = DateTime(2026, 11, 4, 10);
  final now = DateTime(2026, 11, 4, 12);

  ApplyCaptureJournal apply({BudgetItemCatalog? catalog}) => ApplyCaptureJournal(
    sourceIcons: SourceIconRepositoryImpl(storage: storage),
    gateway: gateway,
    store: store,
    recordTransaction: recordTransaction,
    transactionRepository: ledger,
    walletRepository: wallets,
    recurringRules: rules,
    finalizer: CaptureFinalizer(budgetItems: catalog),
    clock: () => now,
  );

  CaptureInboxEntry entry(
    String id, {
    String walletId = 'bri',
    int amount = 2500000,
    String? category = 'builtin.food',
  }) => CaptureInboxEntry(
    id: id,
    packageName: 'id.co.bri.brimo',
    appLabel: 'BRImo',
    text: 'Pembayaran Rp25.000 ke KOPI berhasil',
    capturedAt: capturedAt,
    draft: RecordDraft(
      kind: DraftKind.expense,
      amountSen: amount,
      walletId: walletId,
      categoryId: category,
      note: 'KOPI',
      date: capturedAt,
    ),
  );

  CaptureJournalRecord record(
    CaptureInboxEntry e, {
    String? decision = 'record',
    OccurrenceMatch? match,
    DateTime? resolvedAt,
  }) => CaptureJournalRecord(
    id: e.id,
    decision: decision,
    resolvedAt: resolvedAt ?? capturedAt,
    payload: jsonEncode({
      'entry': captureInboxEntryToJson(e),
      'match': ?(match == null
          ? null
          : {'ruleId': match.rule.id, 'date': match.date.toIso8601String(), 'exact': match.exact}),
    }),
  );

  Future<List<Transaction>> ledgerNow() async =>
      (await ledger.listTransactionsInMonth(capturedAt)).getOrElse((_) => []);

  setUp(() async {
    storage = InMemoryKeyValueStorage();
    store = NotificationCaptureStoreImpl(storage: storage);
    wallets = WalletRepositoryImpl(storage: storage);
    ledger = TransactionRepositoryImpl(storage: storage);
    rules = RecurringRuleRepositoryImpl(storage: storage);
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

  group('Catat', () {
    test('ikon aplikasi sumber dari antrean native menempel di transaksi', () async {
      final e = entry('n1');
      await store.saveInbox([e]);
      gateway
        ..queue = [
          CapturedNotification(
            id: 'n1',
            packageName: 'id.co.bri.brimo',
            title: '',
            body: 'x',
            postedAt: capturedAt,
            icon: Uint8List.fromList([1, 2, 3, 4]),
          ),
        ]
        ..journalRecords = [record(e)];

      await apply()();

      final tx = (await ledgerNow()).single;
      expect(tx.sourceIconId, isNotNull);
      final icon = (await SourceIconRepositoryImpl(storage: storage).read(tx.sourceIconId!)).getOrElse((_) => null);
      expect(icon, isNotNull);
    });

    test('transaksi dari draf dengan id dari id tangkapan; kartu, antrean, dan jurnal dibereskan', () async {
      final e = entry('n1');
      await store.saveInbox([e]);
      gateway.journalRecords = [record(e)];

      final result = await apply()();

      final tx = (await ledgerNow()).single as ExpenseTransaction;
      expect(result.recorded, 1);
      expect(tx.id, captureTransactionId('n1'));
      expect(tx.amount, 2500000);
      expect(tx.walletId, 'bri');
      expect(tx.categoryId, 'builtin.food');
      expect((await store.loadInbox()).getOrElse((_) => []), isEmpty);
      expect((await store.loadProcessedIds()).getOrElse((_) => {}).keys, contains('n1'));
      expect(gateway.acked, contains('n1'));
      expect(gateway.ackedJournal, ['n1']);
      expect(gateway.cancelledActionable, 1);
    });

    test('diterapkan dua kali (proses dimatikan sebelum ack jurnal): tetap satu transaksi', () async {
      final e = entry('n1');
      gateway.journalRecords = [record(e)];
      await apply()();
      // Jurnal belum ter-ack di percobaan pertama: entri yang sama datang lagi.
      gateway.journalRecords = [record(e)];

      final again = await apply()();

      expect(await ledgerNow(), hasLength(1));
      expect(again.recorded, 1);
      expect(gateway.ackedJournal, ['n1', 'n1']);
    });

    test(
      'transaksi dengan id itu sudah ada (mati tepat sesudah mencatat): tidak ditulis ulang, sisanya dibereskan',
      () async {
        final e = entry('n1');
        await ledger.saveTransaction(
          ExpenseTransaction(
            id: captureTransactionId('n1'),
            date: capturedAt,
            amount: 2500000,
            note: 'KOPI',
            walletId: 'bri',
          ),
        );
        await store.saveInbox([e]);
        gateway.journalRecords = [record(e)];

        await apply()();

        expect(await ledgerNow(), hasLength(1));
        expect((await store.loadInbox()).getOrElse((_) => []), isEmpty);
        expect(gateway.acked, contains('n1'));
      },
    );

    test('cocok rutin dengan pos: transaksi tertaut ke kemunculan dan terbebankan ke pos periodenya', () async {
      final rule = RecurringRule(
        id: 'kopi',
        kind: RecurringKind.expense,
        amount: 2500000,
        walletId: 'bri',
        note: 'Kopi',
        budgetItemKey: 'tpl-kopi',
        schedule: RecurringSchedule(frequency: RecurringFrequency.monthly, anchorDate: DateTime(2026, 10, 4)),
      );
      await rules.saveRule(rule);
      final pos = BudgetItemOption(
        budgetId: 'b1',
        budgetName: 'Nov',
        itemId: 'pos-kopi',
        itemName: 'Kopi',
        walletId: 'bri',
        templateItemId: 'tpl-kopi',
        startDate: DateTime(2026, 10, 25),
        endDate: DateTime(2026, 11, 25),
      );
      final e = entry('n1');
      gateway.journalRecords = [
        record(
          e,
          match: OccurrenceMatch(rule: rule, date: DateTime(2026, 11, 4), exact: true),
        ),
      ];

      await apply(catalog: _Catalog([pos]))();

      final tx = (await ledgerNow()).single as ExpenseTransaction;
      expect(tx.recurrence?.ruleId, 'kopi');
      expect(tx.recurrence?.occurrenceDate, DateTime(2026, 11, 4));
      expect(tx.budgetItemId, 'pos-kopi');
    });

    test('rutinnya sudah dihapus sejak notifikasi: tetap tercatat, tanpa tautan', () async {
      final ghost = RecurringRule(
        id: 'hilang',
        kind: RecurringKind.expense,
        amount: 2500000,
        walletId: 'bri',
        note: 'Hilang',
        schedule: RecurringSchedule(frequency: RecurringFrequency.monthly, anchorDate: DateTime(2026, 10, 4)),
      );
      final e = entry('n1');
      gateway.journalRecords = [
        record(
          e,
          match: OccurrenceMatch(rule: ghost, date: DateTime(2026, 11, 4), exact: true),
        ),
      ];

      await apply()();

      expect((await ledgerNow()).single.recurrence, isNull);
    });

    test('dompetnya sudah tidak ada: kartu di kotak masuk dengan alasan, bukan hilang', () async {
      final e = entry('n1', walletId: 'dihapus');
      gateway.journalRecords = [record(e)];

      final result = await apply()();

      expect(result.movedToInbox, 1);
      expect(await ledgerNow(), isEmpty);
      final inbox = (await store.loadInbox()).getOrElse((_) => []);
      expect(inbox.single.id, 'n1');
      expect(inbox.single.reviewReason, CaptureReviewReason.walletUnknown);
      expect(gateway.acked, contains('n1'));
    });

    test('beberapa entri diterapkan urut waktu', () async {
      final a = entry('a', amount: 1000000);
      final b = entry('b', amount: 2000000);
      gateway.journalRecords = [
        record(b, resolvedAt: capturedAt.add(const Duration(minutes: 5))),
        record(a),
      ];

      final result = await apply()();

      expect(result.recorded, 2);
      expect((await ledgerNow()).map((t) => t.amount).toSet(), {1000000, 2000000});
    });
  });

  group('Abaikan dan tanpa keputusan', () {
    test('Abaikan: tidak ada transaksi, kartu dibuang, tangkapan ditandai terproses dan di-ack', () async {
      final e = entry('n1');
      await store.saveInbox([e]);
      gateway.journalRecords = [record(e, decision: 'dismiss')];

      final result = await apply()();

      expect(result.dismissed, 1);
      expect(await ledgerNow(), isEmpty);
      expect((await store.loadInbox()).getOrElse((_) => []), isEmpty);
      expect((await store.loadProcessedIds()).getOrElse((_) => {}).keys, contains('n1'));
      expect(gateway.acked, contains('n1'));
    });

    test('tanpa keputusan: entri jurnal dibuang tetapi tangkapan tetap di antrean untuk diproses biasa', () async {
      final e = entry('n1');
      gateway.journalRecords = [record(e, decision: null)];

      final result = await apply()();

      expect(result.dropped, 1);
      expect(await ledgerNow(), isEmpty);
      expect(gateway.acked, isEmpty);
      expect(gateway.ackedJournal, ['n1']);
      expect((await store.loadProcessedIds()).getOrElse((_) => {}), isEmpty);
    });
  });

  group('ketahanan', () {
    test('muatan rusak: tidak melempar dan entri tetap di jurnal untuk dicoba lagi', () async {
      gateway.journalRecords = [
        CaptureJournalRecord(id: 'x', decision: 'record', resolvedAt: capturedAt, payload: '{bukan json'),
      ];

      final result = await apply()();

      expect(result.isEmpty, isTrue);
      expect(gateway.ackedJournal, isEmpty);
      expect(gateway.journalRecords, hasLength(1));
    });

    test('satu entri rusak tidak menghalangi yang lain', () async {
      final good = entry('ok');
      gateway.journalRecords = [
        CaptureJournalRecord(id: 'x', decision: 'record', resolvedAt: capturedAt, payload: '{bukan json'),
        record(good, resolvedAt: capturedAt.add(const Duration(minutes: 1))),
      ];

      await apply()();

      expect(await ledgerNow(), hasLength(1));
      expect(gateway.ackedJournal, ['ok']);
    });

    test('platform tanpa dukungan atau jurnal kosong: tidak melakukan apa pun', () async {
      final unsupported = ApplyCaptureJournal(
        gateway: const UnsupportedNotificationCaptureGateway(),
        store: store,
        recordTransaction: recordTransaction,
        transactionRepository: ledger,
        walletRepository: wallets,
      );
      expect((await unsupported()).isEmpty, isTrue);
      expect((await apply()()).isEmpty, isTrue);
      expect(gateway.cancelledActionable, 0);
    });
  });
}
