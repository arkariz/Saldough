import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/features/notification_capture/data/notification_capture_store_impl.dart';
import 'package:saldough/features/notification_capture/domain/entities/capture_inbox_entry.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_capture_settings.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_source.dart';
import 'package:saldough/features/notification_capture/domain/services/account_hint.dart';
import 'package:saldough/features/notification_capture/domain/usecases/capture_inbox_actions.dart';
import 'package:saldough/shared/capture/capture.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

import 'notification_fixtures.dart';

/// Banyak dompet per aplikasi tanpa formulir (ADR-044 §3.7, E1/B-85): dompet
/// dipilih di kartu, pengenal rekening di teks menjadi aturan dompet.
void main() {
  group('accountHintOf', () {
    test('tepat satu pengenal bertopeng', () {
      expect(accountHintOf('Pembayaran Rp25.000 dari rekening ****1234 berhasil'), '****1234');
      expect(accountHintOf('Debit dari XXXX5678'), 'xxxx5678');
      expect(accountHintOf('kartu •••4321 dipakai'), '•••4321');
    });

    test('tidak ada, atau lebih dari satu yang berbeda: tidak ditebak', () {
      expect(accountHintOf('Pembayaran Rp25.000 ke KOPI berhasil. Saldo Rp1.234.567'), isNull);
      expect(accountHintOf('Transfer dari ****1234 ke ****5678'), isNull);
      expect(accountHintOf('Dari ****1234, kartu ****1234'), '****1234', reason: 'pengenal yang sama dua kali');
    });
  });

  group('CaptureInboxActions.rememberWallet', () {
    late InMemoryKeyValueStorage storage;
    late NotificationCaptureStoreImpl store;

    setUp(() async {
      storage = InMemoryKeyValueStorage();
      store = NotificationCaptureStoreImpl(storage: storage);
      await store.saveSettings(
        const NotificationCaptureSettings(
          enabled: true,
          sources: [
            NotificationSource(packageName: 'app.a', appLabel: 'App A', walletId: 'bca', keywords: ['berhasil']),
          ],
        ),
      );
    });

    CaptureInboxEntry entry({
      String text = 'Pembayaran Rp25.000 dari ****5678 berhasil',
      String? wallet = 'bca',
      DraftKind kind = DraftKind.expense,
    }) => CaptureInboxEntry(
      id: 'e1',
      packageName: 'app.a',
      appLabel: 'App A',
      text: text,
      capturedAt: DateTime(2026, 11, 5),
      draft: RecordDraft(kind: kind, amountSen: 2500000, walletId: wallet, note: 'KOPI'),
    );

    CaptureInboxActions actions() {
      final ledger = TransactionRepositoryImpl(storage: storage);
      final wallets = WalletRepositoryImpl(storage: storage);
      return CaptureInboxActions(
        store: store,
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

    Future<NotificationSource> source() async =>
        (await store.loadSettings()).getOrElse((_) => const NotificationCaptureSettings()).sources.single;

    test('dompet diubah di kartu: pengenal rekening jadi aturan; teks sama kini ke dompet itu', () async {
      final learned = await actions().rememberWallet(entry(), walletId: 'tabungan');

      expect(learned?.hint, '****5678');
      final s = await source();
      expect(s.walletId, 'bca', reason: 'dompet bawaan tidak berubah');
      expect(s.walletRules.single.walletId, 'tabungan');
      expect(s.resolveWallet('Debit ****5678 Rp10.000 berhasil').walletId, 'tabungan');
      expect(s.resolveWallet('Debit ****9999 Rp10.000 berhasil').walletId, 'bca');
    });

    test('Batalkan mengembalikan setelan sebelumnya', () async {
      final learned = await actions().rememberWallet(entry(), walletId: 'tabungan');
      await learned!.undo();
      expect((await source()).walletRules, isEmpty);
    });

    test('pengenal yang sama dipindah ke dompet baru, aturan lama yang kosong dibuang', () async {
      final a = actions();
      await a.rememberWallet(entry(), walletId: 'tabungan');
      await a.rememberWallet(entry(), walletId: 'bri');
      final rules = (await source()).walletRules;
      expect(rules, hasLength(1));
      expect(rules.single.walletId, 'bri');
      expect(rules.single.keywords, ['****5678']);
    });

    test('dua pengenal untuk satu dompet digabung dalam satu aturan', () async {
      final a = actions();
      await a.rememberWallet(entry(), walletId: 'tabungan');
      await a.rememberWallet(entry(text: 'Pembayaran Rp1.000 dari ****1111 berhasil'), walletId: 'tabungan');
      expect((await source()).walletRules.single.keywords, ['****5678', '****1111']);
    });

    test('tidak belajar: dompet sama, tanpa pengenal, pengenal ganda, transfer, atau sumber tak dikenal', () async {
      final a = actions();
      expect(await a.rememberWallet(entry(), walletId: 'bca'), isNull);
      expect(await a.rememberWallet(entry(text: 'Pembayaran Rp25.000 berhasil'), walletId: 'tabungan'), isNull);
      expect(await a.rememberWallet(entry(text: 'Dari ****1234 ke ****5678'), walletId: 'tabungan'), isNull);
      expect(await a.rememberWallet(entry(kind: DraftKind.transfer), walletId: 'tabungan'), isNull);
      expect(await a.rememberWallet(entry(), walletId: null), isNull);
      expect((await source()).walletRules, isEmpty);
    });
  });
}
