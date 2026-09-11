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
  });
}
