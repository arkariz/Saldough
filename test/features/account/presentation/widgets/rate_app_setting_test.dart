import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/account/presentation/widgets/rate_app_setting.dart';

Widget _host(Future<bool> Function() opener) => MaterialApp(
  theme: AppThemeBridge.build(DsThemePresets.fallback, Brightness.light),
  home: Scaffold(body: ListView(children: [RateAppSettingEntry(opener: opener)])),
);

void main() {
  final events = <AnalyticsEvent>[];
  setUp(() {
    events.clear();
    AppAnalytics.debugSink = events.add;
  });
  tearDown(() => AppAnalytics.debugSink = null);

  test('alamat toko memuat id aplikasi', () {
    expect(playStoreAppUri.toString(), 'market://details?id=com.arkarizdev.tanukonomy');
    expect(playStoreWebUri.queryParameters['id'], 'com.arkarizdev.tanukonomy');
  });

  testWidgets('mengetuk baris mencatat peristiwa dan membuka toko', (tester) async {
    var opened = 0;
    await tester.pumpWidget(
      _host(() async {
        opened++;
        return true;
      }),
    );
    await tester.tap(find.text(t.account.rateApp.title));
    await tester.pumpAndSettle();
    expect(opened, 1);
    expect(events, [ActivationEvents.rateAppTapped]);
    expect(find.text(t.account.rateApp.openFailed), findsNothing);
  });

  testWidgets('gagal membuka toko menampilkan pesan', (tester) async {
    await tester.pumpWidget(_host(() async => false));
    await tester.tap(find.text(t.account.rateApp.title));
    await tester.pumpAndSettle();
    expect(find.text(t.account.rateApp.openFailed), findsOneWidget);
  });
}
