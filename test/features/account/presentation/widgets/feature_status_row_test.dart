import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/discovery/discovery.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/account/presentation/widgets/feature_status_row.dart';

import '../../../../helpers/fake_feature_statuses.dart';

void main() {
  late FakeFeatureStatuses statuses;
  var opened = 0;

  setUp(() {
    statuses = FakeFeatureStatuses();
    opened = 0;
  });

  Future<void> pumpRow(
    WidgetTester tester, {
    DiscoveredFeature feature = DiscoveredFeature.reminder,
    bool registered = true,
    double width = 360,
  }) async {
    final container = GetIt.asNewInstance();
    if (registered) container.registerSingleton<FeatureStatuses>(statuses);
    tester.view
      ..physicalSize = Size(width, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ScopeProvider(
        container: container,
        child: MaterialApp(
          theme: PixelTheme.light,
          home: Scaffold(
            body: FeatureStatusSettingRow(
              feature: feature,
              icon: IconKey.schedule,
              title: 'Judul',
              subtitle: 'Keterangan bawaan',
              onTap: () async => opened++,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('nyala: badge Nyala', (tester) async {
    statuses.status[DiscoveredFeature.reminder] = const FeatureStatus(FeatureState.active);
    await pumpRow(tester);

    expect(find.text(t.discovery.status.on), findsOneWidget);
  });

  testWidgets('mati dan belum disetel: badge Mati', (tester) async {
    statuses.status[DiscoveredFeature.reminder] = const FeatureStatus(FeatureState.off);
    await pumpRow(tester);
    expect(find.text(t.discovery.status.off), findsOneWidget);

    statuses.status[DiscoveredFeature.reminder] = const FeatureStatus(FeatureState.unset);
    statuses.notify();
    await tester.pumpAndSettle();
    expect(find.text(t.discovery.status.off), findsOneWidget);
  });

  testWidgets('izin dicabut: badge Izin belum diberikan, muat di 360dp', (tester) async {
    statuses.status[DiscoveredFeature.reminder] = const FeatureStatus(FeatureState.permissionNeeded);
    await pumpRow(tester);

    expect(find.text(t.discovery.status.permissionNeeded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Catat dari notifikasi aktif menampilkan jumlah aplikasi di keterangan', (tester) async {
    statuses.status[DiscoveredFeature.notification] = const FeatureStatus(FeatureState.active, activeCount: 3);
    await pumpRow(tester, feature: DiscoveredFeature.notification);

    expect(find.text(t.discovery.notification.activeApps(n: 3)), findsOneWidget);
    expect(find.text('Keterangan bawaan'), findsNothing);
  });

  testWidgets('pengingat tetap memakai keterangan bawaan', (tester) async {
    statuses.status[DiscoveredFeature.reminder] = const FeatureStatus(FeatureState.active);
    await pumpRow(tester);

    expect(find.text('Keterangan bawaan'), findsOneWidget);
  });

  testWidgets('platform tidak mendukung dan tanpa FeatureStatuses: tanpa badge', (tester) async {
    await pumpRow(tester, feature: DiscoveredFeature.notification);
    expect(find.byType(AppBadge), findsNothing);

    await pumpRow(tester, registered: false);
    expect(find.byType(AppBadge), findsNothing);
    expect(find.text('Judul'), findsOneWidget);
  });

  testWidgets('status ikut berubah saat setelan berubah dan sesudah layar tujuan ditutup', (tester) async {
    statuses.status[DiscoveredFeature.reminder] = const FeatureStatus(FeatureState.off);
    await pumpRow(tester);
    expect(find.text(t.discovery.status.off), findsOneWidget);

    statuses.status[DiscoveredFeature.reminder] = const FeatureStatus(FeatureState.active);
    statuses.notify();
    await tester.pumpAndSettle();
    expect(find.text(t.discovery.status.on), findsOneWidget);

    statuses.status[DiscoveredFeature.reminder] = const FeatureStatus(FeatureState.permissionNeeded);
    await tester.tap(find.text('Judul'));
    await tester.pumpAndSettle();
    expect(opened, 1);
    expect(find.text(t.discovery.status.permissionNeeded), findsOneWidget);
  });

  testWidgets('kembali ke depan membaca ulang (izin dicabut di sistem)', (tester) async {
    statuses.status[DiscoveredFeature.reminder] = const FeatureStatus(FeatureState.active);
    await pumpRow(tester);

    statuses.status[DiscoveredFeature.reminder] = const FeatureStatus(FeatureState.permissionNeeded);
    const [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ].forEach(tester.binding.handleAppLifecycleStateChanged);
    await tester.pumpAndSettle();

    expect(find.text(t.discovery.status.permissionNeeded), findsOneWidget);
  });

  testWidgets('analitik: baris Catat dari notifikasi di Akun tercatat; pengingat tidak', (tester) async {
    final events = <AnalyticsEvent>[];
    AppAnalytics.debugSink = events.add;
    addTearDown(() => AppAnalytics.debugSink = null);
    statuses.status[DiscoveredFeature.notification] = const FeatureStatus(FeatureState.off, activeCount: 1);
    await pumpRow(tester, feature: DiscoveredFeature.notification);
    await tester.tap(find.text('Judul'));
    await tester.pumpAndSettle();
    expect(events.single, DiscoveryEvents.notificationRowTapped(state: 'off', surface: 'account', action: 'manage'));

    events.clear();
    statuses.status[DiscoveredFeature.reminder] = const FeatureStatus(FeatureState.off);
    await pumpRow(tester);
    await tester.tap(find.text('Judul'));
    await tester.pumpAndSettle();
    expect(events, isEmpty);
  });
}
