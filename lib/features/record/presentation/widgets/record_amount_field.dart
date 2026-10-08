import 'package:flutter/material.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/core/utils/formatters/money_input.dart';

/// Nominal yang sedang diisi di Catat (prototipe `Catat.dc.html`):
/// `amount-display` di tengah dengan simbol mata uang diperkecil di depannya
/// (`.tk-amt__cur`). Diisi lewat [AppKeypad] di bawah lembar
/// (`RecordFormFrame.amountController`), bukan keyboard sistem; isinya
/// dibaca lewat `parseMoneyInput`.
class RecordAmountField extends StatelessWidget {
  /// Membuat [RecordAmountField].
  const RecordAmountField({
    required this.controller,
    required this.kind,
    super.key,
  });

  /// Pengendali teks, berisi angka berpemisah ribuan.
  final TextEditingController controller;

  /// Jenis transaksi.
  final TransactionKind kind;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final display = context.numberStyles.amountDisplay;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final text = value.text;
        final sen = parseMoneyInput(text) ?? 0;
        return Semantics(
          liveRegion: true,
          label: t.record.amountSemantics(
            amount: AppMoneyFormatter.format(sen),
          ),
          excludeSemantics: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text.rich(
                key: const ValueKey('record-amount'),
                TextSpan(
                  children: [
                    TextSpan(
                      text: ActiveCurrency.value.symbol,
                      style: display.copyWith(
                        fontSize: display.fontSize! * 0.56,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                        color: colors.ink2,
                      ),
                    ),
                    TextSpan(
                      text: text.isEmpty ? '0' : text,
                      style: TextStyle(
                        color: text.isEmpty ? colors.ink3 : colors.ink,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                style: display,
              ),
            ),
          ),
        );
      },
    );
  }
}
