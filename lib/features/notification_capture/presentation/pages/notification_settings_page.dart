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
import 'package:saldough/features/notification_capture/presentation/widgets/source_app_tile.dart';
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

  void _showHelp(BuildContext context) {
    unawaited(showAppSheet<void>(context, builder: (_) => const _HelpSheet()));
  }

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
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              children: [
                _Eyebrow(onHelp: () => _showHelp(context)),
                const SizedBox(height: 12),
                DsCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _MasterRow(
                        key: const ValueKey('notification-capture-enabled'),
                        title: texts.enableLabel,
                        status: !settings.enabled
                            ? DsPill(label: texts.statusOff)
                            : state.accessGranted
                            ? DsPill(label: texts.statusActive, tone: DsPillTone.positive, dot: true)
                            : DsPill(label: texts.statusNoAccess, tone: DsPillTone.warning, dot: true),
                        value: settings.enabled,
                        onChanged: (value) => bloc.add(NotificationCaptureToggled(enabled: value)),
                      ),
                      if (settings.enabled && state.batteryRestricted) ...[
                        const SizedBox(height: 12),
                        _BatteryBanner(onTap: () => unawaited(bloc.openBatterySettings())),
                      ],
                    ],
                  ),
                ),
                if (settings.enabled) ...[
                  if (!state.accessGranted) ...[
                    const SizedBox(height: 12),
                    _AccessWarning(onGrant: () => _requestAccess(context)),
                  ],
                  const SizedBox(height: 12),
                  _InboxCard(
                    pending: state.pendingCount,
                    onTap: () => unawaited(context.pushRoute(NotificationCaptureRouteKeys.inbox, const EmptyInput())),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Flexible(child: DsSectionHeader(title: texts.sourcesActiveTitle)),
                      if (!ActivePlan.isPlus) ...[
                        const SizedBox(width: 8),
                        DsPill(
                          label: texts.sourcesFreeCount(n: settings.sources.length, max: freeLimit),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (settings.sources.isEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        texts.sourcesEmpty,
                        style: ds.typography.bodyMd.copyWith(color: ds.colors.textSecondary),
                      ),
                    ),
                    DsButton(label: texts.addSource, expand: true, onPressed: () => _addSource(context)),
                  ] else ...[
                    for (final source in settings.sources)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _SourceCard(
                          source: source,
                          icon: state.appIcons[source.packageName],
                          walletName: state.wallets.where((w) => w.id == source.walletId).firstOrNull?.name,
                          onTap: () => openNotificationSourcePage(context, bloc: bloc, source: source),
                        ),
                      ),
                    DsDashedButton(
                      label: texts.addSource,
                      trailing: PlusBadge(when: () => exceedsFreeSources(settings.sources.length)),
                      onPressed: () => _addSource(context),
                    ),
                  ],
                  const SizedBox(height: 24),
                  DsCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                          child: Row(
                            children: [
                              Expanded(child: DsSectionHeader(title: texts.behaviorTitle)),
                              Icon(Icons.tune_rounded, size: 18, color: ds.colors.textSecondary),
                            ],
                          ),
                        ),
                        Divider(height: 1, color: ds.colors.outlineSubtle),
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
                        if (autoRecord) ...[
                          Divider(height: 1, color: ds.colors.outlineSubtle),
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
                        ],
                        Divider(height: 1, color: ds.colors.outlineSubtle),
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
                        if (reminder && !state.canPostReminders)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: Text(
                              texts.reminderPermissionDenied,
                              style: ds.typography.bodySm.copyWith(color: ds.colors.error),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!kReleaseMode) ...[
                    const SizedBox(height: 16),
                    _DevAccordion(
                      child: _DebugSamples(
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
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.spa_outlined, size: 16, color: ds.colors.actionPrimary),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          texts.privacyFootnote,
                          style: ds.typography.bodySm.copyWith(color: ds.colors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Anak judul: daun, "OTOMASI TANUKI", dan tombol bantuan keamanan.
class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.onHelp});

  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Row(
      children: [
        Icon(Icons.eco_outlined, size: 18, color: ds.colors.actionPrimary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            t.notificationCapture.settingsEyebrow.toUpperCase(),
            style: ds.typography.pixelCaption.copyWith(color: ds.colors.textSecondary),
          ),
        ),
        Semantics(
          button: true,
          label: t.notificationCapture.helpTitle,
          child: DsPressable(
            onPressed: onHelp,
            builder: (context, _) => Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: ds.colors.surfaceSunken, shape: BoxShape.circle),
                child: Icon(Icons.help_outline_rounded, size: 18, color: ds.colors.textSecondary),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Baris sakelar utama: judul besar, pil status, dan sakelar berkenop centang.
/// Seluruh baris bisa diketuk.
class _MasterRow extends StatelessWidget {
  const _MasterRow({
    required this.title,
    required this.status,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String title;
  final Widget status;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return MergeSemantics(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: ds.typography.headlineSm),
                  const SizedBox(height: 6),
                  Align(alignment: Alignment.centerLeft, child: status),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Switch(value: value, onChanged: onChanged, thumbIcon: dsSwitchThumbIcon(context)),
          ],
        ),
      ),
    );
  }
}

