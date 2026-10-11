import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/account/presentation/widgets/setting_row.dart';
import 'package:saldough/features/budget/presentation/navigation/budget_route_keys.dart';

/// Awal bulan keuangan di layar Akun (ADR-038, FINANCIAL_PERIOD F1): membuka
/// lembar Awal bulan keuangan yang sama dengan kepala Rencana › Bulan ini.
class FinancialMonthSettingEntry extends StatelessWidget {
  /// Membuat [FinancialMonthSettingEntry].
  const FinancialMonthSettingEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<FinancialMonthSchedule>(
      valueListenable: ActiveFinancialMonth.notifier,
      builder: (context, schedule, _) => SettingRow(
        key: const ValueKey('financial-month-setting'),
        icon: IconKey.calendar,
        title: t.plan.financialMonthTitle,
        subtitle:
            '${_startLabel(schedule.active)} · '
            '${schedule.periodOf(DateTime.now()).label}',
        onTap: () => unawaited(context.pushRoute(BudgetRouteKeys.financialMonth, const FinancialMonthInput())),
      ),
    );
  }
}

String _startLabel(FinancialMonthStart start) => switch (start.day) {
  final day? => t.plan.financialMonthDay(day: day),
  null => t.plan.financialMonthLastDay,
};
