import 'package:flutter/widgets.dart';
import 'package:saldough/core/utils/formatters/money_expression.dart';
import 'package:saldough/core/utils/formatters/money_input.dart';

/// Pengendali nominal Catat yang bisa menghitung (T-8.18).
///
/// [text] selalu berisi **nominal hasil** berformat kolom nominal, jadi
/// formulir tetap membacanya lewat `parseMoneyInput`. Selama ungkapan
/// memuat operator, ungkapannya ada di [expression] dan [text] berisi
/// hasilnya (kosong bila hasilnya tidak sah, lihat [error]). Menulis [text]
/// atau `clear()` dari luar (pra-isi draf, tagihan freelance) membuang
/// ungkapan.
class RecordAmountController extends TextEditingController {
  /// Membuat [RecordAmountController].
  RecordAmountController({super.text});

  String _expression = '';
  bool _applying = false;

  /// Ungkapan yang sedang dihitung, mis. `10.000 + 5.000`; kosong bila
  /// nominal diketik tanpa operator.
  String get expression => _expression;

  /// Alasan hasil [expression] tidak sah, atau `null`.
  MoneyExpressionError? get error => _expression.isEmpty ? null : evaluateMoneyExpression(_expression).error;

  @override
  set value(TextEditingValue newValue) {
    final dropped = !_applying && _expression.isNotEmpty;
    if (dropped) _expression = '';
    final unchanged = newValue == value;
    super.value = newValue;
    if (dropped && unchanged) notifyListeners();
  }

  /// Menerapkan tombol papan angka [key]; `false` bila tidak ada yang
  /// berubah (mis. digit melewati batas).
  bool applyKey(String key) {
    final base = _expression.isEmpty ? text : _expression;
    final next = applyMoneyExpressionKey(base, key);
    if (next == base) return false;
    final calculating = hasMoneyOperator(next);
    final String nextText;
    if (calculating) {
      final sen = evaluateMoneyExpression(next).sen;
      nextText = sen == null ? '' : formatMoneyInput(sen);
    } else {
      nextText = next;
    }
    _expression = calculating ? next : '';
    _applying = true;
    try {
      if (nextText == text) {
        notifyListeners();
      } else {
        text = nextText;
      }
    } finally {
      _applying = false;
    }
    return true;
  }
}
