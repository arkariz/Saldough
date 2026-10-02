import 'dart:async';

import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';

/// Awal bulan keuangan di layar Akun (KT-R2, ADR-034 §3.6): tanggal 1–28.
/// Hanya tab Rencana yang memakainya; Beranda tetap bulan kalender.
class FinancialMonthSettingEntry extends StatelessWidget {
  /// Membuat [FinancialMonthSettingEntry].
  const FinancialMonthSettingEntry({super.key});

  Future<void> _choose(BuildContext context) async {
    final repository = ScopeProvider.of(context)<FinancialMonthPreferenceRepository>();
    final current = ActiveFinancialMonth.startDay;
    final picked = await showDialog<int>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(t.plan.financialMonthPickerTitle),
        children: [
          for (var day = financialMonthStartDays.min; day <= financialMonthStartDays.max; day++)
            SimpleDialogOption(
              key: ValueKey('financial-month-$day'),
              onPressed: () => Navigator.of(dialogContext).pop(day),
              child: Row(
                children: [
                  Expanded(child: Text(t.plan.financialMonthDay(day: day))),
                  if (day == current) const AppIcon(IconKey.check),
                ],
              ),
            ),
        ],
      ),
    );
    if (picked == null || picked == current) return;
    if ((await repository.save(picked)).isRight()) ActiveFinancialMonth.notifier.value = picked;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ValueListenableBuilder<int>(
      valueListenable: ActiveFinancialMonth.notifier,
      builder: (context, startDay, _) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: AppTappable(
          key: const ValueKey('financial-month-setting'),
          label: t.plan.financialMonthTitle,
          onTap: () => unawaited(_choose(context)),
          child: AppHardCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.plan.financialMonthTitle, style: textTheme.titleSmall),
                      Text(
                        '${t.plan.financialMonthDay(day: startDay)} · '
                        '${financialMonthOf(DateTime.now(), startDay).label}',
                        style: textTheme.bodyMedium?.copyWith(color: context.appColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const AppIcon(IconKey.chevronRight),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
