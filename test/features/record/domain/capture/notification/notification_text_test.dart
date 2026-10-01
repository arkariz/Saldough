import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/record/domain/capture/language/indonesian.dart';
import 'package:saldough/features/record/domain/capture/notification/notification_text.dart';

void main() {
  final lexicon = indonesian.notification;

  test('saldo, rekening tersamar, referensi, dan jam disamarkan; nominal transaksi tetap', () {
    const text = 'Pembayaran Rp25.000 dari rek ****1234 pukul 14.32 berhasil. Saldo Rp1.234.567. Ref 202610011432';
    final masked = NotificationText.maskNonTransactionNumbers(text, lexicon);
    expect(masked.length, text.length);
    expect(masked, contains('Rp25.000'));
    expect(masked, isNot(contains('1.234.567')));
    expect(masked, isNot(contains('1234')));
    expect(masked, isNot(contains('14.32')));
    expect(masked, isNot(contains('202610011432')));
  });

  test('"top up saldo Rp50.000" adalah nominal transaksi', () {
    final masked = NotificationText.maskNonTransactionNumbers('Top up saldo Rp50.000 berhasil', lexicon);
    expect(masked, contains('Rp50.000'));
  });

  test('saldo dengan titik dua dan "anda"', () {
    final masked = NotificationText.maskNonTransactionNumbers('Dana masuk Rp100.000. Saldo anda: Rp900.000', lexicon);
    expect(masked, contains('Rp100.000'));
    expect(masked, isNot(contains('900.000')));
  });

  test('OTP dikenali', () {
    expect(NotificationText.looksLikeOtp('Kode OTP kamu 123456. Jangan berikan ke siapa pun'), isTrue);
    expect(NotificationText.looksLikeOtp('Pembayaran Rp25.000 berhasil'), isFalse);
  });

  test('judul digabung dengan isi tanpa mengulang', () {
    expect(NotificationText.combine('BRImo', 'Dana masuk Rp5.000'), 'BRImo\nDana masuk Rp5.000');
    expect(NotificationText.combine('Dana masuk', 'Dana masuk Rp5.000'), 'Dana masuk Rp5.000');
    expect(NotificationText.combine('', 'X'), 'X');
  });
}
