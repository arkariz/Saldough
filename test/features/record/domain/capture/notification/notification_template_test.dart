import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/record/domain/capture/notification/notification_template.dart';

void main() {
  group('NotificationTemplate.match', () {
    const template = 'Pembayaran {amount} ke {note} berhasil. Ref {*}';

    test('mengutip nominal dan catatan', () {
      final m = NotificationTemplate.match(template, 'Pembayaran Rp25.000 ke KOPI KENANGAN berhasil. Ref 99812');
      expect(m?.amountText, 'Rp25.000');
      expect(m?.note, 'KOPI KENANGAN');
    });

    test('tanpa beda huruf besar-kecil, spasi apa pun, titik akhir opsional', () {
      final m = NotificationTemplate.match(template, '  pembayaran  Rp 25.000\nke Toko A berhasil.   ref 1!  ');
      expect(m?.amountText, 'Rp 25.000');
      expect(m?.note, 'Toko A');
    });

    test('teks tetap yang berbeda tidak cocok', () {
      expect(NotificationTemplate.match(template, 'Pembelian Rp25.000 ke X berhasil. Ref 1'), isNull);
    });

    test('nominal harus ber-Rp atau berpemisah ribuan', () {
      expect(NotificationTemplate.match('{*}dana masuk{*}{amount}{*}', 'Dana masuk ke rek 1234 dari BUDI'), isNull);
      expect(
        NotificationTemplate.match('{*}dana masuk{*}{amount}{*}', 'Dana masuk ke rek 1234 Rp50.000')?.amountText,
        'Rp50.000',
      );
    });

    test('templat tanpa nominal tidak sah', () {
      expect(NotificationTemplate.isValid('Pembayaran {note} berhasil'), isFalse);
      expect(NotificationTemplate.isValid('{amount}'), isFalse);
      expect(NotificationTemplate.match('Pembayaran {note}', 'Pembayaran X'), isNull);
    });
  });

  group('NotificationTemplate.fromSample', () {
    const sample = 'Pembayaran Rp25.000, ke KOPI KENANGAN berhasil pada 01/10 14:32. Ref 99812';

    test('nominal + catatan → templat yang cocok dengan contohnya dan variannya', () {
      final words = NotificationTemplate.words(sample);
      final roles = {1: TemplateWordRole.amount, 3: TemplateWordRole.note, 4: TemplateWordRole.note};
      final template = NotificationTemplate.fromSample(sample, roles);
      expect(template, 'Pembayaran {amount}, ke {note} berhasil pada {*} Ref {*}');
      expect(words[1].text, 'Rp25.000,');
      expect(NotificationTemplate.match(template!, sample)?.amountText, 'Rp25.000');
      final variant = NotificationTemplate.match(
        template,
        'Pembayaran Rp1.250.000, ke Toko Baju Ceria berhasil pada 02/10 09:01. Ref 1',
      );
      expect(variant?.amountText, 'Rp1.250.000');
      expect(variant?.note, 'Toko Baju Ceria');
    });

    test('tanpa nominal, dua nominal, atau catatan terputus → null', () {
      expect(NotificationTemplate.fromSample(sample, {3: TemplateWordRole.note}), isNull);
      expect(
        NotificationTemplate.fromSample(sample, {1: TemplateWordRole.amount, 0: TemplateWordRole.amount}),
        isNull,
      );
      expect(
        NotificationTemplate.fromSample(sample, {
          1: TemplateWordRole.amount,
          3: TemplateWordRole.note,
          5: TemplateWordRole.note,
        }),
        isNull,
      );
    });

    test('kata bukan nominal tidak bisa ditandai nominal', () {
      expect(NotificationTemplate.isAmountWord('Rp25.000,'), isTrue);
      expect(NotificationTemplate.isAmountWord('99812'), isFalse);
      expect(NotificationTemplate.fromSample(sample, {0: TemplateWordRole.amount}), isNull);
    });
  });
}
