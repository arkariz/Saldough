import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/record/domain/capture/capture_draft_resolver.dart';
import 'package:saldough/features/record/domain/capture/capture_evidence.dart';
import 'package:saldough/features/record/domain/capture/interpreted_transaction.dart';
import 'package:saldough/features/record/domain/capture/language/capture_language.dart';
import 'package:saldough/features/record/domain/capture/record_draft.dart';

/// Pagar resolver terhadap kutipan model yang kebetulan substring
/// (verifikasi M3, H1 dan H2).
void main() {
  final now = DateTime(2026, 9, 30, 12);

  RecordDraft resolve(String text, InterpretedTransaction interpreted, {String languageCode = 'id'}) =>
      CaptureDraftResolver(wallets: const [], categories: const [], language: CaptureLanguages.of(languageCode))
          .resolve(
            CaptureEvidence(source: CaptureSource.voice, text: text, capturedAt: now, languageCode: languageCode),
            interpreted,
          );

  group('nominal: kutipan yang memotong angka ditolak', () {
    for (final (text, quote) in [
      ('makan 350 ribu', '350'),
      ('kopi 25 ribu', '5 ribu'),
      ('gaji 1,5 juta', '5 juta'),
      ('parkir 20000', '2000'),
      ('makan 135 ribu', '35 ribu'),
    ]) {
      test('"$text" + "$quote"', () {
        final draft = resolve(text, InterpretedTransaction(amountText: quote));
        expect(draft.amountSen, isNull);
        expect(draft.issues, {DraftIssue.amountMissing});
      });
    }
  });

  test('nominal: kutipan utuh tetap diterima, termasuk beda huruf/spasi dan simbol', () {
    expect(resolve('makan 350 ribu', const InterpretedTransaction(amountText: '350 ribu')).amountSen, 35000000);
    expect(resolve('Makan  35 RIBU pakai BCA', const InterpretedTransaction(amountText: '35 ribu')).amountSen, 3500000);
    expect(resolve('bayar Rp35.000 tadi', const InterpretedTransaction(amountText: 'Rp35.000')).amountSen, 3500000);
    expect(resolve('parkir 2000', const InterpretedTransaction(amountText: '2000')).amountSen, 200000);
    expect(resolve('kopi 5 ribu dan roti 25 ribu', const InterpretedTransaction(amountText: '5 ribu')).amountSen, 500000);
  });

  test('tanggal: kutipan dikenali paket tetapi tanggal model berbeda → dateUnclear', () {
    final draft = resolve(
      'kopi 5000 kemarin',
      InterpretedTransaction(amountText: '5000', dateText: 'kemarin', date: DateTime(2026, 9, 1, 12)),
    );
    expect(draft.date, isNull);
    expect(draft.issues, {DraftIssue.dateUnclear});
  });

  test('tanggal: tafsiran model sama dengan paket → dipakai', () {
    final draft = resolve(
      'beli kopi 5000 tanggal 27 september',
      InterpretedTransaction(amountText: '5000', dateText: '27 september', date: DateTime(2026, 9, 27, 12)),
    );
    expect(draft.date, DateTime(2026, 9, 27, 12));
    expect(draft.issues, isEmpty);
  });

  test('tanggal: kutipan yang tidak dikenali paket dipercaya ke model', () {
    final draft = resolve(
      'kopi 5000 jumat lalu',
      InterpretedTransaction(amountText: '5000', dateText: 'jumat lalu', date: DateTime(2026, 9, 25, 12)),
    );
    expect(draft.date, DateTime(2026, 9, 25, 12));
    expect(draft.issues, isEmpty);
  });
}
