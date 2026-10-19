import 'dart:async';

import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/discovery/discovery.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/recurring/domain/enable_reminders.dart';
import 'package:saldough/features/recurring/domain/reminder_scheduler.dart';
import 'package:saldough/features/recurring/domain/reminder_settings.dart';
import 'package:saldough/features/recurring/domain/sync_recurring_reminders.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Keadaan pengingat rutin untuk pintu permanen (FEATURE_DISCOVERY P-1, P-2)
/// dan tombol yang menyalakannya. Dibaca dari [FeatureStatuses], dibaca ulang
/// saat setelan berubah dan aplikasi kembali ke depan (izin bisa dicabut di
/// sistem). Tanpa [FeatureStatuses] atau repositori yang dibutuhkan (uji,
/// kontainer minimal) tidak membangun apa pun.
class ReminderStatusBuilder extends StatefulWidget {
  /// Membuat [ReminderStatusBuilder].
  const ReminderStatusBuilder({required this.container, required this.builder, super.key});

  /// Kontainer akar.
  final GetIt container;

  /// Dipanggil bila pengingat belum efektif; [enable] meminta izin lalu
  /// menyalakan, dan menampilkan snackbar bila izin ditolak.
  final Widget Function(BuildContext context, FeatureState state, Future<void> Function() enable) builder;

  @override
  State<ReminderStatusBuilder> createState() => _ReminderStatusBuilderState();
}

class _ReminderStatusBuilderState extends State<ReminderStatusBuilder> with WidgetsBindingObserver {
  FeatureStatuses? _statuses;
  StreamSubscription<void>? _changes;
  FeatureState? _state;

  bool get _ready {
    final c = widget.container;
    return c.isRegistered<FeatureStatuses>() &&
        c.isRegistered<ReminderScheduler>() &&
        c.isRegistered<ReminderSettingsRepository>() &&
        c.isRegistered<RecurringRuleRepository>() &&
        c.isRegistered<TransactionRepository>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (!_ready) return;
    _statuses = widget.container<FeatureStatuses>();
    _changes = _statuses!.changes.listen((_) => unawaited(_load()));
    unawaited(_load());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_changes?.cancel());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_load());
  }

  Future<void> _load() async {
    final statuses = _statuses;
    if (statuses == null) return;
    final status = await statuses.read(DiscoveredFeature.reminder);
    if (mounted && status.state != _state) setState(() => _state = status.state);
  }

  Future<void> _enable() async {
    final c = widget.container;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final granted = await EnableReminders(
      scheduler: c<ReminderScheduler>(),
      settings: c<ReminderSettingsRepository>(),
      sync: SyncRecurringReminders(
        scheduler: c<ReminderScheduler>(),
        settings: c<ReminderSettingsRepository>(),
        rules: c<RecurringRuleRepository>(),
        transactions: c<TransactionRepository>(),
      ),
    )();
    if (c.isRegistered<FeatureStatusChanges>()) c<FeatureStatusChanges>().notify();
    if (!granted) messenger?.showSnackBar(SnackBar(content: Text(t.recurring.remindersDenied)));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    if (state == null || state == FeatureState.active || state == FeatureState.unsupported) {
      return const SizedBox.shrink();
    }
    return widget.builder(context, state, _enable);
  }
}
