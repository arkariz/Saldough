import 'package:flutter/material.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/money_expression.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/core/utils/formatters/money_input.dart';
import 'package:saldough/features/record/presentation/widgets/record_amount_controller.dart';

/// Kartu "Nilai transaksi" Catat (acuan Catat v2): label dan kode mata uang,
/// nominal besar yang membal tiap berubah, lalu chip penambah cepat
/// (+5k, +10k, +50k, +100k). Diisi lewat [DsKeypad] di bawah lembar
/// (`RecordFormFrame.amountController`) atau chip, bukan keyboard sistem;
/// isinya dibaca lewat `parseMoneyInput`.
///
/// Selama menghitung (T-8.18), ungkapannya tampil satu baris di atas nominal,
/// dan nominal besar berisi hasilnya; hasil yang tidak sah diberi keterangan
/// `error` di bawah ungkapan.
class RecordAmountField extends StatelessWidget {
  /// Membuat [RecordAmountField]. [onChanged] dipanggil sesudah chip cepat
  /// mengubah nominal (papan angka memakai `onAmountChanged` kerangka).
  const RecordAmountField({required this.controller, required this.kind, this.onChanged, super.key});

  /// Pengendali nominal, berisi angka berpemisah ribuan.
  final RecordAmountController controller;

  /// Jenis transaksi.
  final TransactionKind kind;

  /// Dipanggil sesudah chip cepat mengubah nominal.
  final VoidCallback? onChanged;

  /// Penambah cepat dalam satuan utama mata uang aktif.
  static List<int> get quickUnits => ActiveCurrency.value.fractionDigits == 0 ? const [5000, 10000, 50000, 100000] : const [5, 10, 50, 100];

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final text = value.text;
        final sen = parseMoneyInput(text) ?? 0;
        final expression = controller.expression;
        final error = controller.error;
        final amount = AppMoneyFormatter.formatRevealed(sen);
        final reduced = DsMotion.reduced(context);
        return DsCard(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                liveRegion: true,
                label: expression.isEmpty
                    ? t.record.amountSemantics(amount: amount)
                    : t.record.calc.semantics(expression: expression, amount: amount),
                excludeSemantics: true,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
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
                            style: ds.typography.amount.copyWith(color: c.textSecondary),
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
                          style: ds.typography.bodySm.copyWith(color: c.error),
                        ),
                      TweenAnimationBuilder<double>(
                        key: ValueKey(text),
                        tween: Tween(begin: reduced ? 1 : 0.88, end: 1),
                        duration: reduced ? Duration.zero : const Duration(milliseconds: 240),
                        curve: Curves.easeOutBack,
                        builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text.rich(
                            key: const ValueKey('record-amount'),
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: ActiveCurrency.value.symbol,
                                  style: ds.typography.headlineSm.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: c.textMuted,
                                  ),
                                ),
                                TextSpan(
                                  text: text.isEmpty ? '0' : text,
                                  style: TextStyle(color: text.isEmpty ? c.textMuted : c.textPrimary),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                            style: ds.typography.displayLg.copyWith(
                              fontSize: 32,
                              height: 1.15,
                              fontFeatures: const [FontFeature.tabularFigures(), FontFeature.liningFigures()],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _QuickAdd(controller: controller, onChanged: onChanged),
            ],
          ),
        );
      },
    );
  }
}

class _QuickAdd extends StatelessWidget {
  const _QuickAdd({required this.controller, required this.onChanged});

  final RecordAmountController controller;
  final VoidCallback? onChanged;

  static String _short(int units) => units >= 1000 && units % 1000 == 0 ? '+${units ~/ 1000}k' : '+$units';

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    // Satu baris horizontal: label, lalu empat chip sama lebar.
    return Row(
      children: [
        Text('${t.record.quickAddLabel}:', style: ds.typography.labelSm.copyWith(color: c.textMuted)),
        const SizedBox(width: 8),
        for (final (i, units) in RecordAmountField.quickUnits.indexed) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: DsPressable(
              onPressed: () {
                if (controller.addSen(units * 100)) onChanged?.call();
              },
              pressedScale: 0.93,
              semanticLabel: t.record.quickAddSemantics(amount: AppMoneyFormatter.formatRevealed(units * 100)),
              builder: (context, _) => Container(
                key: ValueKey('record-quick-$units'),
                constraints: const BoxConstraints(minHeight: 28),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.surfaceSunken,
                  borderRadius: DsRadius.mdAll,
                  border: Border.all(color: c.outlineSubtle),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _short(units),
                    maxLines: 1,
                    style: ds.typography.labelMd.copyWith(color: c.textPrimary, fontSize: 12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
