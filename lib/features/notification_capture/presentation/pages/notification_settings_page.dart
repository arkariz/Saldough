import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/plan/active_plan.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/notification_capture/domain/entities/captured_notification.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_capture_settings.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_source.dart';
import 'package:saldough/features/notification_capture/presentation/bloc/notification_settings_bloc.dart';
import 'package:saldough/features/notification_capture/presentation/navigation/notification_capture_route_keys.dart';
import 'package:saldough/features/notification_capture/presentation/pages/notification_source_page.dart';
import 'package:saldough/features/notification_capture/presentation/widgets/access_disclosure.dart';
import 'package:saldough/features/notification_capture/presentation/widgets/plus_gate.dart';
import 'package:state_management/state_management.dart';

/// Paket sumber uji `adb shell cmd notification post` (build debug saja).
const debugShellPackage = 'com.android.shell';

/// Layar setelan Catat dari notifikasi (ADR-032 §3.9), tampilan v2: nyala/mati,
/// izin sistem, optimasi baterai, kotak masuk, aplikasi yang didengarkan, lalu
/// perilaku (catat otomatis, kabari lewat notifikasi).
class NotificationSettingsPage extends StatefulWidget {
  /// Membuat [NotificationSettingsPage].
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Kembali dari setelan akses sistem.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<NotificationSettingsBloc>().add(
        const NotificationSettingsResumed(),
      );
    }
  }

  Future<void> _requestAccess(BuildContext context) async {
    final bloc = context.read<NotificationSettingsBloc>();
    if (await showAccessDisclosure(context)) await bloc.openAccessSettings();
  }

  Future<void> _addSource(BuildContext context) =>
      pickAndOpenNotificationSource(context, bloc: context.read<NotificationSettingsBloc>());

  @override
  Widget build(BuildContext context) {
    final texts = t.notificationCapture;
    final ds = context.ds;
    return Scaffold(
      appBar: AppBar(title: Text(texts.settingsTitle, style: ds.typography.headlineMd), centerTitle: false),
      body: SafeArea(
        child: BlocBuilder<NotificationSettingsBloc, NotificationSettingsState>(
          builder: (context, state) {
            if (state.isLoading) return const AppSkeletonPage();
            final bloc = context.read<NotificationSettingsBloc>();
            final settings = state.settings;
            final autoRecord = settings.autoRecordLevel != AutoRecordLevel.reviewAll;
            final reminder = settings.remindsWhenClosed(isPlus: ActivePlan.isPlus);
            final freeLimit = ActivePlan.limits.value.freeNotificationSources;
            // Urut dari yang wajib (nyala, izin, aplikasi) ke yang opsional
            // (perilaku), ADR-032 §3.9.
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DsListCard(
                  children: [
                    DsSwitchRow(
                      key: const ValueKey('notification-capture-enabled'),
                      leading: DsIconTile.asset(asset: ClayIcons.bell),
                      title: texts.enableLabel,
                      subtitle: settings.enabled && state.accessGranted ? texts.accessGranted : texts.enableHint,
                      value: settings.enabled,
                      onChanged: (value) => bloc.add(NotificationCaptureToggled(enabled: value)),
                    ),
                  ],
                ),
                if (settings.enabled) ...[
                  if (!state.accessGranted) ...[
                    const SizedBox(height: 12),
                    _AccessWarning(onGrant: () => _requestAccess(context)),
                  ],
                  if (state.batteryRestricted) ...[
                    const SizedBox(height: 12),
                    DsListCard(
                      children: [
                        DsSettingRow(
                          key: const ValueKey('notification-battery'),
                          leading: DsIconTile.child(
                            tone: DsIconTileTone.warning,
                            size: DsIconTileSize.md,
                            child: Icon(Icons.battery_alert_rounded, size: 20, color: ds.colors.onWarningContainer),
                          ),
                          title: texts.batteryTitle,
                          subtitle: texts.batteryBody,
                          onTap: () => unawaited(bloc.openBatterySettings()),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  DsListCard(
                    children: [
                      DsSettingRow(
                        key: const ValueKey('notification-capture-inbox'),
                        leading: const SettingIconTile(IconKey.inbox),
                        title: texts.inboxEntryTitle,
                        subtitle: texts.inboxEntryBody,
                        badge: state.pendingCount > 0
                            ? DsBadge(
                                label: texts.pendingBadge(n: state.pendingCount),
                                tone: DsBadgeTone.warning,
                              )
                            : null,
                        onTap: () => unawaited(
                          context.pushRoute(NotificationCaptureRouteKeys.inbox, const EmptyInput()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: DsSectionHeader(title: texts.sourcesTitle)),
                      if (!ActivePlan.isPlus)
                        DsBadge(
                          label: texts.sourcesFreeCount(n: settings.sources.length, max: freeLimit),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (settings.sources.isEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        texts.sourcesEmpty,
                        style: ds.typography.bodyMd.copyWith(color: ds.colors.textSecondary),
                      ),
                    ),
                    DsButton(label: texts.addSource, expand: true, onPressed: () => _addSource(context)),
                  ] else
                    DsListCard(
                      children: [
                        for (final source in settings.sources)
                          _SourceRow(
                            source: source,
                            walletName: state.wallets.where((w) => w.id == source.walletId).firstOrNull?.name,
                            onTap: () => openNotificationSourcePage(context, bloc: bloc, source: source),
                          ),
                        DsSettingRow(
                          leading: DsIconTile.child(
                            size: DsIconTileSize.md,
                            child: Icon(Icons.add_rounded, size: 20, color: ds.colors.actionPrimary),
                          ),
                          title: texts.addSource,
                          badge: PlusBadge(when: () => exceedsFreeSources(settings.sources.length)),
                          onTap: () => _addSource(context),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  DsSectionHeader(title: texts.behaviorTitle),
                  const SizedBox(height: 8),
                  DsListCard(
                    children: [
                      // Tiga tingkat otomatis sebagai dua sakelar (ADR-032 §3.4). Baris
                      // sakelar berlabel yang bisa diketuk utuh (QA PR #43 F15); mematikan
                      // lalu menyalakan lagi memulihkan tingkat terakhir selama halaman
                      // terbuka (F20).
                      DsSwitchRow(
                        key: const ValueKey('notification-auto-record'),
                        title: texts.autoRecordLabel,
                        badge: const PlusBadge(),
                        subtitle: autoRecord ? texts.autoRecordOnHint : texts.autoRecordOffHint,
                        value: autoRecord,
                        onChanged: (on) {
                          // Tingkat otomatis hanya untuk Plus (ADR-041 §3.8).
                          if (on && plusLocked) {
                            unawaited(openNotificationPaywall(context));
                            return;
                          }
                          bloc.add(AutoRecordToggled(on: on));
                        },
                      ),
                      if (autoRecord)
                        DsSwitchRow(
                          key: const ValueKey('notification-auto-record-any-category'),
                          title: texts.autoRecordAnyCategoryLabel,
                          badge: const PlusBadge(),
                          subtitle: texts.autoRecordAnyCategoryHint,
                          value: settings.autoRecordLevel == AutoRecordLevel.whenAmountAndWallet,
                          onChanged: (on) {
                            if (plusLocked) {
                              unawaited(openNotificationPaywall(context));
                              return;
                            }
                            bloc.add(
                              AutoRecordLevelChanged(
                                on ? AutoRecordLevel.whenAmountAndWallet : AutoRecordLevel.whenComplete,
                              ),
                            );
                          },
                        ),
                      DsSwitchRow(
                        key: const ValueKey('notification-reminder'),
                        title: texts.reminderLabel,
                        subtitle: texts.reminderHint,
                        value: reminder,
                        onChanged: (on) => bloc.add(
                          NotificationDeliveryChanged(
                            on ? NotificationDelivery.reminderAndInbox : NotificationDelivery.inboxOnly,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (reminder && !state.canPostReminders)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                      child: Text(
                        texts.reminderPermissionDenied,
                        style: ds.typography.bodySm.copyWith(color: ds.colors.error),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lock_outline_rounded, size: 16, color: ds.colors.textMuted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          texts.privacyFootnote,
                          style: ds.typography.bodySm.copyWith(color: ds.colors.textMuted),
                        ),
                      ),
                    ],
                  ),
                  if (!kReleaseMode) ...[
                    const SizedBox(height: 32),
                    _DebugSamples(
                      samples: state.debugSamples,
                      onAddShellSource: () => openNotificationSourcePage(
                        context,
                        bloc: bloc,
                        source: const NotificationSource(
                          packageName: debugShellPackage,
                          appLabel: 'adb shell',
                          keywords: defaultNotificationKeywords,
                        ),
                        isNew: true,
                      ),
                      onRefresh: () => bloc.add(const DebugSamplesRequested()),
                    ),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Izin akses notifikasi belum diberikan: satu-satunya penghalang, jadi
/// tampil menonjol di atas daftar aplikasi.
class _AccessWarning extends StatelessWidget {
  const _AccessWarning({required this.onGrant});

  final VoidCallback onGrant;

  @override
  Widget build(BuildContext context) {
    final texts = t.notificationCapture;
    final ds = context.ds;
    return DsCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              DsIconTile.child(
                tone: DsIconTileTone.warning,
                size: DsIconTileSize.sm,
                child: Icon(Icons.priority_high_rounded, size: 18, color: ds.colors.onWarningContainer),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(texts.accessMissingTitle, style: ds.typography.titleMd)),
            ],
          ),
          const SizedBox(height: 8),
          Text(texts.accessMissingBody, style: ds.typography.bodyMd.copyWith(color: ds.colors.textSecondary)),
          const SizedBox(height: 12),
          DsButton(label: texts.accessAction, expand: true, onPressed: onGrant),
        ],
      ),
    );
  }
}

/// Satu aplikasi yang didengarkan: nama dan dompetnya; peringatan bila
/// dompet atau filter kosong.
class _SourceRow extends StatelessWidget {
  const _SourceRow({required this.source, required this.walletName, required this.onTap});

  final NotificationSource source;
  final String? walletName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final texts = t.notificationCapture;
    final ds = context.ds;
    final noFilter = source.keywords.every((k) => k.trim().isEmpty);
    final (subtitle, warn) = switch ((source.enabled, noFilter, walletName)) {
      (false, _, _) => (texts.sourcePaused, false),
      (true, true, _) => (texts.sourceKeywordsNone, true),
      (true, false, null) => (texts.sourceNoWallet, true),
      (true, false, final String name) => (texts.sourceWallet(name: name), false),
    };
    final initial = source.appLabel.trim().isEmpty ? '?' : source.appLabel.trim().characters.first.toUpperCase();
    return DsSettingRow(
      leading: DsIconTile.child(
        size: DsIconTileSize.md,
        tone: warn ? DsIconTileTone.warning : DsIconTileTone.neutral,
        child: Text(initial, style: ds.typography.titleMd.copyWith(color: ds.colors.textPrimary)),
      ),
      title: source.appLabel,
      subtitle: subtitle,
      badge: warn ? DsBadge(label: texts.sourceNeedsAttention, tone: DsBadgeTone.warning) : null,
      onTap: onTap,
    );
  }
}

class _DebugSamples extends StatelessWidget {
  const _DebugSamples({required this.samples, required this.onAddShellSource, required this.onRefresh});

  final List<CapturedNotification> samples;
  final VoidCallback onAddShellSource;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final texts = t.notificationCapture;
    final ds = context.ds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: DsSectionHeader(title: texts.debugSamplesTitle)),
            IconButton(onPressed: onRefresh, icon: const Icon(Icons.refresh_rounded)),
          ],
        ),
        Text(texts.debugSamplesHint, style: ds.typography.bodySm.copyWith(color: ds.colors.textSecondary)),
        const SizedBox(height: 8),
        if (samples.isEmpty) Text(texts.debugSamplesEmpty, style: ds.typography.bodyMd),
        for (final sample in samples)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DsCard(
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: '${sample.packageName}\n${sample.text}'));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showAppSnackBar(SnackBar(content: Text(texts.copied)));
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sample.packageName, style: ds.typography.bodySm.copyWith(color: ds.colors.textSecondary)),
                  Text(sample.text, style: ds.typography.bodyMd),
                ],
              ),
            ),
          ),
        DsButton.ghost(label: texts.debugShellSource, onPressed: onAddShellSource),
      ],
    );
  }
}