/// Pita peringatan optimasi baterai di dalam kartu utama.
class _BatteryBanner extends StatelessWidget {
  const _BatteryBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    return DsPressable(
      onPressed: onTap,
      builder: (context, _) => Container(
        key: const ValueKey('notification-battery'),
        constraints: const BoxConstraints(minHeight: 40),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: c.toneWarmContainer.withValues(alpha: 0.6), borderRadius: DsRadius.baseAll),
        child: Row(
          children: [
            Icon(Icons.battery_alert_rounded, size: 16, color: c.onToneWarmContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                t.notificationCapture.batteryBanner,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ds.typography.labelMd.copyWith(color: c.onToneWarmContainer, letterSpacing: 0),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: c.onToneWarmContainer),
          ],
        ),
      ),
    );
  }
}

/// Kartu pintu ke Kotak masuk: tile, judul, keterangan, dan pil jumlah.
class _InboxCard extends StatelessWidget {
  const _InboxCard({required this.pending, required this.onTap});

  final int pending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final texts = t.notificationCapture;
    final ds = context.ds;
    final c = ds.colors;
    return DsCard(
      key: const ValueKey('notification-capture-inbox'),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      onTap: onTap,
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: DsIconTile.child(
                    size: DsIconTileSize.md,
                    child: Icon(Icons.inbox_outlined, size: 22, color: c.textPrimary),
                  ),
                ),
                if (pending > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: c.actionPrimary,
                        shape: BoxShape.circle,
                        border: Border.all(color: c.surfaceCard, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(texts.inboxEntryTitle, style: ds.typography.titleMd.copyWith(fontSize: 15)),
                Text(
                  pending > 0 ? texts.pendingReady(n: pending) : texts.inboxEntryBody,
                  style: ds.typography.bodySm.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
          if (pending > 0) ...[
            const SizedBox(width: 8),
            DsPill(
              label: texts.pendingBadge(n: pending),
              tone: DsPillTone.positive,
              trailingIcon: Icons.arrow_forward_rounded,
            ),
          ] else
            Icon(Icons.chevron_right_rounded, size: 20, color: c.textMuted),
        ],
      ),
    );
  }
}

/// Kartu satu aplikasi yang didengarkan: ikon asli, nama dengan titik status,
/// dompet atau peringatan, dan pil keadaan.
class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.source, required this.icon, required this.walletName, required this.onTap});

  final NotificationSource source;
  final Uint8List? icon;
  final String? walletName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final texts = t.notificationCapture;
    final ds = context.ds;
    final c = ds.colors;
    final noFilter = source.keywords.every((k) => k.trim().isEmpty);
    final (subtitle, warn) = switch ((source.enabled, noFilter, walletName)) {
      (false, _, _) => (texts.sourcePaused, false),
      (true, true, _) => (texts.sourceKeywordsNone, true),
      (true, false, null) => (texts.sourceNoWallet, true),
      (true, false, final String name) => (texts.sourceWallet(name: name), false),
    };
    final dot = !source.enabled ? c.textMuted : (warn ? c.error : c.actionPrimary);
    return DsCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      onTap: onTap,
      child: Row(
        children: [
          SourceAppTile(label: source.appLabel, icon: icon, warn: warn, dimmed: !source.enabled),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        source.appLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ds.typography.titleMd.copyWith(
                          fontSize: 15,
                          color: source.enabled ? c.textPrimary : c.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                    ),
                  ],
                ),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ds.typography.bodySm.copyWith(color: warn ? c.error : c.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (warn)
            DsPill(label: texts.sourceStateSet, tone: DsPillTone.danger, icon: Icons.tune_rounded)
          else if (source.enabled)
            DsPill(label: texts.sourceStateActive, tone: DsPillTone.positive),
          Icon(Icons.chevron_right_rounded, size: 20, color: c.textMuted),
        ],
      ),
    );
  }
}

/// Lembar "Keamanan notifikasi": apa yang dibaca dan ke mana perginya.
class _HelpSheet extends StatelessWidget {
  const _HelpSheet();

  @override
  Widget build(BuildContext context) {
    final texts = t.notificationCapture;
    final ds = context.ds;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, size: 22, color: ds.colors.actionPrimary),
              const SizedBox(width: 8),
              Expanded(child: Text(texts.helpTitle, style: ds.typography.headlineSm)),
            ],
          ),
          const SizedBox(height: 12),
          Text(texts.helpBody, style: ds.typography.bodyMd.copyWith(color: ds.colors.textSecondary)),
          const SizedBox(height: 20),
          DsButton(label: texts.helpClose, expand: true, onPressed: () => Navigator.of(context).pop()),
        ],
      ),
    );
  }
}

/// Kartu abu "Opsi lanjutan & pengembang", terlipat; hanya di build non-rilis.
class _DevAccordion extends StatefulWidget {
  const _DevAccordion({required this.child});

  final Widget child;

  @override
  State<_DevAccordion> createState() => _DevAccordionState();
}

class _DevAccordionState extends State<_DevAccordion> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    return DecoratedBox(
      decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: DsRadius.lgAll),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DsPressable(
            onPressed: () => setState(() => _open = !_open),
            builder: (context, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.build_circle_outlined, size: 20, color: c.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t.notificationCapture.devOptionsTitle,
                      style: ds.typography.titleMd.copyWith(fontSize: 14),
                    ),
                  ),
                  Icon(_open ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: c.textSecondary),
                ],
              ),
            ),
          ),
          if (_open) Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: widget.child),
        ],
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
