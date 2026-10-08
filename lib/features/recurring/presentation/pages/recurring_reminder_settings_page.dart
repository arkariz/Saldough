import 'dart:async';

import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/recurring/domain/reminder_scheduler.dart';
import 'package:saldough/features/recurring/domain/reminder_settings.dart';
import 'package:saldough/features/recurring/domain/sync_recurring_reminders.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Sakelar global pengingat rutin (ADR-035 §3.8). Izin notifikasi diminta
/// saat pertama dinyalakan; bila ditolak, sakelar tetap mati. Jadwal
/// langsung disusun ulang sesudah sakelar berubah.
class RecurringReminderSettingsPage extends StatefulWidget {
  /// Membuat [RecurringReminderSettingsPage].
  const RecurringReminderSettingsPage({super.key});

  @override
  State<RecurringReminderSettingsPage> createState() => _RecurringReminderSettingsPageState();
}

class _RecurringReminderSettingsPageState extends State<RecurringReminderSettingsPage> {
  bool? _enabled;
  late ReminderSettingsRepository _settings;
  late ReminderScheduler _scheduler;
  late SyncRecurringReminders _sync;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_enabled != null) return;
    final c = ScopeProvider.of(context);
    _settings = c<ReminderSettingsRepository>();
    _scheduler = c<ReminderScheduler>();
    _sync = SyncRecurringReminders(
      scheduler: _scheduler,
      settings: _settings,
      rules: c<RecurringRuleRepository>(),
      transactions: c<TransactionRepository>(),
    );
    unawaited(_load());
  }

  Future<void> _load() async {
    final enabled = (await _settings.isEnabled()).getOrElse((_) => false);
    if (mounted) setState(() => _enabled = enabled);
  }

  Future<void> _toggle(bool value) async {
    final messenger = ScaffoldMessenger.of(context);
    if (value && !await _scheduler.requestPermission()) {
      messenger.showSnackBar(SnackBar(content: Text(t.recurring.remindersDenied)));
      return;
    }
    await _settings.setEnabled(enabled: value);
    if (mounted) setState(() => _enabled = value);
    await _sync();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _enabled;
    return Scaffold(
      appBar: AppBar(title: Text(t.recurring.remindersTitle)),
      body: SafeArea(
        child: enabled == null
            ? const AppSkeletonPage()
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.space4),
                children: [
                  AppCard(
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(t.recurring.remindersTitle),
                      subtitle: Text(
                        t.recurring.remindersBody,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.appColors.ink2),
                      ),
                      value: enabled,
                      onChanged: (value) => unawaited(_toggle(value)),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
