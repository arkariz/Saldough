import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/notification_capture/domain/entities/captured_notification.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_pattern.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_source.dart';
import 'package:saldough/features/notification_capture/domain/services/notification_draft_composer.dart';
import 'package:saldough/features/notification_capture/domain/services/notification_template.dart';
import 'package:saldough/shared/capture/capture.dart';
import 'package:saldough/shared/wallet/wallet.dart';

import 'notification_fixtures.dart';

/// ADR-042 §3.1: banyak dompet per aplikasi (kasus Bank Jago dengan Kantong).
void main() {
  const wallets = [
    Wallet(id: 'main', name: 'Jago Utama', iconKey: 'walletBank', initialBalance: 0, currentBalance: 0),
    Wallet(id: 'trip', name: 'Liburan', iconKey: 'walletBank', initialBalance: 0, currentBalance: 0),
    Wallet(id: 'save', name: 'Tabungan', iconKey: 'walletBank', initialBalance: 0, currentBalance: 0),
  ];
  const jago = NotificationSource(
    packageName: 'com.jago.digitalBanking',
    appLabel: 'Jago',
    walletId: 'main',
    walletRules: [
      WalletRule(walletId: 'trip', keywords: ['Kantong Liburan']),
      WalletRule(walletId: 'save', keywords: ['Kantong Tabungan']),
    ],
  );

  Future<NotificationDraft> compose(String body, {List<NotificationPattern> patterns = const []}) =>
      notificationComposer().compose(
        CapturedNotification(
          id: '1',
          packageName: jago.packageName,
          title: '',
          body: body,
          postedAt: DateTime(2026, 10, 23, 10),
        ),
        source: jago,
        patterns: patterns,
        wallets: wallets,
        categories: notificationCategories,
        currencyCode: 'IDR',
        languageCode: 'id',
      );

  group('resolveWallet', () {
    test('tepat satu aturan cocok → dompet aturan itu', () {
      final r = jago.resolveWallet('Pembayaran Rp25.000 dari Kantong Liburan berhasil');
      expect(r.walletId, 'trip');
      expect(r.ambiguous, isFalse);
    });

    test('tanpa aturan cocok → dompet bawaan', () {
      final r = jago.resolveWallet('Pembayaran Rp25.000 berhasil');
      expect(r.walletId, 'main');
      expect(r.ambiguous, isFalse);
    });

    test('dua dompet berbeda cocok → ambigu, tidak menebak', () {
      final r = jago.resolveWallet('Kantong Liburan dan Kantong Tabungan');
      expect(r.walletId, isNull);
      expect(r.ambiguous, isTrue);
    });
  });

  group('penyusun draf', () {
    test('pengeluaran dari Kantong memakai dompet Kantong', () async {
      final draft = (await compose('Pembayaran Rp25.000 ke KOPI dari Kantong Liburan berhasil')).draft;
      expect(draft.walletId, 'trip');
    });

    test('tanpa pengenal memakai dompet bawaan', () async {
      final draft = (await compose('Pembayaran Rp25.000 ke KOPI berhasil')).draft;
      expect(draft.walletId, 'main');
    });

    test('ambigu → dompet kosong dan walletUnknown', () async {
      final draft = (await compose('Pembayaran Rp25.000 dari Kantong Liburan dan Kantong Tabungan berhasil')).draft;
      expect(draft.walletId, isNull);
      expect(draft.issues, contains(DraftIssue.walletUnknown));
      expect(draft.isConfident, isFalse);
    });

    test('pola transfer {from}/{to} memetakan kedua Kantong', () async {
      const pattern = NotificationPattern(
        id: 'u1',
        packageName: 'com.jago.digitalBanking',
        label: 'Antar kantong',
        template: 'Pindah {amount} dari {from} ke {to}',
        kind: NotificationPatternKind.transferBetween,
      );
      final draft = (await compose('Pindah Rp100.000 dari Kantong Liburan ke Kantong Tabungan', patterns: [pattern]))
          .draft;
      expect(draft.kind, DraftKind.transfer);
      expect(draft.amountSen, 10000000);
      expect(draft.walletId, 'trip');
      expect(draft.toWalletId, 'save');
      expect(draft.isConfident, isTrue);
    });

    test('sisi yang tidak terpetakan dibiarkan kosong, bukan ditebak', () async {
      const pattern = NotificationPattern(
        id: 'u1',
        packageName: 'com.jago.digitalBanking',
        label: 'Antar kantong',
        template: 'Pindah {amount} dari {from} ke {to}',
        kind: NotificationPatternKind.transferBetween,
      );
      final draft = (await compose('Pindah Rp100.000 dari Kantong Liburan ke Kantong Misteri', patterns: [pattern]))
          .draft;
      expect(draft.walletId, 'trip');
      expect(draft.toWalletId, isNull);
      expect(draft.issues, contains(DraftIssue.transferTargetMissing));
    });

    test('kedua sisi dompet sama → keduanya kosong', () async {
      const pattern = NotificationPattern(
        id: 'u1',
        packageName: 'com.jago.digitalBanking',
        label: 'Antar kantong',
        template: 'Pindah {amount} dari {from} ke {to}',
        kind: NotificationPatternKind.transferBetween,
      );
      final draft = (await compose('Pindah Rp100.000 dari Kantong Liburan ke Kantong Liburan', patterns: [pattern]))
          .draft;
      expect(draft.walletId, isNull);
      expect(draft.toWalletId, isNull);
    });
  });

  group('templat {from}/{to}', () {
    test('wajib berpasangan', () {
      expect(NotificationTemplate.isValid('Pindah {amount} dari {from} ke {to}'), isTrue);
      expect(NotificationTemplate.isValid('Pindah {amount} dari {from}'), isFalse);
      expect(NotificationTemplate.isValid('Pindah {amount} ke {to}'), isFalse);
    });

    test('dibuat dari contoh dengan peran Dari dan Ke', () {
      const sample = 'Pindah Rp100.000 dari Kantong Liburan ke Kantong Tabungan';
      final template = NotificationTemplate.fromSample(sample, {
        1: TemplateWordRole.amount,
        3: TemplateWordRole.from,
        4: TemplateWordRole.from,
        6: TemplateWordRole.to,
        7: TemplateWordRole.to,
      });
      expect(template, 'Pindah {amount} dari {from} ke {to}');
      final match = NotificationTemplate.match(template!, sample);
      expect(match?.fromText, 'Kantong Liburan');
      expect(match?.toText, 'Kantong Tabungan');
    });

    test('peran Dari tanpa Ke ditolak', () {
      const sample = 'Pindah Rp100.000 dari Kantong Liburan ke Kantong Tabungan';
      expect(
        NotificationTemplate.fromSample(sample, {1: TemplateWordRole.amount, 3: TemplateWordRole.from}),
        isNull,
      );
    });
  });
}
