import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/notification_capture/presentation/navigation/notification_capture_route_keys.dart';

/// Pintu masuk setelan Catat dari notifikasi di layar Akun (ADR-032). Hanya
/// Android: iOS tidak mengizinkan membaca notifikasi aplikasi lain.
class NotificationCaptureSettingEntry extends StatelessWidget {
  /// Membuat [NotificationCaptureSettingEntry].
  const NotificationCaptureSettingEntry({super.key});

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.android) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.space2),
      child: AppTappable(
        key: const ValueKey('notification-capture-setting'),
        label: t.notificationCapture.accountEntryTitle,
        onTap: () => context.pushRoute(NotificationCaptureRouteKeys.settings, const EmptyInput()),
        child: AppCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.notificationCapture.accountEntryTitle, style: textTheme.titleSmall),
                    Text(
                      t.notificationCapture.accountEntryBody,
                      style: textTheme.bodyMedium?.copyWith(color: context.appColors.ink2),
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
