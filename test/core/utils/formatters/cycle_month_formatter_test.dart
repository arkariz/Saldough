import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';

void main() {
  group('CycleMonthFormatter', () {
    test('memformat dalam bahasa Indonesia (bawaan)', () {
      expect(CycleMonthFormatter.format('2026-08'), 'Agustus 2026');
      expect(CycleMonthFormatter.format('2026-01'), 'Januari 2026');
      expect(CycleMonthFormatter.format('2026-12'), 'Desember 2026');
    });

    test('memformat dalam bahasa Inggris kalau locale aktif en', () async {
      await LocaleSettings.setLocale(AppLocale.en);
      addTearDown(() => LocaleSettings.setLocale(AppLocale.id));

      expect(CycleMonthFormatter.format('2026-08'), 'August 2026');
    });

    test('mengembalikan id apa adanya kalau formatnya tidak valid', () {
      expect(CycleMonthFormatter.format('bukan-id'), 'bukan-id');
      expect(CycleMonthFormatter.format('2026-13'), '2026-13');
      expect(CycleMonthFormatter.format('2026'), '2026');
    });

    // UX-21: dasar Text catat jam kerja -- sebelumnya disusun tangan jadi
    // "2026-09-11", melanggar aturan slang.
    test('formatDate memformat tanggal lengkap dalam bahasa Indonesia (bawaan)', () {
      expect(CycleMonthFormatter.formatDate(DateTime(2026, 9, 11)), '11 September 2026');
      expect(CycleMonthFormatter.formatDate(DateTime(2026, 1, 5)), '5 Januari 2026');
    });

    test('formatDate memformat dalam bahasa Inggris kalau locale aktif en', () async {
      await LocaleSettings.setLocale(AppLocale.en);
      addTearDown(() => LocaleSettings.setLocale(AppLocale.id));

      expect(CycleMonthFormatter.formatDate(DateTime(2026, 1, 5)), '5 January 2026');
    });
  });
}
