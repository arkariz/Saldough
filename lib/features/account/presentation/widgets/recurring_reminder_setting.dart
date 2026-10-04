import 'package:flutter/material.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/recurring/presentation/navigation/recurring_route_keys.dart';

/// Pintu masuk sakelar global pengingat rutin di layar Akun (ADR-035 §3.8).
class RecurringReminderSettingEntry extends StatelessWidget {
  /// Membuat [RecurringReminderSettingEntry].
  const RecurringReminderSettingEntry({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: AppTappable(
        key: const ValueKey('recurring-reminder-setting'),
        label: t.recurring.remindersTitle,
        onTap: () => context.pushRoute(RecurringRouteKeys.reminders, const EmptyInput()),
        child: AppHardCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.recurring.remindersTitle, style: textTheme.titleSmall),
                    Text(
                      t.recurring.remindersBody,
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
    );
  }
}
