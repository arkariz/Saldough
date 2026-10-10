import 'dart:async';

import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/account/presentation/widgets/setting_row.dart';

/// Awal bulan keuangan di layar Akun (KT-R2, ADR-035 §3.6): tanggal 1–28.
/// Mengubahnya menambah entri riwayat lewat
/// [FinancialMonthSchedule.changedOn] (ADR-038): periode berjalan menjadi
/// periode peralihan, periode yang sudah selesai tidak berubah. Lembar
/// pratinjau dan "hari terakhir" menyusul di T-18.6.
class FinancialMonthSettingEntry extends StatelessWidget {
  /// Membuat [FinancialMonthSettingEntry].
  const FinancialMonthSettingEntry({super.key});

  Future<void> _choose(BuildContext context) async {
    final repository = ScopeProvider.of(context)<FinancialMonthPreferenceRepository>();
    final schedule = ActiveFinancialMonth.schedule;
    final current = schedule.active.day;
    final picked = await showDialog<int>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(t.plan.financialMonthPickerTitle),
        children: [
          for (var day = FinancialMonthStart.minDay; day <= FinancialMonthStart.maxDay; day++)
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
    final updated = schedule.changedOn(DateTime.now(), FinancialMonthStart.day(picked));
    if ((await repository.save(updated)).isRight()) ActiveFinancialMonth.notifier.value = updated;
  }

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
        onTap: () => unawaited(_choose(context)),
      ),
    );
  }
}

String _startLabel(FinancialMonthStart start) => switch (start.day) {
  final day? => t.plan.financialMonthDay(day: day),
  null => t.plan.financialMonthLastDay,
};
