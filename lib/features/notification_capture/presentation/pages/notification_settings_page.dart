import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/notification_capture/domain/entities/captured_notification.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_capture_settings.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_source.dart';
import 'package:saldough/features/notification_capture/presentation/bloc/notification_settings_bloc.dart';
import 'package:saldough/features/notification_capture/presentation/navigation/notification_capture_route_keys.dart';
import 'package:saldough/features/notification_capture/presentation/pages/notification_source_page.dart';
import 'package:saldough/features/notification_capture/presentation/widgets/app_picker_sheet.dart';
import 'package:saldough/features/notification_capture/presentation/widgets/notification_widgets.dart';
import 'package:state_management/state_management.dart';

/// Paket sumber uji `adb shell cmd notification post` (build debug saja).
const debugShellPackage = 'com.android.shell';

/// Layar setelan Catat dari notifikasi (ADR-032 §3.9): nyala/mati, izin
/// sistem, kotak masuk, aplikasi yang didengarkan, lalu perilaku (catat
/// otomatis, kabari lewat notifikasi).
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
      context.read<NotificationSettingsBloc>().add(const NotificationSettingsResumed());
    }
  }

  Future<void> _requestAccess(BuildContext context) async {
    final bloc = context.read<NotificationSettingsBloc>();
    final texts = t.notificationCapture;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(texts.disclosureTitle),
        content: SingleChildScrollView(child: Text(texts.disclosureBody)),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(t.common.cancel)),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(texts.disclosureAccept)),
        ],
      ),
    );
    if (accepted ?? false) await bloc.openAccessSettings();
  }

  Future<void> _addSource(BuildContext context) async {
    final bloc = context.read<NotificationSettingsBloc>();
    final app = await showAppPickerSheet(context, load: bloc.loadInstalledApps);
    if (app == null || !context.mounted) return;
    final existing = bloc.state.settings.sources.where((s) => s.packageName == app.packageName).firstOrNull;
    await openNotificationSourcePage(
      context,
      bloc: bloc,
      source:
          existing ??
          NotificationSource(packageName: app.packageName, appLabel: app.label, keywords: defaultNotificationKeywords),
      isNew: existing == null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final texts = t.notificationCapture;
    final textTheme = Theme.of(context).textTheme;
    final colors = context.appColors;
    return Scaffold(
      appBar: AppBar(title: Text(texts.settingsTitle)),
      body: SafeArea(
        child: BlocBuilder<NotificationSettingsBloc, NotificationSettingsState>(
          builder: (context, state) {
            if (state.isLoading) return const AppSkeletonPage();
            final bloc = context.read<NotificationSettingsBloc>();
            final settings = state.settings;
            final autoRecord = settings.autoRecordLevel != AutoRecordLevel.reviewAll;
            final reminder = settings.delivery == NotificationDelivery.reminderAndInbox;
            // Urut dari yang wajib (nyala, izin, aplikasi) ke yang opsional
            // (perilaku), ADR-032 §3.9.
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.space4),
              children: [
                NotificationSwitchCard(
                  key: const ValueKey('notification-capture-enabled'),
                  label: texts.enableLabel,
                  hint: texts.enableHint,
                  value: settings.enabled,
                  onChanged: (value) => bloc.add(NotificationCaptureToggled(enabled: value)),
                  footer: settings.enabled && state.accessGranted
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.space1),
                          child: Row(
                            children: [
                              AppIcon(IconKey.check, color: colors.positive, size: 16),
                              const SizedBox(width: AppSpacing.space1),
                              Text(texts.accessGranted, style: textTheme.bodySmall),
                            ],
                          ),
                        )
                      : null,
                ),
                if (settings.enabled) ...[
                  if (!state.accessGranted) ...[
                    const SizedBox(height: AppSpacing.space2),
                    _AccessWarning(onGrant: () => _requestAccess(context)),
                  ],
                  const SizedBox(height: AppSpacing.space2),
                  NotificationNavCard(
                    key: const ValueKey('notification-capture-inbox'),
                    title: texts.inboxEntryTitle,
                    subtitle: texts.inboxEntryBody,
                    onTap: () => unawaited(context.pushRoute(NotificationCaptureRouteKeys.inbox, const EmptyInput())),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  AppSectionLabel(texts.sourcesTitle),
                  const SizedBox(height: AppSpacing.space1),
                  if (settings.sources.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
                      child: Text(texts.sourcesEmpty, style: textTheme.bodyMedium),
                    ),
                  for (final source in settings.sources)
                    _SourceRow(
                      source: source,
                      walletName: state.wallets.where((w) => w.id == source.walletId).firstOrNull?.name,
                      onTap: () => openNotificationSourcePage(context, bloc: bloc, source: source),
                    ),
                  if (settings.sources.isEmpty)
                    AppButton(label: texts.addSource, onPressed: () => _addSource(context))
                  else
                    AppButton.secondary(label: texts.addSource, onPressed: () => _addSource(context)),
                  const SizedBox(height: AppSpacing.space6),
                  AppSectionLabel(texts.behaviorTitle),
                  const SizedBox(height: AppSpacing.space1),
                  AppHardCard(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4, vertical: AppSpacing.space2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Tiga tingkat otomatis sebagai dua sakelar (ADR-032 §3.4).
                        NotificationSwitchRow(
                          key: const ValueKey('notification-auto-record'),
                          label: texts.autoRecordLabel,
                          hint: autoRecord ? texts.autoRecordOnHint : texts.autoRecordOffHint,
                          value: autoRecord,
                          onChanged: (on) => bloc.add(
                            AutoRecordLevelChanged(on ? AutoRecordLevel.whenComplete : AutoRecordLevel.reviewAll),
                          ),
                        ),
                        if (autoRecord)
                          NotificationSwitchRow(
                            key: const ValueKey('notification-auto-record-any-category'),
                            indent: true,
                            label: texts.autoRecordAnyCategoryLabel,
                            hint: texts.autoRecordAnyCategoryHint,
                            value: settings.autoRecordLevel == AutoRecordLevel.whenAmountAndWallet,
                            onChanged: (on) => bloc.add(
                              AutoRecordLevelChanged(
                                on ? AutoRecordLevel.whenAmountAndWallet : AutoRecordLevel.whenComplete,
                              ),
                            ),
                          ),
                        Divider(color: colors.line, height: AppSpacing.space4),
                        NotificationSwitchRow(
                          key: const ValueKey('notification-reminder'),
                          label: texts.reminderLabel,
                          hint: texts.reminderHint,
                          value: reminder,
                          onChanged: (on) => bloc.add(
                            NotificationDeliveryChanged(
                              on ? NotificationDelivery.reminderAndInbox : NotificationDelivery.inboxOnly,
                            ),
                          ),
                        ),
                        if (reminder && !state.canPostReminders)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.space1),
                            child: Text(
                              texts.reminderPermissionDenied,
                              style: textTheme.bodySmall?.copyWith(color: colors.ink),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!kReleaseMode) ...[
                    const SizedBox(height: AppSpacing.space8),
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
    final textTheme = Theme.of(context).textTheme;
    final colors = context.appColors;
    return AppHardCard(
      color: Color.alphaBlend(colors.brand.withValues(alpha: 0.12), colors.surface),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(texts.accessMissingTitle, style: textTheme.titleSmall),
          const SizedBox(height: AppSpacing.space1),
          Text(texts.accessMissingBody, style: textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.space2),
          AppButton(label: texts.accessAction, onPressed: onGrant),
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
    final colors = context.appColors;
    final noFilter = source.keywords.every((k) => k.trim().isEmpty);
    final (subtitle, color) = switch ((source.enabled, noFilter, walletName)) {
      (false, _, _) => (texts.sourcePaused, null),
      (true, true, _) => (texts.sourceKeywordsNone, colors.ink),
      (true, false, null) => (texts.sourceNoWallet, colors.danger),
      (true, false, final String name) => (texts.sourceWallet(name: name), null),
    };
    return NotificationNavCard(
      title: source.appLabel,
      titleColor: source.enabled ? null : colors.ink2,
      subtitle: subtitle,
      subtitleColor: color,
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
    final textTheme = Theme.of(context).textTheme;
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: AppSectionLabel(texts.debugSamplesTitle)),
            IconButton(onPressed: onRefresh, icon: const AppIcon(IconKey.refresh)),
          ],
        ),
        Text(texts.debugSamplesHint, style: textTheme.bodySmall?.copyWith(color: colors.ink2)),
        const SizedBox(height: AppSpacing.space2),
        if (samples.isEmpty) Text(texts.debugSamplesEmpty, style: textTheme.bodyMedium),
        for (final sample in samples)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.space2),
            child: AppTappable(
              label: sample.packageName,
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: '${sample.packageName}\n${sample.text}'));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texts.copied)));
                }
              },
              child: AppHardCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sample.packageName, style: textTheme.bodySmall?.copyWith(color: colors.ink2)),
                    Text(sample.text, style: textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
          ),
        AppButton.tertiary(label: texts.debugShellSource, onPressed: onAddShellSource),
      ],
    );
  }
}
