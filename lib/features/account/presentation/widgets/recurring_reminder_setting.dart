import 'package:flutter/material.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/account/presentation/widgets/setting_row.dart';
import 'package:saldough/features/recurring/presentation/navigation/recurring_route_keys.dart';

/// Pintu masuk sakelar global pengingat rutin di layar Akun (ADR-035 §3.8).
class RecurringReminderSettingEntry extends StatelessWidget {
  /// Membuat [RecurringReminderSettingEntry].
  const RecurringReminderSettingEntry({super.key});

  @override
  Widget build(BuildContext context) => SettingRow(
    key: const ValueKey('recurring-reminder-setting'),
    icon: IconKey.schedule,
    title: t.recurring.remindersTitle,
    subtitle: t.recurring.remindersBody,
    onTap: () => context.pushRoute(RecurringRouteKeys.reminders, const EmptyInput()),
  );
}
