import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saldough/core/currency/active_currency.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/app_icon.dart';
import 'package:saldough/core/presentation/widgets/pixel_corner_border.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/core/utils/formatters/money_input.dart';

/// Papan angka pengisi nominal di Catat, pengganti keyboard sistem
/// (komponen Keypad, ADR-034).
///
/// Empat baris tiga kolom: 1–9, lalu `000` (mata uang tanpa desimal) atau
/// pemisah desimal, `0`, dan hapus. Tekan lama hapus mengosongkan nominal.
/// Tombol `surface2` bersudut piksel kecil, jarak 8px, angka tabular, getar
/// ringan saat ditekan. [onKey] menerima digit, `000`, [moneyKeyDecimal],
/// atau [moneyKeyBackspace]; teksnya dihitung lewat [applyMoneyKey].
class AppKeypad extends StatelessWidget {
  /// Membuat [AppKeypad].
  const AppKeypad({required this.onKey, required this.onClear, this.keyHeight = 46, super.key});

  /// Dipanggil dengan tombol yang ditekan.
  final ValueChanged<String> onKey;

  /// Tekan lama tombol hapus.
  final VoidCallback onClear;

  /// Tinggi tiap tombol.
  final double keyHeight;

  @override
  Widget build(BuildContext context) {
    final decimalCurrency = ActiveCurrency.value.fractionDigits > 0;
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      [if (decimalCurrency) moneyKeyDecimal else '000', '0', moneyKeyBackspace],
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, row) in rows.indexed) ...[
          if (i > 0) const SizedBox(height: AppSpacing.space2),
          Row(
            children: [
              for (final (j, key) in row.indexed) ...[
                if (j > 0) const SizedBox(width: AppSpacing.space2),
                Expanded(child: _Key(keyValue: key, height: keyHeight, onKey: onKey, onClear: onClear)),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _Key extends StatefulWidget {
  const _Key({required this.keyValue, required this.height, required this.onKey, required this.onClear});

  final String keyValue;
  final double height;
  final ValueChanged<String> onKey;
  final VoidCallback onClear;

  @override
  State<_Key> createState() => _KeyState();
}

class _KeyState extends State<_Key> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final key = widget.keyValue;
    final backspace = key == moneyKeyBackspace;
    final label = key == moneyKeyDecimal ? MoneySeparators.decimal : key;
    return Semantics(
      button: true,
      label: backspace ? t.common.keypadBackspace : label,
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('keypad-$key'),
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: () {
          unawaited(HapticFeedback.selectionClick());
          widget.onKey(key);
        },
        onLongPress: backspace
            ? () {
                unawaited(HapticFeedback.mediumImpact());
                widget.onClear();
              }
            : null,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          height: widget.height,
          decoration: ShapeDecoration(
            color: _pressed ? colors.surface3 : colors.surface2,
            shape: const PixelCornerBorder.small(),
          ),
          child: Center(
            child: backspace
                ? AppIcon(IconKey.backspace, color: colors.ink)
                : Text(label, style: context.numberStyles.amountLg.copyWith(fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}
