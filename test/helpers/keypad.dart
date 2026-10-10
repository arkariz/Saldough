import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/utils/formatters/money_expression.dart';

const Map<String, String> _operatorKeys = {
  '+': moneyKeyAdd,
  '-': moneyKeySubtract,
  '*': moneyKeyMultiply,
  '/': moneyKeyDivide,
};

/// Mengetik [digits] (mis. `'75000'`) lewat papan angka CATAT (T-14.5).
/// `+ - * /` mengetuk tombol operator kalkulator (T-8.18), mis. `'10+5'`.
/// Mengosongkan nominal dulu lewat tekan lama tombol hapus kalau [clear].
Future<void> enterAmount(
  WidgetTester tester,
  String digits, {
  bool clear = true,
}) async {
  if (clear) {
    final backspace = find.byKey(const ValueKey('keypad-backspace'));
    await tester.ensureVisible(backspace);
    await tester.longPress(backspace);
    await tester.pump();
  }
  for (final char in digits.split('')) {
    final key = find.byKey(ValueKey('keypad-${_operatorKeys[char] ?? char}'));
    await tester.ensureVisible(key);
    await tester.tap(key);
    await tester.pump();
  }
}
