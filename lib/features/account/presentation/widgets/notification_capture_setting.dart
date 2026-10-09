import 'package:flutter/material.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/account/presentation/widgets/setting_row.dart';
import 'package:saldough/features/notification_capture/presentation/navigation/notification_capture_route_keys.dart';

/// Pintu masuk setelan Catat dari notifikasi di layar Akun (ADR-032). Hanya
/// Android (layar Akun yang memeriksa platformnya): iOS tidak mengizinkan
/// membaca notifikasi aplikasi lain.
class NotificationCaptureSettingEntry extends StatelessWidget {
  /// Membuat [NotificationCaptureSettingEntry].
  const NotificationCaptureSettingEntry({super.key});

  @override
  Widget build(BuildContext context) => SettingRow(
    key: const ValueKey('notification-capture-setting'),
    icon: IconKey.notifications,
    title: t.notificationCapture.accountEntryTitle,
    subtitle: t.notificationCapture.accountEntryBody,
    onTap: () => context.pushRoute(NotificationCaptureRouteKeys.settings, const EmptyInput()),
  );
}
