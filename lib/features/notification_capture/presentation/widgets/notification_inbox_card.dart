import 'dart:async';

import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/discovery/discovery.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/spotlight/spotlight.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/tutorial/tutorial.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/features/notification_capture/domain/entities/capture_inbox_entry.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_gateway.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_store.dart';
import 'package:saldough/features/notification_capture/domain/services/capture_inbox_changes.dart';
import 'package:saldough/features/notification_capture/presentation/navigation/notification_capture_route_keys.dart';
import 'package:saldough/features/notification_capture/presentation/widgets/access_disclosure.dart';
import 'package:saldough/shared/capture/capture.dart';
import 'package:saldough/shared/transaction/transaction_presentation.dart';

/// Widget **Kotak masuk notifikasi** di Beranda untuk Android (komponen
/// InboxCard, FEATURE_DISCOVERY P-7, P-8): pintu permanen Catat dari
/// notifikasi yang tidak pernah hilang, tanpa tutup atau tunda. Isinya
/// mengikuti keadaan: belum disetel (Nyalakan, Mulai cepat), izin hilang
/// (Izinkan), sakelar mati (Nyalakan, setelan), aktif tanpa yang menunggu
/// ("{n} aplikasi aktif" + Kelola), aktif dengan tangkapan (Cek, pratinjau
/// paling banyak dua, Ajari pola, kaki). Latar `warning-soft` hanya bila ada
/// yang perlu dicek. Pratinjau hanya membaca: mencatat lewat Cek / CATAT
/// (aturan 8). Kosong di platform tanpa dukungan dan tanpa layanan
/// terdaftar (uji).
class NotificationInboxCard extends StatefulWidget {
  /// Membuat [NotificationInboxCard].
  const NotificationInboxCard({required this.container, super.key});

  /// Kontainer akar.
  final GetIt container;

  @override
  State<NotificationInboxCard> createState() => _NotificationInboxCardState();
}

class _NotificationInboxCardState extends State<NotificationInboxCard> with WidgetsBindingObserver {
  static const _previewCount = 2;

