import 'dart:async';

import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_store.dart';
import 'package:saldough/features/notification_capture/domain/services/capture_inbox_changes.dart';
import 'package:saldough/features/notification_capture/presentation/navigation/notification_capture_route_keys.dart';

/// Kartu Beranda "transaksi dari notifikasi perlu ditinjau" (ADR-032 §3.7).
/// Disisipkan shell ke slot Beranda; kosong bila tidak ada yang menunggu
/// atau fitur tidak terdaftar (platform lain, uji).
class CaptureInboxBanner extends StatefulWidget {
  /// Membuat [CaptureInboxBanner].
  const CaptureInboxBanner({required this.container, super.key});

  /// Container akar tempat modul notifikasi terdaftar; slot Beranda berada
  /// di bawah `HomeScope` yang terisolasi (ADR-030).
  final GetIt container;

  @override
  State<CaptureInboxBanner> createState() => _CaptureInboxBannerState();
}

class _CaptureInboxBannerState extends State<CaptureInboxBanner> {
  NotificationCaptureStore? _store;
  StreamSubscription<void>? _changes;
  int _pending = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_store != null) return;
    final container = widget.container;
    if (!container.isRegistered<NotificationCaptureStore>()) return;
    _store = container<NotificationCaptureStore>();
    _changes = container<CaptureInboxChanges>().stream.listen((_) => _load());
    unawaited(_load());
  }

  Future<void> _load() async {
    final count = (await _store!.loadInbox()).fold((_) => 0, (inbox) => inbox.length);
    if (mounted && count != _pending) setState(() => _pending = count);
  }

  @override
  void dispose() {
    unawaited(_changes?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_pending == 0) return const SizedBox.shrink();
    final texts = t.notificationCapture;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.space4),
      child: AppTappable(
        key: const ValueKey('capture-inbox-banner'),
        label: texts.banner(n: _pending),
        onTap: () => context.pushRoute(NotificationCaptureRouteKeys.inbox, const EmptyInput()),
        child: AppCard(
          child: Row(
            children: [
              const AppIcon(IconKey.pending),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: Text(texts.banner(n: _pending), style: Theme.of(context).textTheme.titleSmall),
              ),
              Text(texts.bannerAction, style: TextStyle(color: context.appColors.brand)),
              const AppIcon(IconKey.chevronRight),
            ],
          ),
        ),
      ),
    );
  }
}
