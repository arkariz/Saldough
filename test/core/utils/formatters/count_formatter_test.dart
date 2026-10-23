import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/utils/formatters/count_formatter.dart';

/// Jumlah benda memakai pemisah ribuan menurut bahasa (QA Fase 22, Q5).
void main() {
  tearDown(() => LocaleSettings.setLocale(AppLocale.id));

  test('id: titik; en: koma; di bawah seribu tanpa pemisah', () async {
    await LocaleSettings.setLocale(AppLocale.id);
    expect([0, 999, 1000, 5008, 1234567].map(CountFormatter.format), ['0', '999', '1.000', '5.008', '1.234.567']);
    await LocaleSettings.setLocale(AppLocale.en);
    expect([0, 999, 1000, 5008, 1234567].map(CountFormatter.format), ['0', '999', '1,000', '5,008', '1,234,567']);
  });
}
