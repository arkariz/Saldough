import 'dart:async';

import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/discovery/discovery.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/notification_capture/domain/entities/capture_inbox_entry.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_store.dart';
import 'package:saldough/features/notification_capture/domain/services/capture_inbox_changes.dart';
import 'package:saldough/features/notification_capture/presentation/navigation/notification_capture_route_keys.dart';

/// Tile aksi cepat **Notifikasi** di Beranda (Android): pintu tetap ke Catat
/// dari notifikasi, dengan lencana jumlah yang menunggu dicek.
///
/// Tujuan ketukan mengikuti keadaan fitur, selalu tempat yang sama untuk
/// keadaan yang sama: belum disetel → Mulai cepat; sakelar mati → setelan;
/// selain itu → kotak masuk (yang sendiri menangani izin hilang dan keadaan
/// kosong). Tidak pernah mencatat langsung (aturan 8). Disisipkan akar
/// komposisi hanya bila platform mendukung.
class NotificationQuickAction extends StatefulWidget {
  /// Membuat [NotificationQuickAction].
  const NotificationQuickAction({required this.container, super.key});

  /// Kontainer akar.
  final GetIt container;

  @override
  State<NotificationQuickAction> createState() => _NotificationQuickActionState();
}

class _NotificationQuickActionState extends State<NotificationQuickAction> with WidgetsBindingObserver {
  FeatureStatuses? _statuses;
  NotificationCaptureStore? _store;
  final _subscriptions = <StreamSubscription<void>>[];
  FeatureStatus? _status;
  int _pending = 0;

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

  Future<FeatureStatus?> _load() async {
    final statuses = _statuses;
    final store = _store;
    if (statuses == null || store == null) return null;
    final status = await statuses.read(DiscoveredFeature.notification);
    final pending = status.isEffective
        ? (await store.loadInbox()).getOrElse((_) => const <CaptureInboxEntry>[]).length
        : 0;
    if (!mounted) return status;
    if (status != _status || pending != _pending) {
      setState(() {
        _status = status;
        _pending = pending;
      });
    }
    return status;
  }

  Future<void> _open() async {
    final status = _status ?? await _load();
    if (!mounted) return;
    final key = switch (status?.state) {
      FeatureState.unset => NotificationCaptureRouteKeys.quickStart,
      FeatureState.off => NotificationCaptureRouteKeys.settings,
      _ => NotificationCaptureRouteKeys.inbox,
    };
    await context.pushRoute(key, const EmptyInput());
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final tile = DsQuickActionTile(
      key: const ValueKey('home-action-notification'),
      tile: DsIconTile.asset(asset: ClayIcons.bell, tone: DsIconTileTone.warning),
      label: t.home.actionNotification,
      onPressed: () => unawaited(_open()),
    );
    if (_pending == 0) return tile;
    return Semantics(
      label: '${t.home.actionNotification}, ${t.notificationCapture.banner(n: _pending)}',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          tile,
          Positioned(
            top: -6,
            right: -2,
            child: DsBadge(label: '$_pending', tone: DsBadgeTone.warning),
          ),
        ],
      ),
    );
  }
}
