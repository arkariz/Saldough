import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/notification_capture/domain/entities/captured_notification.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_pattern.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_source.dart';
import 'package:saldough/features/notification_capture/domain/services/built_in_notification_patterns.dart';
import 'package:saldough/features/notification_capture/domain/services/notification_draft_composer.dart';
import 'package:saldough/shared/capture/capture.dart';

import 'notification_fixtures.dart';

/// Contoh teks umum notifikasi bank/e-wallet Indonesia. **Bukan sampel asli**
/// -- ganti/tambah dengan sampel dari layar debug (ADR-032 §3.6) sebelum
/// T-11.17 dicentang.
void main() {
  final postedAt = DateTime(2026, 10, 1, 14, 32);

  Future<NotificationDraft> compose(
    String body, {
    String title = '',
    NotificationSource source = brimoSource,
    List<NotificationPattern> patterns = const [],
    TransactionInterpreter? cloud,
  }) => notificationComposer(cloud: cloud).compose(
    CapturedNotification(id: '1', packageName: source.packageName, title: title, body: body, postedAt: postedAt),
    source: source,
    patterns: patterns,
    wallets: notificationWallets,
    categories: notificationCategories,
    currencyCode: 'IDR',
    languageCode: 'id',
  );

  group('aturan notifikasi', () {
    test('pembayaran: nominal transaksi, bukan saldo; dompet sumber; kategori dari alias', () async {
      final result = await compose('Pembayaran Rp25.000 ke KOPI KENANGAN berhasil. Saldo Rp1.234.567');
      final draft = result.draft;
      expect(draft.kind, DraftKind.expense);
      expect(draft.amountSen, 2500000);
      expect(draft.walletId, 'bri');
      expect(draft.categoryId, isNotNull);
      expect(draft.note, 'KOPI KENANGAN');
      expect(draft.date, postedAt);
      expect(draft.isConfident, isTrue);
      expect(result.autoEligible, isTrue);
    });

    test('judul notifikasi tidak ikut ke catatan', () async {
      final draft = (await compose('Pembayaran Rp25.000 ke KOPI KENANGAN berhasil', title: 'BRImo')).draft;
      expect(draft.note, 'KOPI KENANGAN');
    });

    test('dana masuk = pemasukan, walau ada kata transfer tanpa dompet lawan', () async {
      final draft = (await compose('Transfer masuk Rp1.500.000 dari BUDI SANTOSO ke rek ****1234')).draft;
      expect(draft.kind, DraftKind.income);
      expect(draft.amountSen, 150000000);
      expect(draft.walletId, 'bri');
    });

    test('tanpa kata arah → kindUnclear, tidak yakin', () async {
      final draft = (await compose('Transaksi Rp50.000 berhasil')).draft;
      expect(draft.issues, contains(DraftIssue.kindUnclear));
      expect(draft.isConfident, isFalse);
    });

    test('top up ke dompet sendiri = transfer keluar dari dompet sumber', () async {
      final draft = (await compose('Top up ke GoPay Rp100.000 berhasil')).draft;
      expect(draft.kind, DraftKind.transfer);
      expect(draft.walletId, 'bri');
      expect(draft.toWalletId, 'gopay');
      expect(draft.isConfident, isTrue);
    });

    test('top up dari dompet lain di aplikasi e-wallet = transfer masuk ke dompet sumber', () async {
      const gopay = NotificationSource(packageName: 'com.gojek.app', appLabel: 'Gojek', walletId: 'gopay');
      final draft = (await compose('Isi saldo dari BRI Rp100.000 berhasil', source: gopay)).draft;
      expect(draft.kind, DraftKind.transfer);
      expect(draft.walletId, 'bri');
      expect(draft.toWalletId, 'gopay');
    });

    test('nama bank pengirim (= dompet sumber) bukan lawan transfer', () async {
      final draft = (await compose('Transfer ke BRI Rp20.000 berhasil')).draft;
      expect(draft.kind, DraftKind.expense);
      expect(draft.walletId, 'bri');
      expect(draft.toWalletId, isNull);
    });

    test('sumber tanpa dompet → dompet kosong', () async {
      const noWallet = NotificationSource(packageName: 'x', appLabel: 'X');
      final draft = (await compose('Pembayaran Rp25.000 berhasil', source: noWallet)).draft;
      expect(draft.walletId, isNull);
    });
  });

  group('pola', () {
    const userPattern = NotificationPattern(
      id: 'u1',
      packageName: 'id.co.bri.brimo',
      label: 'QRIS',
      template: 'QRIS {amount} di {note} sukses',
      kind: NotificationPatternKind.expense,
    );

    test('pola pengguna menentukan jenis, nominal, catatan', () async {
      final result = await compose('QRIS Rp18.500 di WARUNG BU TINI sukses', patterns: [userPattern]);
      expect(result.pattern, userPattern);
      expect(result.draft.kind, DraftKind.expense);
      expect(result.draft.amountSen, 1850000);
      expect(result.draft.note, 'WARUNG BU TINI');
      expect(result.draft.walletId, 'bri');
      expect(result.autoEligible, isTrue);
    });

    test('pola paket lain diabaikan', () async {
      const other = NotificationPattern(
        id: 'u2',
        packageName: 'ovo.id',
        label: 'x',
        template: 'QRIS {amount} di {note} sukses',
        kind: NotificationPatternKind.income,
      );
      final result = await compose('QRIS Rp18.500 di WARUNG sukses', patterns: [other]);
      expect(result.pattern, isNull);
    });

    test('aturan yang yakin mendahului pola bawaan belum terverifikasi', () async {
      final result = await compose('Dana masuk Rp75.000 dari ANI', patterns: builtInNotificationPatterns);
      expect(result.pattern, isNull);
      expect(result.autoEligible, isTrue);
    });

    test('pola bawaan belum terverifikasi dipakai bila aturan ragu, tidak layak otomatis', () async {
      final result = await compose(
        'Dana masuk Rp75.000 dari ANI, pembayaran tagihan',
        patterns: builtInNotificationPatterns,
      );
      expect(result.pattern?.builtIn, isTrue);
      expect(result.draft.kind, DraftKind.income);
      expect(result.draft.amountSen, 7500000);
      expect(result.autoEligible, isFalse);
    });

    test('pola bawaan tidak menangkap saldo bila nominal transaksi tidak tertulis', () async {
      final result = await compose(
        'Pembayaran QRIS berhasil. Saldo Rp1.000.000',
        patterns: builtInNotificationPatterns,
      );
      expect(result.draft.amountSen, isNull);
    });

    test('pola transfer keluar dengan dompet lawan tetap', () async {
      const topUp = NotificationPattern(
        id: 'u3',
        packageName: 'id.co.bri.brimo',
        label: 'Top up',
        template: 'Top up {*} {amount} berhasil',
        kind: NotificationPatternKind.transferOut,
        transferWalletId: 'gopay',
      );
      final draft = (await compose('Top up GOPAY Rp100.000 berhasil', patterns: [topUp])).draft;
      expect(draft.kind, DraftKind.transfer);
      expect(draft.walletId, 'bri');
      expect(draft.toWalletId, 'gopay');
      expect(draft.isConfident, isTrue);
    });
  });

  group('bahasa', () {
    test('notifikasi Indonesia ditafsirkan paket id walau aplikasi berbahasa Inggris', () async {
      final draft = (await notificationComposer().compose(
        CapturedNotification(
          id: '1',
          packageName: brimoSource.packageName,
          title: '',
          body: 'Pembayaran Rp25.000 ke KOPI KENANGAN berhasil. Saldo Rp1.234.567',
          postedAt: postedAt,
        ),
        source: brimoSource,
        patterns: const [],
        wallets: notificationWallets,
        categories: notificationCategories,
        currencyCode: 'IDR',
        languageCode: 'en',
      )).draft;
      expect(draft.kind, DraftKind.expense);
      expect(draft.amountSen, 2500000);
      expect(draft.isConfident, isTrue);
    });

    test('notifikasi Inggris ditafsirkan paket en', () {
      expect(detectNotificationLanguage('Payment of IDR 25,000 successful', fallback: 'id')?.code, 'en');
      expect(detectNotificationLanguage('Rp25.000', fallback: 'en')?.code, 'id');
      expect(detectNotificationLanguage('25.000', fallback: 'en')?.code, 'en');
    });
  });

  group('cloud', () {
    test('aturan ragu → cloud; sebutan dompet cloud diganti dompet sumber', () async {
      final cloud = _FakeCloud(
        const InterpretedTransaction(kind: DraftKind.expense, amountText: 'Rp50.000', walletText: 'QRIS'),
      );
      final draft = (await compose('Transaksi Rp50.000 berhasil', cloud: cloud)).draft;
      expect(cloud.calls, 1);
      expect(cloud.lastEvidence?.source, CaptureSource.notification);
      expect(draft.kind, DraftKind.expense);
      expect(draft.walletId, 'bri');
      expect(draft.issues, isNot(contains(DraftIssue.walletUnknown)));
    });

    test('cloud menerima teks tersamar (tanpa saldo/rekening); kutipan divalidasi ke teks asli', () async {
      final cloud = _FakeCloud(
        const InterpretedTransaction(kind: DraftKind.expense, amountText: 'Rp50.000'),
      );
      final draft = (await compose('Transaksi Rp50.000 dari rek ****1234 berhasil. Saldo Rp1.234.567', cloud: cloud))
          .draft;
      final sent = cloud.lastEvidence!.text;
      expect(sent, contains('Rp50.000'));
      expect(sent, isNot(contains('1.234.567')));
      expect(sent, isNot(contains('1234')));
      expect(draft.amountSen, 5000000);
      expect(draft.sourceText, contains('Saldo Rp1.234.567'));
    });
  });
}

final class _FakeCloud implements TransactionInterpreter {
  _FakeCloud(this.result);

  final InterpretedTransaction result;
  int calls = 0;
  CaptureEvidence? lastEvidence;

  @override
  Future<Either<Failure, InterpretedTransaction>> interpret(
    CaptureEvidence evidence,
    InterpretationContext context,
  ) async {
    calls++;
    lastEvidence = evidence;
    return right(result);
  }
}
