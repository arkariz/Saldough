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
/// ringan saat ditekan. Tombol tampak setinggi [keyHeight] (40), tetapi area
/// sentuhnya ikut mengisi jarak antarbaris sehingga tetap 48 (`AppSize.touch`,
/// QA PR #43 F1): papan angka lebih pendek tanpa target sentuh yang lebih
/// kecil. [onKey] menerima digit, `000`, [moneyKeyDecimal],
/// atau [moneyKeyBackspace]; teksnya dihitung lewat [applyMoneyKey].
class AppKeypad extends StatelessWidget {
  /// Membuat [AppKeypad].
  const AppKeypad({
    required this.onKey,
    required this.onClear,
    this.keyHeight = 40,
    super.key,
  });

  /// Dipanggil dengan tombol yang ditekan.
  final ValueChanged<String> onKey;

  /// Tekan lama tombol hapus.
  final VoidCallback onClear;

  /// Tinggi tampak tiap tombol; area sentuhnya paling sedikit
  /// `AppSize.touch`.
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
        for (final row in rows)
          Row(
            children: [
              for (final (j, key) in row.indexed) ...[
                if (j > 0) const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: _Key(
                    keyValue: key,
                    height: keyHeight,
                    onKey: onKey,
                    onClear: onClear,
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }
}

class _Key extends StatefulWidget {
  const _Key({
    required this.keyValue,
    required this.height,
    required this.onKey,
    required this.onClear,
  });

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
    void tap() {
      unawaited(HapticFeedback.selectionClick());
      widget.onKey(key);
    }

    // Jarak antarbaris (8px) masuk ke area sentuh: tombol 40 + 2×4 = 48.
    final gap = ((AppSize.touch - widget.height) / 2).clamp(0.0, double.infinity);
    return Semantics(
      button: true,
      label: backspace ? t.common.keypadBackspace : label,
      // `excludeSemantics` membuang aksi ketuk `GestureDetector`, jadi
      // aksinya dipasang di sini (QA PR #43 F7).
      onTap: tap,
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('keypad-$key'),
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: tap,
        onLongPress: backspace
            ? () {
                unawaited(HapticFeedback.mediumImpact());
                widget.onClear();
              }
            : null,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: gap),
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
                  : Text(
                      label,
                      style: context.numberStyles.amountLg.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
