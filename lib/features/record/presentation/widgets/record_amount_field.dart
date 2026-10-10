import 'package:flutter/material.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/money_expression.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/core/utils/formatters/money_input.dart';
import 'package:saldough/features/record/presentation/widgets/record_amount_controller.dart';

/// Nominal yang sedang diisi di Catat (prototipe `Catat.dc.html`):
/// `amount-display` di tengah dengan simbol mata uang diperkecil di depannya
/// (`.tk-amt__cur`). Diisi lewat [AppKeypad] di bawah lembar
/// (`RecordFormFrame.amountController`), bukan keyboard sistem; isinya
/// dibaca lewat `parseMoneyInput`.
///
/// Selama menghitung (T-8.18), ungkapannya tampil satu baris di atas nominal,
/// dan nominal besar berisi hasilnya; hasil yang tidak sah diberi keterangan
/// `danger` di bawah ungkapan.
class RecordAmountField extends StatelessWidget {
  /// Membuat [RecordAmountField].
  const RecordAmountField({
    required this.controller,
    required this.kind,
    super.key,
  });

  /// Pengendali nominal, berisi angka berpemisah ribuan.
  final RecordAmountController controller;

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
        final expression = controller.expression;
        final error = controller.error;
        final amount = AppMoneyFormatter.formatRevealed(sen);
        final caption = Theme.of(context).textTheme.bodyMedium;
        return Semantics(
          liveRegion: true,
          label: expression.isEmpty
              ? t.record.amountSemantics(amount: amount)
              : t.record.calc.semantics(expression: expression, amount: amount),
          excludeSemantics: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.space1),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (expression.isNotEmpty)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      expression,
                      key: const ValueKey('record-amount-expression'),
                      maxLines: 1,
                      style: context.numberStyles.amount.copyWith(color: colors.ink2),
                    ),
                  ),
                if (error != null)
                  Text(
                    switch (error) {
                      MoneyExpressionError.notPositive => t.record.calc.notPositive,
                      MoneyExpressionError.divideByZero => t.record.calc.divideByZero,
                      MoneyExpressionError.tooLarge => t.record.calc.tooLarge,
                    },
                    key: const ValueKey('record-amount-error'),
                    textAlign: TextAlign.center,
                    style: caption?.copyWith(color: colors.danger),
                  ),
                FittedBox(
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
              ],
            ),
          ),
        );
      },
    );
  }
}
