import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/utils/formatters/money_input.dart';
import 'package:saldough/features/record/presentation/widgets/investment_form_sheet.dart';
import 'package:saldough/features/record/presentation/widgets/record_form_frame.dart';
import 'package:saldough/shared/investment/investment.dart';
import 'package:saldough/shared/investment/investment_presentation.dart';

/// Rupa B-97 §0, §4.4: format jumlah berskala, pengurai isian, dan papan
/// angka yang mengisi jumlah.
void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.id));

  test('formatScaled tanpa nol buntut, pemisah locale', () {
    expect(formatScaled(123456), '12,3456');
    expect(formatScaled(50000), '5');
    expect(formatScaled(15234567), '1.523,4567');
    expect(formatQuantity(InstrumentType.stock, 12 * quantityScale), '12 lot');
  });

  test('parseScaled dan scaledInputText bolak-balik', () {
    expect(parseScaled('12,5'), 125000);
    expect(parseScaled('0,0001'), 1);
    expect(parseScaled('0'), isNull);
    expect(parseScaled('abc'), isNull);
    expect(scaledInputText(125000), '12,5');
    expect(parseUnitPriceInput(InstrumentType.bond, '100,5'), 1005000);
    expect(formatUnitPrice(InstrumentType.bond, 1005000), '100,5% dari nominal');
  });

  test('formatSignedPercent satu desimal, bertanda', () {
    expect(formatSignedPercent(750000, 11100000), '+6,8%');
    expect(formatSignedPercent(-120000, 5714286), '−2,1%');
    expect(formatSignedPercent(1, 0), isNull);
  });

  test('quantityAfterKey: angka, desimal sekali, batas desimal, hapus', () {
    var text = '';
    for (final key in ['1', '2', moneyKeyDecimal, '5', moneyKeyDecimal, '0', '7']) {
      text = quantityAfterKey(text, key, decimals: 2);
    }
    expect(text, '12,50');
    expect(quantityAfterKey(text, moneyKeyBackspace, decimals: 2), '12,5');
    expect(quantityAfterKey(text, RecordFormFrame.frameClearKey, decimals: 2), '');
    expect(quantityAfterKey('', moneyKeyDecimal, decimals: 4), '0,');
    expect(quantityAfterKey('5', '000', decimals: 4), '500');
    expect(quantityAfterKey('5', '000', decimals: 0), '5000');
    expect(quantityAfterKey('5', moneyKeyDecimal, decimals: 0), '5');
    expect(quantityAfterKey('5', '+', decimals: 2), '5');
  });
}