  FeatureStatuses? _statuses;
  NotificationCaptureStore? _store;
  final _subscriptions = <StreamSubscription<void>>[];
  FeatureStatus? _status;
  List<CaptureInboxEntry> _pending = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final c = widget.container;
    if (!c.isRegistered<FeatureStatuses>() || !c.isRegistered<NotificationCaptureStore>()) return;
    _statuses = c<FeatureStatuses>();
    _store = c<NotificationCaptureStore>();
    _subscriptions.add(_statuses!.changes.listen((_) => unawaited(_load())));
    if (c.isRegistered<CaptureInboxChanges>()) {
      _subscriptions.add(c<CaptureInboxChanges>().stream.listen((_) => unawaited(_load())));
    }
    unawaited(_load());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_load());
  }

  Future<void> _load() async {
    final statuses = _statuses;
    final store = _store;
    if (statuses == null || store == null) return;
    final status = await statuses.read(DiscoveredFeature.notification);
    final pending = status.isSupported
        ? (await store.loadInbox()).getOrElse((_) => const [])
        : const <CaptureInboxEntry>[];
    if (!mounted) return;
    if (status != _status || pending.length != _pending.length || !_samePending(pending)) {
      setState(() {
        _status = status;
        _pending = pending;
      });
    }
  }

  bool _samePending(List<CaptureInboxEntry> next) {
    for (var i = 0; i < next.length; i++) {
      if (next[i] != _pending[i]) return false;
    }
    return true;
  }

  Future<void> _push<I extends RouteInput>(RouteKey<I> key, I input) async {
    await context.pushRoute(key, input);
    await _load();
  }

  /// Nama keadaan untuk analitik (`unset`, `active`, `permission`, `off`).
  String get _stateName => switch (_status?.state) {
    FeatureState.permissionNeeded => 'permission',
    FeatureState.off => 'off',
    FeatureState.active => 'active',
    _ => 'unset',
  };

  void _tapped(String action) => AppAnalytics.log(
    DiscoveryEvents.notificationRowTapped(state: _stateName, surface: 'home', action: action),
  );

  void _openSettings() {
    _tapped('manage');
    unawaited(_push(NotificationCaptureRouteKeys.settings, const EmptyInput()));
  }

  void _openInbox() => unawaited(_push(NotificationCaptureRouteKeys.inbox, const EmptyInput()));

  void _openQuickStart() {
    _tapped('quick_start');
    unawaited(_push(NotificationCaptureRouteKeys.quickStart, const EmptyInput()));
  }

  Future<void> _allow() async {
    _tapped('manage');
    final gateway = widget.container<NotificationCaptureGateway>();
    if (await showAccessDisclosure(context)) await gateway.openAccessSettings();
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    if (status == null || !status.isSupported) return const SizedBox.shrink();
    final texts = t.discovery;
    final textTheme = Theme.of(context).textTheme;
    final colors = context.appColors;
    final active = status.state == FeatureState.active;
    final hasPending = active && _pending.isNotEmpty;
    final (title, sub) = switch (status.state) {
      FeatureState.unset => (texts.notification.button, t.notificationCapture.accountEntryBody),
      FeatureState.off => (texts.notification.button, texts.status.off),
      FeatureState.permissionNeeded => (texts.notification.manage, texts.status.permissionNeeded),
      _ => (
        texts.notification.inboxTitle,
        hasPending
            ? t.notificationCapture.banner(n: _pending.length)
            : texts.notification.activeApps(n: status.activeCount),
      ),
    };
    final (ctaLabel, onCta, primary) = switch (status.state) {
      FeatureState.unset => (texts.turnOn, _openQuickStart, true),
      FeatureState.off => (texts.turnOn, _openSettings, true),
      FeatureState.permissionNeeded => (texts.allowAccess, () => unawaited(_allow()), true),
      _ => hasPending ? (texts.notification.check, _openInbox, false) : (null, null, false),
    };
    final head = Row(
      children: [
        const AppIconTile(IconKey.inbox),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: textTheme.titleSmall),
              Text(sub, style: textTheme.bodySmall?.copyWith(color: colors.ink2)),
            ],
          ),
        ),
        if (ctaLabel != null && onCta != null) ...[
          const SizedBox(width: AppSpacing.space3),
          if (primary)
            AppButton(key: const ValueKey('inbox-card-action'), small: true, label: ctaLabel, onPressed: onCta)
          else
            AppButton.secondary(
              key: const ValueKey('inbox-card-action'),
              small: true,
              label: ctaLabel,
              onPressed: onCta,
            ),
        ],
      ],
    );
    // Disorot sekali saat pertama tampil (T-21.6); kartu ini memuat dirinya
    // sendiri sesudah Beranda, jadi memicu turnya sendiri.
    return TourTrigger(
      tour: TourId.home,
      ready: true,
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.space6),
        child: SpotlightTarget(
          spotlightKey: SpotlightKey.homeNotification,
          child: _card(context, status, active: active, hasPending: hasPending, head: head),
        ),
      ),
    );
  }

  Widget _card(
    BuildContext context,
    FeatureStatus status, {
    required bool active,
    required bool hasPending,
    required Widget head,
  }) {
    final texts = t.discovery;
    final textTheme = Theme.of(context).textTheme;
    final colors = context.appColors;
    return AppCard(
      key: const ValueKey('notification-inbox-card'),
      color: hasPending ? colors.warningSoft : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Aktif tanpa yang menunggu: kepala membuka layar setelan penuh.
          if (active && !hasPending)
            InkWell(key: const ValueKey('inbox-card-head'), onTap: _openSettings, child: head)
          else
            head,
          if (hasPending) ...[
            for (final entry in _pending.take(_previewCount)) ...[
              const SizedBox(height: AppSpacing.space3),
              _PreviewRow(
                entry: entry,
                onTeach: () {
                  _tapped('teach_pattern');
                  unawaited(_push(NotificationCaptureRouteKeys.teachPattern, TeachPatternInput(entryId: entry.id)));
                },
              ),
            ],
          ],
          if (active) ...[
            const SizedBox(height: AppSpacing.space3),
            Row(
              children: [
                if (hasPending)
                  Expanded(
                    child: Text(
                      texts.notification.activeApps(n: status.activeCount),
                      style: textTheme.bodySmall?.copyWith(color: colors.ink2),
                    ),
                  )
                else
                  const Spacer(),
                AppButton.text(
                  key: const ValueKey('inbox-card-manage'),
                  small: true,
                  label: texts.notification.manageSources,
                  onPressed: _openSettings,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Satu tangkapan di pratinjau: hanya baca. Tangkapan yang nominalnya tak
/// terbaca membawa **Ajari pola** menggantikan nominal.
class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.entry, required this.onTeach});

  final CaptureInboxEntry entry;
  final VoidCallback onTeach;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.appColors;
    final draft = entry.draft;
    final amount = draft.amountSen;
    final note = draft.note.trim();
    return DecoratedBox(
      decoration: ShapeDecoration(color: colors.surface, shape: const PixelCornerBorder.small()),
      child: Padding(
        key: ValueKey('inbox-preview-${entry.id}'),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space3, vertical: AppSpacing.space2),
        child: Row(
          children: [
            TransactionIcon(
              kind: switch (draft.kind) {
                DraftKind.income => TransactionKind.income,
                DraftKind.expense => TransactionKind.expense,
                DraftKind.transfer => TransactionKind.transfer,
              },
              categoryId: draft.categoryId,
              sourceIconId: entry.iconId,
            ),
            const SizedBox(width: AppSpacing.space3 + TransactionIcon.badgeOverhang),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.isEmpty ? entry.text : note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium,
                  ),
                  Text(
                    amount == null
                        ? t.notificationCapture.amountUnknown
                        : '${entry.appLabel} · ${CycleMonthFormatter.formatDateShort(entry.capturedAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(color: colors.ink2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.space2),
            if (amount == null)
              AppButton.secondary(
                key: ValueKey('inbox-teach-${entry.id}'),
                small: true,
                label: t.discovery.notification.teachPattern,
                onPressed: onTeach,
              )
            else
              AppMoneyText(
                amount,
                kind: switch (draft.kind) {
                  DraftKind.income => MoneyKind.income,
                  DraftKind.expense => MoneyKind.expense,
                  DraftKind.transfer => MoneyKind.transfer,
                },
              ),
          ],
        ),
      ),
    );
  }
}
